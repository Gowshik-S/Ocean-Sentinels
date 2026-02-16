package com.oceansentinels.app.mesh.ble

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.*
import android.bluetooth.le.*
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import com.oceansentinels.app.mesh.model.MeshMessage
import com.oceansentinels.app.mesh.model.MeshPeer
import com.google.gson.Gson
import com.google.gson.JsonParser
import timber.log.Timber
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Core BLE Mesh Manager for Ocean Sentinels.
 * Handles BLE advertising, scanning, connection management, and data transfer.
 *
 * Implements dual-PHY strategy:
 * 1. Try BLE PHY Coded (Long Range, S=8, ~400m range) if supported
 * 2. Fall back to standard BLE 1M PHY if Coded PHY unavailable
 *
 * Based on BitChat's mesh architecture adapted for hazard reporting.
 */
@SuppressLint("MissingPermission")
class BleMeshManager(private val context: Context) {

    companion object {
        private const val TAG = "BleMeshManager"

        /** Ocean Sentinels Mesh Service UUID */
        val MESH_SERVICE_UUID: UUID = UUID.fromString("A1C3E5F7-2B4D-6E8F-9A0B-1C2D3E4F5A6B")
        /** Ocean Sentinels Mesh Characteristic UUID (for data transfer) */
        val MESH_CHARACTERISTIC_UUID: UUID = UUID.fromString("B2D4F608-3C5E-7F90-AB1C-2D3E4F5061C7")

        /** Maximum BLE packet size before fragmentation */
        const val MAX_PACKET_SIZE = 512
        /** Fragment size for BLE transmission */
        const val FRAGMENT_SIZE = 469
        /** Scan interval between restarts */
        const val SCAN_RESTART_INTERVAL_MS = 20_000L
        /** Stale peer timeout */
        const val PEER_STALE_TIMEOUT_MS = 180_000L
        /** Maximum simultaneous connections */
        const val MAX_CONNECTIONS = 7
        /** Delay between write confirmation checks (ms) */
        const val WRITE_CONFIRM_TIMEOUT_MS = 5_000L
        /** Reconnection attempt interval for lost peers (ms) */
        const val RECONNECT_INTERVAL_MS = 10_000L
    }

    // ==================== State ====================

    private val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    private val adapter: BluetoothAdapter? = bluetoothManager.adapter
    private val handler = Handler(Looper.getMainLooper())

    private val discoveredPeers = ConcurrentHashMap<String, MeshPeer>()
    private val connectedGatts = ConcurrentHashMap<String, BluetoothGatt>()

    /** LRU-based deduplication cache — auto-evicts oldest entries */
    private val processedMessageIds: MutableSet<String> = java.util.Collections.synchronizedSet(
        object : LinkedHashSet<String>() {
            override fun add(element: String): Boolean {
                val added = super.add(element)
                if (size > maxProcessedIds) {
                    val first = iterator().next()
                    remove(first)
                }
                return added
            }
        }
    )
    private val maxProcessedIds = 10_000

    private var gattServer: BluetoothGattServer? = null
    private var advertisingSet: AdvertisingSet? = null
    private var legacyAdvertiseCallback: AdvertiseCallback? = null
    private var scanCallback: ScanCallback? = null

    private var isRunning = false
    private var isAdvertising = false
    private var isScanning = false

    private var localDeviceMac: String = "00:00:00:00:00:00"
    private var localDeviceId: String = ""
    private var localMeshId: ByteArray = ByteArray(8)

    /**
     * Per-device incoming data buffers for GATT fragment reassembly.
     * When MTU fragmentation splits a message into chunks, each chunk arrives
     * as a separate onCharacteristicWriteRequest. We accumulate until valid JSON.
     */
    private val incomingBuffers = ConcurrentHashMap<String, java.io.ByteArrayOutputStream>()
    /** Timeout (ms) to clear stale incomplete buffers */
    private val bufferTimestamps = ConcurrentHashMap<String, Long>()
    private val BUFFER_STALE_TIMEOUT_MS = 10_000L
    /** Lock for synchronized fragment reassembly across GATT server/client callbacks */
    private val bufferLock = Any()

    // ==================== Callbacks ====================

    var onPeerDiscovered: ((MeshPeer) -> Unit)? = null
    var onPeerConnected: ((MeshPeer) -> Unit)? = null
    var onPeerDisconnected: ((String) -> Unit)? = null
    /**
     * Called when a valid mesh message is received from a peer.
     *
     * Parameters: (message: MeshMessage, senderBleAddress: String)
     *
     * The senderBleAddress is the BLE MAC of the peer that sent/relayed this
     * message to us. This is critical for relay exclusion:
     *
     * Comparison with bitchat-android:
     * ─────────────────────────────────
     * bitchat's RoutedPacket carries both `peerID` (logical sender) and
     * `relayAddress` (BLE address of the immediate hop). When broadcasting,
     * BluetoothPacketBroadcaster.broadcastSinglePacketInternal() skips both:
     *   1. device.address == routed.relayAddress  (don't echo back to relay hop)
     *   2. addressPeerMap[device.address] == senderID  (don't echo to author)
     *
     * Our equivalent: MeshForegroundService.handleReceivedMessage() receives
     * senderBleAddress here and passes it as excludeAddress to broadcastMessage().
     * broadcastMessage() also checks message.originDeviceMac against the
     * addressToDeviceId map to skip the original author.
     */
    var onMessageReceived: ((MeshMessage, String) -> Unit)? = null
    var onMessageSent: ((String, Boolean) -> Unit)? = null
    var onError: ((String) -> Unit)? = null

    /**
     * Maps BLE device address → mesh device ID (from DeviceIdentifier).
     * Populated when we receive a message from a peer — we extract their
     * originDeviceMac from the message JSON and associate it with their
     * BLE address.
     *
     * This is the Ocean Sentinels equivalent of bitchat's
     * BluetoothConnectionTracker.addressPeerMap, which maps BLE MAC → peerID.
     * Used in broadcastMessage() to skip the original message author.
     */
    private val addressToDeviceId = ConcurrentHashMap<String, String>()

    /**
     * Tracks in-flight writes: messageId -> set of peer addresses with confirmed delivery.
     * A write is only considered "delivered to peer" after onCharacteristicWrite SUCCESS.
     */
    private val pendingWrites = ConcurrentHashMap<String, MutableSet<String>>()
    private val confirmedWrites = ConcurrentHashMap<String, MutableSet<String>>()
    /** Maps GATT device address to the messageId currently being written */
    private val activeWriteMessageId = ConcurrentHashMap<String, String>()

    // ==================== Reactive State for UI ====================

    private val _connectedPeerCount = MutableStateFlow(0)
    val connectedPeerCount: StateFlow<Int> = _connectedPeerCount.asStateFlow()

    private val _discoveredPeerCount = MutableStateFlow(0)
    val discoveredPeerCount: StateFlow<Int> = _discoveredPeerCount.asStateFlow()

    private val _isRunningFlow = MutableStateFlow(false)
    val isRunningFlow: StateFlow<Boolean> = _isRunningFlow.asStateFlow()

    private val _isAdvertisingFlow = MutableStateFlow(false)
    val isAdvertisingFlow: StateFlow<Boolean> = _isAdvertisingFlow.asStateFlow()

    private val _isScanningFlow = MutableStateFlow(false)
    val isScanningFlow: StateFlow<Boolean> = _isScanningFlow.asStateFlow()

    /** Update the reactive peer counts */
    private fun updatePeerCounts() {
        _connectedPeerCount.value = connectedGatts.size
        _discoveredPeerCount.value = discoveredPeers.size
    }

    // ==================== Capability Detection ====================

    /** Check if BLE is available */
    fun isBleAvailable(): Boolean {
        return adapter != null && adapter.isEnabled &&
                context.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)
    }

    /** Check if Coded PHY (Long Range) is supported */
    fun isCodedPhySupported(): Boolean {
        return adapter?.isLeCodedPhySupported == true
    }

    /** Check if Extended Advertising is supported (required for Coded PHY advertising) */
    fun isExtendedAdvertisingSupported(): Boolean {
        return adapter?.isLeExtendedAdvertisingSupported == true
    }

    /** Full Long Range support check */
    fun isLongRangeSupported(): Boolean {
        return isCodedPhySupported() && isExtendedAdvertisingSupported()
    }

    /** Check if required BLE permissions are granted */
    fun hasRequiredPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED &&
            ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_ADVERTISE) == PackageManager.PERMISSION_GRANTED &&
            ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
        } else {
            ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        }
    }

    // ==================== Lifecycle ====================

    /** Start the mesh network (advertising + scanning + GATT server) */
    fun start(deviceId: String, meshId: ByteArray) {
        if (isRunning) {
            Timber.w("$TAG: Mesh already running")
            return
        }
        if (!isBleAvailable()) {
            onError?.invoke("BLE not available or disabled")
            return
        }
        if (!hasRequiredPermissions()) {
            onError?.invoke("BLE permissions not granted")
            return
        }

        localDeviceId = deviceId
        localDeviceMac = deviceId // Use deviceId everywhere MAC was used
        localMeshId = meshId
        isRunning = true
        _isRunningFlow.value = true

        Timber.i("$TAG: Starting mesh network (Coded PHY: ${isLongRangeSupported()})")

        startGattServer()
        startAdvertising()
        startScanning()
        startPeerCleanup()
        startReconnectionLoop()
    }

    /** Stop the mesh network */
    fun stop() {
        if (!isRunning) return
        isRunning = false
        _isRunningFlow.value = false

        Timber.i("$TAG: Stopping mesh network")

        stopScanning()
        stopAdvertising()
        stopGattServer()
        disconnectAll()
        incomingBuffers.clear()
        bufferTimestamps.clear()
        handler.removeCallbacksAndMessages(null)
    }

    // ==================== GATT Server ====================

    private fun startGattServer() {
        try {
            gattServer = bluetoothManager.openGattServer(context, gattServerCallback)

            val service = BluetoothGattService(
                MESH_SERVICE_UUID,
                BluetoothGattService.SERVICE_TYPE_PRIMARY
            )

            val characteristic = BluetoothGattCharacteristic(
                MESH_CHARACTERISTIC_UUID,
                BluetoothGattCharacteristic.PROPERTY_READ or
                        BluetoothGattCharacteristic.PROPERTY_WRITE or
                        BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE or
                        BluetoothGattCharacteristic.PROPERTY_NOTIFY,
                BluetoothGattCharacteristic.PERMISSION_READ or
                        BluetoothGattCharacteristic.PERMISSION_WRITE
            )

            service.addCharacteristic(characteristic)
            gattServer?.addService(service)

            Timber.i("$TAG: GATT server started")
        } catch (e: Exception) {
            Timber.e(e, "$TAG: Failed to start GATT server")
            onError?.invoke("Failed to start GATT server: ${e.message}")
        }
    }

    private fun stopGattServer() {
        gattServer?.close()
        gattServer = null
    }

    private val gattServerCallback = object : BluetoothGattServerCallback() {
        override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) {
            try {
                when (newState) {
                    BluetoothProfile.STATE_CONNECTED -> {
                        Timber.i("$TAG: Device connected to server: ${device.address}")
                        val peer = MeshPeer(
                            address = device.address,
                            name = device.name,
                            rssi = 0,
                            isCodedPhy = false,
                            primaryPhy = BluetoothDevice.PHY_LE_1M,
                            secondaryPhy = 0,
                            lastSeenMillis = System.currentTimeMillis(),
                            isConnected = true,
                            hasOceanService = true
                        )
                        discoveredPeers[device.address] = peer
                        updatePeerCounts()
                        onPeerConnected?.invoke(peer)
                    }
                    BluetoothProfile.STATE_DISCONNECTED -> {
                        Timber.i("$TAG: Device disconnected from server: ${device.address}")
                        // Keep peer in discovered list (mark disconnected) so both
                        // devices maintain symmetric visibility of each other.
                        discoveredPeers[device.address]?.let { peer ->
                            discoveredPeers[device.address] = peer.copy(isConnected = false)
                        }
                        synchronized(bufferLock) {
                            incomingBuffers.remove(device.address)
                            bufferTimestamps.remove(device.address)
                        }
                        updatePeerCounts()
                        onPeerDisconnected?.invoke(device.address)
                    }
                }
            } catch (e: Exception) {
                Timber.e(e, "$TAG: Error in GATT server connection state change")
            }
        }

        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            characteristic: BluetoothGattCharacteristic,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray
        ) {
            if (characteristic.uuid == MESH_CHARACTERISTIC_UUID) {
                // Fragment reassembly: accumulate chunks per device
                val address = device.address
                val now = System.currentTimeMillis()

                val parsedMessage = synchronized(bufferLock) {
                    // Check for stale buffer and reset if timed out
                    val lastWrite = bufferTimestamps[address] ?: 0L
                    if (now - lastWrite > BUFFER_STALE_TIMEOUT_MS) {
                        incomingBuffers.remove(address)
                    }

                    val buffer = incomingBuffers.getOrPut(address) { java.io.ByteArrayOutputStream() }
                    buffer.write(value)
                    bufferTimestamps[address] = now

                    // Try to parse the accumulated data as a complete JSON message
                    val accumulated = buffer.toByteArray()
                    val json = String(accumulated, Charsets.UTF_8).trim()

                    // Quick check: valid JSON object starts with { and ends with }
                    if (json.startsWith("{") && json.endsWith("}")) {
                        val message = parseMeshMessage(json)
                        if (message != null) {
                            incomingBuffers.remove(address)
                            bufferTimestamps.remove(address)
                            message // return parsed message
                        } else if (json.count { it == '{' } == json.count { it == '}' }) {
                            Timber.w("$TAG: Malformed JSON from $address, clearing buffer")
                            incomingBuffers.remove(address)
                            bufferTimestamps.remove(address)
                            null
                        } else null
                    } else null
                }

                // Handle outside synchronized block to avoid holding lock during callback
                if (parsedMessage != null) {
                    handleIncomingData(parsedMessage, address)
                }

                if (responseNeeded) {
                    gattServer?.sendResponse(
                        device, requestId, BluetoothGatt.GATT_SUCCESS, offset, null
                    )
                }
            }
        }

        override fun onCharacteristicReadRequest(
            device: BluetoothDevice,
            requestId: Int,
            offset: Int,
            characteristic: BluetoothGattCharacteristic
        ) {
            if (characteristic.uuid == MESH_CHARACTERISTIC_UUID) {
                // Return mesh ID for identification
                gattServer?.sendResponse(
                    device, requestId, BluetoothGatt.GATT_SUCCESS, offset, localMeshId
                )
            }
        }
    }

    // ==================== Advertising ====================

    private fun startAdvertising() {
        val advertiser = adapter?.bluetoothLeAdvertiser ?: run {
            Timber.e("$TAG: BluetoothLeAdvertiser not available")
            return
        }

        if (isLongRangeSupported() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startCodedPhyAdvertising(advertiser)
        }
        // Always start legacy advertising for backward compatibility
        startLegacyAdvertising(advertiser)
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun startCodedPhyAdvertising(advertiser: BluetoothLeAdvertiser) {
        try {
            val builder = AdvertisingSetParameters.Builder()
            builder.setLegacyMode(false)
            builder.setConnectable(true)
            builder.setScannable(false) // Extended connectable ads cannot be scannable
            builder.setPrimaryPhy(BluetoothDevice.PHY_LE_CODED)
            builder.setSecondaryPhy(BluetoothDevice.PHY_LE_CODED)
            builder.setTxPowerLevel(AdvertisingSetParameters.TX_POWER_HIGH)
            // Use LOW interval (100ms) for best discovery range with Coded PHY
            builder.setInterval(AdvertisingSetParameters.INTERVAL_LOW)
            val parameters = builder.build()

            val data = AdvertiseData.Builder()
                .addServiceUuid(ParcelUuid(MESH_SERVICE_UUID))
                .addServiceData(ParcelUuid(MESH_SERVICE_UUID), localMeshId)
                .setIncludeDeviceName(false)
                .build()

            advertiser.startAdvertisingSet(
                parameters, data, null, null, null,
                object : AdvertisingSetCallback() {
                    override fun onAdvertisingSetStarted(
                        set: AdvertisingSet?, txPower: Int, status: Int
                    ) {
                        if (status == ADVERTISE_SUCCESS) {
                            advertisingSet = set
                            isAdvertising = true
                            _isAdvertisingFlow.value = true
                            Timber.i("$TAG: Coded PHY advertising started (TX: $txPower)")
                        } else {
                            Timber.w("$TAG: Coded PHY advertising failed: $status, falling back to legacy only")
                        }
                    }

                    override fun onAdvertisingSetStopped(set: AdvertisingSet?) {
                        advertisingSet = null
                        Timber.i("$TAG: Coded PHY advertising stopped")
                    }
                }
            )
        } catch (e: Exception) {
            Timber.e(e, "$TAG: Error starting Coded PHY advertising")
        }
    }

    private fun startLegacyAdvertising(advertiser: BluetoothLeAdvertiser) {
        try {
            val settings = AdvertiseSettings.Builder()
                .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
                .setConnectable(true)
                .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
                .setTimeout(0) // Advertise indefinitely
                .build()

            val data = AdvertiseData.Builder()
                .addServiceUuid(ParcelUuid(MESH_SERVICE_UUID))
                .setIncludeDeviceName(false)
                .build()

            val scanResponse = AdvertiseData.Builder()
                .addServiceData(ParcelUuid(MESH_SERVICE_UUID), localMeshId)
                .build()

            legacyAdvertiseCallback = object : AdvertiseCallback() {
                override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
                    isAdvertising = true
                    _isAdvertisingFlow.value = true
                    Timber.i("$TAG: Legacy advertising started")
                }

                override fun onStartFailure(errorCode: Int) {
                    Timber.e("$TAG: Legacy advertising failed: $errorCode")
                }
            }

            advertiser.startAdvertising(settings, data, scanResponse, legacyAdvertiseCallback)
        } catch (e: Exception) {
            Timber.e(e, "$TAG: Error starting legacy advertising")
        }
    }

    private fun stopAdvertising() {
        val advertiser = adapter?.bluetoothLeAdvertiser ?: return
        try {
            advertisingSet?.let {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    advertiser.stopAdvertisingSet(object : AdvertisingSetCallback() {})
                }
                advertisingSet = null
            }
            legacyAdvertiseCallback?.let { callback ->
                advertiser.stopAdvertising(callback)
                legacyAdvertiseCallback = null
            }
            isAdvertising = false
            _isAdvertisingFlow.value = false
        } catch (e: Exception) {
            Timber.e(e, "$TAG: Error stopping advertising")
        }
    }

    // ==================== Scanning ====================

    private fun startScanning() {
        val scanner = adapter?.bluetoothLeScanner ?: run {
            Timber.e("$TAG: BluetoothLeScanner not available")
            return
        }

        val settingsBuilder = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)

        // Enable extended advertisement scanning for Coded PHY
        if (isLongRangeSupported()) {
            settingsBuilder
                .setLegacy(false)
                .setPhy(ScanSettings.PHY_LE_ALL_SUPPORTED)
        }

        val filter = ScanFilter.Builder()
            .setServiceUuid(ParcelUuid(MESH_SERVICE_UUID))
            .build()

        scanCallback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                handleScanResult(result)
            }

            override fun onBatchScanResults(results: MutableList<ScanResult>) {
                results.forEach { handleScanResult(it) }
            }

            override fun onScanFailed(errorCode: Int) {
                Timber.e("$TAG: Scan failed: $errorCode")
                // Schedule retry
                handler.postDelayed({
                    if (isRunning) startScanning()
                }, SCAN_RESTART_INTERVAL_MS)
            }
        }

        try {
            scanner.startScan(listOf(filter), settingsBuilder.build(), scanCallback!!)
            isScanning = true
            _isScanningFlow.value = true
            Timber.i("$TAG: Scanning started (Long Range: ${isLongRangeSupported()})")
        } catch (e: Exception) {
            Timber.e(e, "$TAG: Error starting scan")
        }

        // Schedule periodic scan restart (Android limits continuous scanning)
        handler.postDelayed({
            if (isRunning) {
                stopScanning()
                handler.postDelayed({
                    if (isRunning) startScanning()
                }, 1000)
            }
        }, SCAN_RESTART_INTERVAL_MS)
    }

    /**
     * Attempt to reconnect to known peers that were previously seen but are now disconnected.
     * Called periodically to maintain mesh connectivity through obstacles.
     */
    private fun attemptReconnections() {
        if (!isRunning) return
        val now = System.currentTimeMillis()
        discoveredPeers.values
            .filter { !it.isConnected && !connectedGatts.containsKey(it.address) }
            .filter { now - it.lastSeenMillis < PEER_STALE_TIMEOUT_MS }
            .filter { connectedGatts.size < MAX_CONNECTIONS }
            .forEach { peer ->
                Timber.d("$TAG: Attempting reconnection to ${peer.address}")
                val device = adapter?.getRemoteDevice(peer.address)
                device?.let { connectToPeer(it) }
            }
    }

    private fun stopScanning() {
        val scanner = adapter?.bluetoothLeScanner ?: return
        try {
            scanCallback?.let {
                scanner.stopScan(it)
                scanCallback = null
            }
            isScanning = false
            _isScanningFlow.value = false
        } catch (e: Exception) {
            Timber.e(e, "$TAG: Error stopping scan")
        }
    }

    private fun handleScanResult(result: ScanResult) {
        val device = result.device
        val address = device.address

        // Skip self
        if (address == localDeviceMac) return

        val isCodedPhy = result.primaryPhy == BluetoothDevice.PHY_LE_CODED
        val meshData = result.scanRecord?.getServiceData(ParcelUuid(MESH_SERVICE_UUID))

        val peer = MeshPeer(
            address = address,
            name = device.name,
            rssi = result.rssi,
            isCodedPhy = isCodedPhy,
            primaryPhy = result.primaryPhy,
            secondaryPhy = result.secondaryPhy,
            lastSeenMillis = System.currentTimeMillis(),
            isConnected = connectedGatts.containsKey(address),
            hasOceanService = true
        )

        val existingPeer = discoveredPeers[address]
        if (existingPeer != null) {
            // Update existing peer — preserve connection & service state,
            // refresh lastSeenMillis so stale-cleanup doesn't remove it.
            discoveredPeers[address] = existingPeer.copy(
                rssi = result.rssi,
                lastSeenMillis = System.currentTimeMillis(),
                isCodedPhy = isCodedPhy,
                primaryPhy = result.primaryPhy,
                secondaryPhy = result.secondaryPhy
            )
            updatePeerCounts()

            // Re-connect if previously disconnected and we have capacity
            if (!existingPeer.isConnected && !connectedGatts.containsKey(address)
                && connectedGatts.size < MAX_CONNECTIONS) {
                Timber.i("$TAG: Re-connecting to previously seen peer: $address")
                connectToPeer(device)
            }
        } else {
            // Brand-new peer
            discoveredPeers[address] = peer
            updatePeerCounts()
            onPeerDiscovered?.invoke(peer)
            Timber.i("$TAG: New peer discovered: $address (Coded: $isCodedPhy, RSSI: ${result.rssi})")

            // Auto-connect if we have capacity
            if (connectedGatts.size < MAX_CONNECTIONS) {
                connectToPeer(device)
            }
        }
    }

    // ==================== Connection Management ====================

    private fun connectToPeer(device: BluetoothDevice) {
        if (connectedGatts.containsKey(device.address)) return
        if (connectedGatts.size >= MAX_CONNECTIONS) return

        val phyMask = if (isCodedPhySupported()) {
            BluetoothDevice.PHY_LE_CODED_MASK or BluetoothDevice.PHY_LE_1M_MASK
        } else {
            BluetoothDevice.PHY_LE_1M_MASK
        }

        try {
            device.connectGatt(
                context,
                false, // autoConnect must be false for PHY selection
                gattClientCallback,
                BluetoothDevice.TRANSPORT_LE,
                phyMask,
                handler
            )
        } catch (e: Exception) {
            Timber.e(e, "$TAG: Error connecting to ${device.address}")
        }
    }

    private val gattClientCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            try {
                when (newState) {
                    BluetoothProfile.STATE_CONNECTED -> {
                        Timber.i("$TAG: Connected to ${gatt.device.address}")
                        connectedGatts[gatt.device.address] = gatt
                        updatePeerCounts()
                        gatt.discoverServices()

                        // Request Coded PHY upgrade if supported
                        if (isCodedPhySupported()) {
                            val peerAddress = gatt.device.address
                            handler.postDelayed({
                                // Guard: only upgrade if still connected
                                if (connectedGatts.containsKey(peerAddress)) {
                                    try {
                                        gatt.setPreferredPhy(
                                            BluetoothDevice.PHY_LE_CODED,
                                            BluetoothDevice.PHY_LE_CODED,
                                            BluetoothDevice.PHY_OPTION_S8
                                        )
                                    } catch (e: Exception) {
                                        Timber.w(e, "$TAG: Failed to set Coded PHY")
                                    }
                                }
                            }, 1000)
                        }

                        // Request larger MTU for better throughput
                        gatt.requestMtu(517)

                        discoveredPeers[gatt.device.address]?.let { peer ->
                            discoveredPeers[gatt.device.address] = peer.copy(isConnected = true)
                            onPeerConnected?.invoke(peer.copy(isConnected = true))
                        }
                    }
                    BluetoothProfile.STATE_DISCONNECTED -> {
                        Timber.i("$TAG: Disconnected from ${gatt.device.address}")
                        connectedGatts.remove(gatt.device.address)
                        gatt.close()
                        synchronized(bufferLock) {
                            incomingBuffers.remove(gatt.device.address)
                            bufferTimestamps.remove(gatt.device.address)
                        }
                        updatePeerCounts()

                        discoveredPeers[gatt.device.address]?.let { peer ->
                            discoveredPeers[gatt.device.address] = peer.copy(isConnected = false)
                        }
                        onPeerDisconnected?.invoke(gatt.device.address)
                    }
                }
            } catch (e: Exception) {
                Timber.e(e, "$TAG: Error in GATT client connection state change")
            }
        }

        override fun onPhyUpdate(gatt: BluetoothGatt, txPhy: Int, rxPhy: Int, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                val phyName = when (txPhy) {
                    BluetoothDevice.PHY_LE_CODED -> "Coded (Long Range)"
                    BluetoothDevice.PHY_LE_2M -> "2M (High Speed)"
                    else -> "1M (Standard)"
                }
                Timber.i("$TAG: PHY updated to $phyName for ${gatt.device.address}")

                discoveredPeers[gatt.device.address]?.let { peer ->
                    discoveredPeers[gatt.device.address] = peer.copy(
                        isCodedPhy = txPhy == BluetoothDevice.PHY_LE_CODED,
                        primaryPhy = txPhy
                    )
                }
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                val service = gatt.getService(MESH_SERVICE_UUID)
                if (service != null) {
                    Timber.i("$TAG: Ocean Sentinels service found on ${gatt.device.address}")
                    discoveredPeers[gatt.device.address]?.let { peer ->
                        discoveredPeers[gatt.device.address] = peer.copy(hasOceanService = true)
                    }
                } else {
                    Timber.w("$TAG: No Ocean Sentinels service on ${gatt.device.address}")
                }
            }
        }

        override fun onCharacteristicWrite(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            status: Int
        ) {
            val peerAddress = gatt.device.address
            if (status == BluetoothGatt.GATT_SUCCESS) {
                Timber.d("$TAG: Data written to $peerAddress")
                // Track confirmed write for this peer
                val messageId = activeWriteMessageId.remove(peerAddress)
                if (messageId != null) {
                    confirmedWrites.getOrPut(messageId) {
                        java.util.Collections.synchronizedSet(mutableSetOf())
                    }.add(peerAddress)
                    Timber.i("$TAG: Write confirmed for message $messageId to $peerAddress")
                }
            } else {
                Timber.w("$TAG: Write failed for $peerAddress: $status")
                activeWriteMessageId.remove(peerAddress)
            }
        }

        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray
        ) {
            if (characteristic.uuid == MESH_CHARACTERISTIC_UUID) {
                // Apply same synchronized fragment reassembly for client-side notifications
                val address = gatt.device.address
                val now = System.currentTimeMillis()

                val parsedMessage = synchronized(bufferLock) {
                    val lastWrite = bufferTimestamps[address] ?: 0L
                    if (now - lastWrite > BUFFER_STALE_TIMEOUT_MS) {
                        incomingBuffers.remove(address)
                    }

                    val buffer = incomingBuffers.getOrPut(address) { java.io.ByteArrayOutputStream() }
                    buffer.write(value)
                    bufferTimestamps[address] = now

                    val accumulated = buffer.toByteArray()
                    val json = String(accumulated, Charsets.UTF_8).trim()

                    if (json.startsWith("{") && json.endsWith("}")) {
                        val message = parseMeshMessage(json)
                        if (message != null) {
                            incomingBuffers.remove(address)
                            bufferTimestamps.remove(address)
                            message
                        } else if (json.count { it == '{' } == json.count { it == '}' }) {
                            Timber.w("$TAG: Malformed JSON from $address, clearing buffer")
                            incomingBuffers.remove(address)
                            bufferTimestamps.remove(address)
                            null
                        } else null
                    } else null
                }

                if (parsedMessage != null) {
                    handleIncomingData(parsedMessage, address)
                }
            }
        }

        override fun onMtuChanged(gatt: BluetoothGatt, mtu: Int, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                peerMtu[gatt.device.address] = mtu
                Timber.d("$TAG: MTU changed to $mtu for ${gatt.device.address}")
            } else {
                Timber.w("$TAG: MTU negotiation failed for ${gatt.device.address}, status=$status")
            }
        }
    }

    private fun disconnectAll() {
        connectedGatts.values.forEach { gatt ->
            try {
                gatt.disconnect()
                gatt.close()
            } catch (e: Exception) {
                Timber.e(e, "$TAG: Error disconnecting ${gatt.device.address}")
            }
        }
        connectedGatts.clear()
        updatePeerCounts()
    }

    // ==================== Data Transfer ====================

    /** Track negotiated MTU per peer (default BLE MTU = 23, payload = 20) */
    private val peerMtu = ConcurrentHashMap<String, Int>()

    /**
     * Send a mesh message to all connected peers (flooding broadcast).
     * Handles MTU-aware chunking for large messages.
     * Returns the number of peers it was sent to.
     *
     * Note: sentCount reflects peers where the write was *queued* successfully.
     * Use getConfirmedDeliveryCount(messageId) to check actual confirmed deliveries.
     */
    /**
     * Send a mesh message to all connected peers (flooding broadcast).
     * Handles MTU-aware chunking for large messages.
     * Returns the number of peers it was sent to.
     *
     * @param message The mesh message to broadcast
     * @param excludeAddresses BLE MAC addresses to skip (the peer(s) that sent
     *   this message to us). This prevents echo-back to the sender.
     *
     * Peer exclusion logic (3-layer filter, inspired by bitchat-android):
     * ──────────────────────────────────────────────────────────────────
     * bitchat's BluetoothPacketBroadcaster.broadcastSinglePacketInternal()
     * applies two skip checks per device:
     *   1. device.address == routed.relayAddress  → skip relay hop
     *   2. addressPeerMap[device.address] == senderID  → skip author
     *
     * Our equivalent (3 layers):
     *   1. excludeAddresses.contains(gatt.device.address)
     *      → Skip the BLE peer that forwarded the message to us
     *      → Matches bitchat's relayAddress check
     *   2. addressToDeviceId[gatt.device.address] == originDeviceMac
     *      → Skip the original message author if connected to us
     *      → Matches bitchat's senderID check
     *   3. relayPath.contains(deviceIdForPeer)
     *      → Skip any peer that has previously relayed this message
     *      → More thorough than bitchat (which only checks 1 & 2)
     *
     * Note: sentCount reflects peers where the write was *queued* successfully.
     * Use getConfirmedDeliveryCount(messageId) to check actual confirmed deliveries.
     */
    fun broadcastMessage(message: MeshMessage, excludeAddresses: Set<String> = emptySet()): Int {
        val data = message.toBytes()
        var sentCount = 0

        // Track pending writes for this message
        pendingWrites[message.messageId] = java.util.Collections.synchronizedSet(mutableSetOf())
        confirmedWrites[message.messageId] = java.util.Collections.synchronizedSet(mutableSetOf())

        connectedGatts.values.forEach { gatt ->
            val peerBleAddress = gatt.device.address

            // ── Filter 1: Skip the immediate relay sender ──
            // This is the BLE address of the peer that forwarded this message to us.
            // Matches bitchat's: if (device.address == routed.relayAddress) return@forEach
            if (excludeAddresses.contains(peerBleAddress)) {
                Timber.d("$TAG: Skipping relay back to sender: $peerBleAddress")
                return@forEach
            }

            // ── Filter 2: Skip the original message author ──
            // Resolve BLE address → mesh device ID via our learned mapping.
            // Matches bitchat's: if (addressPeerMap[device.address] == senderID) return@forEach
            val peerDeviceId = addressToDeviceId[peerBleAddress]
            if (peerDeviceId != null && peerDeviceId == message.originDeviceMac) {
                Timber.d("$TAG: Skipping broadcast to original author: $peerBleAddress (deviceId=$peerDeviceId)")
                return@forEach
            }

            // ── Filter 3: Skip peers already in the relay path ──
            // relayPath contains mesh device IDs (not BLE MACs), so we
            // compare against the resolved device ID for this peer.
            // This catches peers that relayed earlier in the chain.
            if (peerDeviceId != null && message.relayPath.contains(peerDeviceId)) {
                Timber.d("$TAG: Skipping peer already in relay path: $peerBleAddress (deviceId=$peerDeviceId)")
                return@forEach
            }

            try {
                val service = gatt.getService(MESH_SERVICE_UUID)
                if (service == null) {
                    Timber.w("$TAG: GATT service not found on ${gatt.device.address}, skipping")
                    return@forEach
                }
                val characteristic = service.getCharacteristic(MESH_CHARACTERISTIC_UUID)
                if (characteristic == null) {
                    Timber.w("$TAG: GATT characteristic not found on ${gatt.device.address}, skipping")
                    return@forEach
                }

                // Track which message we're writing to this peer
                activeWriteMessageId[gatt.device.address] = message.messageId
                pendingWrites[message.messageId]?.add(gatt.device.address)

                // Get effective MTU payload size (MTU - 3 bytes GATT overhead)
                val mtu = peerMtu.getOrDefault(gatt.device.address, 23)
                val maxPayload = (mtu - 3).coerceAtLeast(20)

                if (data.size <= maxPayload) {
                    // Single write -- fits in one packet
                    characteristic.value = data
                    characteristic.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
                    if (gatt.writeCharacteristic(characteristic)) {
                        sentCount++
                        Timber.d("$TAG: Sent ${data.size}B to ${gatt.device.address}")
                    } else {
                        activeWriteMessageId.remove(gatt.device.address)
                    }
                } else {
                    // Chunked write -- split into MTU-sized fragments
                    val chunks = data.toList().chunked(maxPayload).map { it.toByteArray() }
                    val peerAddress = gatt.device.address
                    writeChunksSequentially(gatt, characteristic, chunks, 0, peerAddress, message.messageId)
                    sentCount++
                }
            } catch (e: Exception) {
                Timber.e(e, "$TAG: Error sending to ${gatt.device.address}")
                activeWriteMessageId.remove(gatt.device.address)
            }
        }

        if (sentCount > 0) {
            onMessageSent?.invoke(message.messageId, true)
        }

        Timber.i("$TAG: Broadcast message ${message.messageId} to $sentCount peers")
        return sentCount
    }

    /**
     * Check how many peers have confirmed receiving a given message.
     */
    fun getConfirmedDeliveryCount(messageId: String): Int {
        return confirmedWrites[messageId]?.size ?: 0
    }

    /**
     * Check if at least one peer confirmed receiving the message.
     */
    fun isMessageConfirmedByAnyPeer(messageId: String): Boolean {
        return (confirmedWrites[messageId]?.size ?: 0) > 0
    }

    /**
     * Clean up tracking data for a message (after it's been processed).
     */
    fun clearMessageTracking(messageId: String) {
        pendingWrites.remove(messageId)
        confirmedWrites.remove(messageId)
    }

    /**
     * Write chunks sequentially with non-blocking delays.
     * Uses handler.postDelayed instead of Thread.sleep to avoid ANR.
     */
    private fun writeChunksSequentially(
        gatt: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic,
        chunks: List<ByteArray>,
        index: Int,
        peerAddress: String,
        messageId: String
    ) {
        if (index >= chunks.size) {
            Timber.d("$TAG: All ${chunks.size} chunks sent to $peerAddress")
            return
        }
        if (!connectedGatts.containsKey(peerAddress)) {
            Timber.w("$TAG: Peer $peerAddress disconnected during chunked write")
            return
        }

        try {
            characteristic.value = chunks[index]
            characteristic.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
            if (gatt.writeCharacteristic(characteristic)) {
                if (index < chunks.size - 1) {
                    handler.postDelayed({
                        writeChunksSequentially(gatt, characteristic, chunks, index + 1, peerAddress, messageId)
                    }, 50)
                }
            } else {
                Timber.w("$TAG: Chunk $index/${chunks.size} failed for $peerAddress")
            }
        } catch (e: Exception) {
            Timber.e(e, "$TAG: Error writing chunk $index to $peerAddress")
        }
    }

    /**
     * Send a message to a specific connected peer.
     */
    fun sendToPeer(message: MeshMessage, peerAddress: String): Boolean {
        val gatt = connectedGatts[peerAddress] ?: return false
        val data = message.toBytes()

        try {
            val service = gatt.getService(MESH_SERVICE_UUID)
            if (service == null) {
                Timber.w("$TAG: GATT service not found on $peerAddress")
                return false
            }
            val characteristic = service.getCharacteristic(MESH_CHARACTERISTIC_UUID)
            if (characteristic == null) {
                Timber.w("$TAG: GATT characteristic not found on $peerAddress")
                return false
            }

            characteristic.value = data
            characteristic.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
            return gatt.writeCharacteristic(characteristic)
        } catch (e: Exception) {
            Timber.e(e, "$TAG: Error sending to $peerAddress")
        }
        return false
    }

    /** Handle an already-parsed message from a peer, with deduplication */
    private fun handleIncomingData(message: MeshMessage, senderAddress: String) {
        // Deduplication check
        if (isDuplicate(message.messageId)) {
            Timber.d("$TAG: Duplicate message ignored: ${message.messageId}")
            return
        }

        markProcessed(message.messageId)

        // Learn this peer's mesh device ID from their message.
        // This builds our addressToDeviceId map (like bitchat's
        // BluetoothConnectionTracker.addressPeerMap) so broadcastMessage()
        // can skip the original author when relaying.
        if (message.originDeviceMac.isNotBlank()) {
            addressToDeviceId[senderAddress] = message.originDeviceMac
            Timber.d("$TAG: Learned peer identity: $senderAddress → ${message.originDeviceMac}")
        }

        Timber.i("$TAG: Received message ${message.messageId} from $senderAddress (hop: ${message.hopCount})")
        // Pass sender BLE address so the service can exclude it during relay
        onMessageReceived?.invoke(message, senderAddress)
    }

    /** Handle raw incoming bytes from a peer (non-fragmented path) */
    private fun handleIncomingRawData(data: ByteArray, senderAddress: String) {
        try {
            val json = String(data, Charsets.UTF_8)
            val message = parseMeshMessage(json)

            if (message != null) {
                handleIncomingData(message, senderAddress)
            }
        } catch (e: Exception) {
            Timber.e(e, "$TAG: Error parsing incoming data from $senderAddress")
        }
    }

    // ==================== Deduplication ====================

    /** Check if a message has already been processed */
    fun isDuplicate(messageId: String): Boolean {
        return processedMessageIds.contains(messageId)
    }

    /** Mark a message as processed */
    fun markProcessed(messageId: String) {
        processedMessageIds.add(messageId) // LRU auto-evicts oldest entries
    }

    // ==================== Peer Management ====================

    /** Get all discovered peers */
    fun getDiscoveredPeers(): List<MeshPeer> = discoveredPeers.values.toList()

    /** Get connected peers only */
    fun getConnectedPeers(): List<MeshPeer> =
        discoveredPeers.values.filter { it.isConnected }.toList()

    /** Get connected peer count */
    fun getConnectedPeerCount(): Int = connectedGatts.size

    /** Periodic cleanup of stale peers */
    private fun startPeerCleanup() {
        handler.postDelayed(object : Runnable {
            override fun run() {
                if (!isRunning) return

                val now = System.currentTimeMillis()
                val staleAddresses = discoveredPeers.entries
                    .filter { now - it.value.lastSeenMillis > PEER_STALE_TIMEOUT_MS }
                    .map { it.key }

                staleAddresses.forEach { address ->
                    discoveredPeers.remove(address)
                    connectedGatts[address]?.let { gatt ->
                        gatt.disconnect()
                        gatt.close()
                        connectedGatts.remove(address)
                    }
                    Timber.d("$TAG: Removed stale peer: $address")
                }

                if (staleAddresses.isNotEmpty()) {
                    updatePeerCounts()
                }

                handler.postDelayed(this, 60_000)
            }
        }, 60_000)
    }

    /** Periodically attempt to reconnect to known disconnected peers */
    private fun startReconnectionLoop() {
        handler.postDelayed(object : Runnable {
            override fun run() {
                if (!isRunning) return
                attemptReconnections()
                handler.postDelayed(this, RECONNECT_INTERVAL_MS)
            }
        }, RECONNECT_INTERVAL_MS)
    }

    // ==================== Status ====================

    fun isRunning(): Boolean = isRunning
    fun isAdvertising(): Boolean = isAdvertising
    fun isScanning(): Boolean = isScanning

    // ==================== Message Parsing ====================

    private val gson = Gson()

    /**
     * Parse a JSON mesh message using Gson for robust handling.
     */
    private fun parseMeshMessage(json: String): MeshMessage? {
        try {
            val obj = JsonParser.parseString(json).asJsonObject

            val id = obj.get("id")?.asString ?: return null
            val mac = obj.get("mac")?.asString ?: return null
            val fp = obj.get("fp")?.asString ?: return null
            val ht = obj.get("ht")?.asString ?: return null
            val loc = obj.get("loc")?.asString ?: ""
            val lat = obj.get("lat")?.asDouble
            val lng = obj.get("lng")?.asDouble
            val desc = obj.get("desc")?.asString ?: ""
            val urg = obj.get("urg")?.asString ?: "medium"
            val ts = obj.get("ts")?.asLong ?: System.currentTimeMillis()
            val hops = obj.get("hops")?.asInt ?: 0
            val photo = obj.get("photo")?.asString
            val contact = obj.get("contact")?.asString
            val uid = obj.get("uid")?.asInt

            val path = if (obj.has("path") && obj.get("path").isJsonArray) {
                obj.getAsJsonArray("path").map { it.asString }
            } else {
                emptyList()
            }

            return MeshMessage(
                messageId = id,
                originDeviceMac = mac,
                originDeviceFingerprint = fp,
                hazardType = ht,
                location = loc,
                latitude = lat,
                longitude = lng,
                description = desc,
                urgency = urg,
                createdAtMillis = ts,
                hopCount = hops,
                relayPath = path,
                photoUrl = photo,
                contactInfo = contact,
                reporterUserId = uid
            )
        } catch (e: Exception) {
            Timber.e(e, "$TAG: Failed to parse mesh message")
            return null
        }
    }

    /** Get the local device identifier (persistent, not MAC) */
    fun getLocalDeviceId(): String = localDeviceId
}
