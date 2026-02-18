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
        /** Client Characteristic Configuration Descriptor UUID (standard BLE CCCD) */
        val CCCD_UUID: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")

        /** Maximum BLE packet size before fragmentation */
        const val MAX_PACKET_SIZE = 512
        /** Fragment size for BLE transmission */
        const val FRAGMENT_SIZE = 469
        /** Scan interval between restarts (aligned with relay interval) */
        const val SCAN_RESTART_INTERVAL_MS = 15_000L
        /** Duty-cycle scan ON duration — 8s to catch Coded PHY long preamble */
        const val SCAN_DUTY_ON_MS = 8_000L
        /** Duty-cycle scan OFF duration — 2s pause to prevent Android throttling */
        const val SCAN_DUTY_OFF_MS = 2_000L
        /** Minimum interval between scan starts to prevent Android error 6 */
        const val SCAN_RATE_LIMIT_MS = 5_000L
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
    /** Tracks addresses with a pending connectGatt() call that hasn't resolved yet */
    private val pendingConnections = java.util.Collections.synchronizedSet(mutableSetOf<String>())
    /** Timestamps for pending connections — used to cleanup stuck entries */
    private val pendingConnectionTimestamps = ConcurrentHashMap<String, Long>()

    /**
     * Devices that have subscribed to GATT server notifications (via CCCD write).
     * These are peers connected to OUR server that we can push data to via
     * notifyCharacteristicChanged() — the second write path alongside connectedGatts.
     *
     * This matches bitchat's subscribedDevices in BluetoothGattServerManager which
     * broadcasts to both server-subscribed and client-connected devices.
     */
    private val notificationSubscribers = ConcurrentHashMap<String, BluetoothDevice>()

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

    /**
     * Try to reassemble a complete message from accumulated buffer data.
     * MUST be called inside synchronized(bufferLock).
     *
     * Supports two wire formats with automatic detection:
     * 1. Length-prefix (new): [4-byte BE length][UTF-8 JSON payload]
     *    - Reliable: receiver knows exactly how many bytes to expect
     *    - First byte will NOT be '{' (0x7B) for any realistic payload size
     * 2. Legacy brace-counting (old): raw UTF-8 JSON starting with '{'
     *    - Backward compatible with peers running older app versions
     *    - Fragile: fails if description contains literal braces
     *
     * Detection: if first accumulated byte == '{', use legacy. Otherwise, length-prefix.
     * This is safe because a length prefix starting with 0x7B would mean a payload
     * of >= 2 billion bytes — impossible over BLE.
     *
     * @param address BLE address of the sending device (buffer key)
     * @return Parsed MeshMessage if reassembly is complete, null if more data needed
     */
    private fun tryReassembleMessage(address: String): MeshMessage? {
        val buffer = incomingBuffers[address] ?: return null
        val accumulated = buffer.toByteArray()
        if (accumulated.isEmpty()) return null

        val isLegacyFormat = accumulated[0] == '{'.code.toByte()

        if (isLegacyFormat) {
            // Legacy brace-counting fallback for old peers
            val json = String(accumulated, Charsets.UTF_8).trim()
            if (json.startsWith("{") && json.endsWith("}")) {
                val message = parseMeshMessage(json)
                if (message != null) {
                    incomingBuffers.remove(address)
                    bufferTimestamps.remove(address)
                    return message
                } else if (json.count { it == '{' } == json.count { it == '}' }) {
                    Timber.w("$TAG: Malformed legacy JSON from $address, clearing buffer")
                    incomingBuffers.remove(address)
                    bufferTimestamps.remove(address)
                }
            }
        } else {
            // Length-prefix protocol: [4-byte BE length][payload]
            if (accumulated.size < 4) return null // Need more data for header

            val expectedLen = ((accumulated[0].toInt() and 0xFF) shl 24) or
                    ((accumulated[1].toInt() and 0xFF) shl 16) or
                    ((accumulated[2].toInt() and 0xFF) shl 8) or
                    (accumulated[3].toInt() and 0xFF)

            // Sanity: reject implausible lengths (>1MB — no BLE message is that large)
            if (expectedLen <= 0 || expectedLen > 1_048_576) {
                Timber.w("$TAG: Invalid length prefix ($expectedLen) from $address, clearing buffer")
                incomingBuffers.remove(address)
                bufferTimestamps.remove(address)
                return null
            }

            if (accumulated.size >= 4 + expectedLen) {
                val payload = accumulated.copyOfRange(4, 4 + expectedLen)
                val json = String(payload, Charsets.UTF_8)
                incomingBuffers.remove(address)
                bufferTimestamps.remove(address)
                val message = parseMeshMessage(json)
                if (message != null) {
                    return message
                } else {
                    Timber.w("$TAG: Length-prefix payload invalid JSON from $address (len=$expectedLen)")
                }
            }
            // else: still accumulating chunks, need more data
        }
        return null
    }

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

        // ── Clear ALL in-memory state ──
        // Without this, stale peers/dedup entries survive a stop()+start()
        // cycle and cause connection failures on the next session.
        // Clearing app data/cache fixes this because it restarts the process
        // and recreates the Hilt singleton, but we must not require that.
        incomingBuffers.clear()
        bufferTimestamps.clear()
        discoveredPeers.clear()
        pendingConnections.clear()
        pendingConnectionTimestamps.clear()
        notificationSubscribers.clear()
        peerMtu.clear()
        addressToDeviceId.clear()
        processedMessageIds.clear()
        pendingWrites.clear()
        confirmedWrites.clear()
        activeWriteMessageId.clear()
        peerWriteQueue.clear()

        handler.removeCallbacksAndMessages(null)

        // Reset UI state
        updatePeerCounts()
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

            // ── CCCD Descriptor (required for GATT notifications) ──
            // Without this descriptor, clients cannot subscribe to notifications
            // and gattServer.notifyCharacteristicChanged() silently fails.
            // The CCCD lets clients write ENABLE_NOTIFICATION_VALUE to opt-in.
            val cccdDescriptor = BluetoothGattDescriptor(
                CCCD_UUID,
                BluetoothGattDescriptor.PERMISSION_READ or
                        BluetoothGattDescriptor.PERMISSION_WRITE
            )
            characteristic.addDescriptor(cccdDescriptor)

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
                        // Only register as a new peer if we don't already know them
                        // from the client side (scan → connectToPeer). If the client
                        // callback already added a richer MeshPeer with RSSI/PHY info,
                        // don't overwrite it with a bare peer (rssi=0, isCodedPhy=false).
                        val existingPeer = discoveredPeers[device.address]
                        if (existingPeer == null) {
                            // Unknown device connected to our GATT server.
                            // Mark hasOceanService=false until they actually write to
                            // our mesh characteristic (proving they're an Ocean Sentinels peer).
                            val peer = MeshPeer(
                                address = device.address,
                                name = device.name,
                                rssi = 0,
                                isCodedPhy = false,
                                primaryPhy = BluetoothDevice.PHY_LE_1M,
                                secondaryPhy = 0,
                                lastSeenMillis = System.currentTimeMillis(),
                                isConnected = true,
                                hasOceanService = false // proven when they write to our characteristic
                            )
                            discoveredPeers[device.address] = peer
                            updatePeerCounts()
                            onPeerConnected?.invoke(peer)
                        } else if (!existingPeer.isConnected) {
                            // Known peer reconnecting via server side — update status
                            val updated = existingPeer.copy(
                                isConnected = true,
                                lastSeenMillis = System.currentTimeMillis()
                            )
                            discoveredPeers[device.address] = updated
                            updatePeerCounts()
                            onPeerConnected?.invoke(updated)
                        }

                        // ── FIX: Initiate reverse client connection ──
                        // When a peer connects to our GATT server, we can RECEIVE
                        // their writes but we CANNOT write to them (no client GATT).
                        // broadcastMessage() only uses connectedGatts (client handles).
                        // Without a reverse client connection, messages received here
                        // get stuck — we can't relay them forward.
                        //
                        // Solution: If we don't already have a client GATT handle,
                        // connect back as a client so broadcastMessage() can reach them.
                        if (!connectedGatts.containsKey(device.address)
                            && !pendingConnections.contains(device.address)
                            && connectedGatts.size + pendingConnections.size < MAX_CONNECTIONS) {
                            handler.postDelayed({
                                if (isRunning && !connectedGatts.containsKey(device.address)
                                    && !pendingConnections.contains(device.address)
                                    && connectedGatts.size + pendingConnections.size < MAX_CONNECTIONS) {
                                    Timber.i("$TAG: Initiating reverse client connection to ${device.address}")
                                    connectToPeer(device)
                                }
                            }, 1500) // Delay to let initial connection settle
                        }
                    }
                    BluetoothProfile.STATE_DISCONNECTED -> {
                        Timber.i("$TAG: Device disconnected from server: ${device.address}")
                        notificationSubscribers.remove(device.address)
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

                    // Try to reassemble using length-prefix or legacy brace-counting
                    tryReassembleMessage(address)
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

                // Mark hasOceanService=true: this device wrote to our mesh
                // characteristic, proving it's a real Ocean Sentinels peer
                // (not just a random BLE device that connected to our GATT server).
                discoveredPeers[device.address]?.let { peer ->
                    if (!peer.hasOceanService) {
                        discoveredPeers[device.address] = peer.copy(hasOceanService = true)
                    }
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

        /**
         * Handle CCCD descriptor writes — clients subscribing/unsubscribing
         * to GATT notifications.
         *
         * When a client writes ENABLE_NOTIFICATION_VALUE to the CCCD, we add
         * them to notificationSubscribers so broadcastMessage() can push
         * data to them via notifyCharacteristicChanged().
         *
         * This is the Ocean Sentinels equivalent of bitchat's
         * BluetoothGattServerManager.onDescriptorWriteRequest() which tracks
         * subscribedDevices for server-push broadcasting.
         */
        override fun onDescriptorWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            descriptor: BluetoothGattDescriptor,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray?
        ) {
            if (descriptor.uuid == CCCD_UUID) {
                if (value != null && value.contentEquals(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)) {
                    notificationSubscribers[device.address] = device
                    Timber.i("$TAG: Notification subscriber added: ${device.address} (total: ${notificationSubscribers.size})")
                } else {
                    notificationSubscribers.remove(device.address)
                    Timber.i("$TAG: Notification subscriber removed: ${device.address} (total: ${notificationSubscribers.size})")
                }

                if (responseNeeded) {
                    gattServer?.sendResponse(
                        device, requestId, BluetoothGatt.GATT_SUCCESS, offset, null
                    )
                }
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

    /** Timestamp of the last scan start — used for rate-limiting */
    private var lastScanStartTime = 0L

    /**
     * Duty-cycle scan runnable — prevents Android from throttling continuous
     * LOW_LATENCY scanning after ~30 minutes.
     *
     * Cycle: 8s scan ON → 2s OFF → repeat.
     * 80% duty cycle still catches Coded PHY's long preamble (~1ms) easily.
     *
     * Inspired by bitchat's PowerManager.kt which uses 8s/2s cycling for
     * PERFORMANCE mode and 2s/28s for BATTERY_SAVER mode.
     */
    private val scanDutyCycleRunnable = object : Runnable {
        override fun run() {
            if (!isRunning) return
            stopScanning()
            // OFF period — then restart
            handler.postDelayed({
                if (isRunning) {
                    startScanning()
                }
            }, SCAN_DUTY_OFF_MS)
        }
    }

    /** Reusable scan-restart runnable — prevents stacking duplicate restarts */
    private val scanRestartRunnable = object : Runnable {
        override fun run() {
            if (!isRunning) return
            stopScanning()
            handler.postDelayed({
                if (isRunning) startScanning()
            }, 1000)
        }
    }

    private fun startScanning() {
        // ── Rate-limit: prevent Android "scanning too frequently" error (code 6) ──
        // Matches bitchat's 5s minimum between scan starts.
        val now = System.currentTimeMillis()
        val elapsed = now - lastScanStartTime
        if (elapsed < SCAN_RATE_LIMIT_MS) {
            val waitMs = SCAN_RATE_LIMIT_MS - elapsed
            Timber.d("$TAG: Scan rate-limited, retrying in ${waitMs}ms")
            handler.postDelayed({
                if (isRunning) startScanning()
            }, waitMs)
            return
        }
        lastScanStartTime = now

        val scanner = adapter?.bluetoothLeScanner ?: run {
            Timber.e("$TAG: BluetoothLeScanner not available")
            return
        }

        val settingsBuilder = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)

        // Enable extended advertisement scanning for Coded PHY
        // Requires API 26+ (Oreo) for setLegacy() and setPhy() methods
        if (isLongRangeSupported() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
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
                // Schedule retry — remove old restart first to prevent stacking
                handler.removeCallbacks(scanRestartRunnable)
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

        // ── Duty-cycle scanning: 8s ON then 2s OFF ──
        // Prevents Android from silently throttling continuous LOW_LATENCY scans
        // after ~30 minutes. The 2s OFF resets the throttle counter.
        // Also schedule the periodic full restart as a safety net.
        handler.removeCallbacks(scanDutyCycleRunnable)
        handler.removeCallbacks(scanRestartRunnable)
        handler.postDelayed(scanDutyCycleRunnable, SCAN_DUTY_ON_MS)
        handler.postDelayed(scanRestartRunnable, SCAN_RESTART_INTERVAL_MS)
    }

    /**
     * Attempt to reconnect to known peers that were previously seen but are now disconnected.
     * Called periodically to maintain mesh connectivity through obstacles.
     */
    private fun attemptReconnections() {
        if (!isRunning) return
        val now = System.currentTimeMillis()

        // ── Cleanup stale pending connections (>15s timeout) ──
        // If connectGatt() never fires onConnectionStateChange (e.g., device
        // walked away before GATT response), the address stays in pendingConnections
        // forever, permanently blocking reconnection attempts for that peer.
        val staleThreshold = 15_000L
        val stalePending = pendingConnectionTimestamps.entries
            .filter { now - it.value > staleThreshold }
            .map { it.key }
        stalePending.forEach { address ->
            pendingConnections.remove(address)
            pendingConnectionTimestamps.remove(address)
            Timber.d("$TAG: Cleared stale pending connection for $address (>15s)")
        }

        discoveredPeers.values
            // ── FIX: Reconnect any peer missing a client GATT handle ──
            // Previous: filtered `!it.isConnected` which missed server-only peers
            // (marked isConnected=true from GATT server callback but no client GATT).
            // Now: only check connectedGatts — if no client handle, reconnect.
            .filter { !connectedGatts.containsKey(it.address) }
            .filter { !pendingConnections.contains(it.address) } // skip already-pending
            .filter { now - it.lastSeenMillis < PEER_STALE_TIMEOUT_MS }
            .filter { connectedGatts.size + pendingConnections.size < MAX_CONNECTIONS }
            .forEach { peer ->
                Timber.d("$TAG: Attempting reconnection to ${peer.address}")
                val device = adapter?.getRemoteDevice(peer.address)
                device?.let { connectToPeerAutoConnect(it) }
            }
    }

    /**
     * Connect to a peer with autoConnect=true.
     * Used for reconnection of previously-known peers that went behind an obstacle.
     * autoConnect=true uses Android's internal LOW_POWER scan to automatically
     * reconnect when the peer returns to range — ideal for intermittent obstacles.
     *
     * Note: autoConnect=true does NOT support PHY selection (always uses 1M),
     * but the PHY upgrade to Coded is requested after connection in the callback.
     */
    private fun connectToPeerAutoConnect(device: BluetoothDevice) {
        if (connectedGatts.containsKey(device.address)) return
        if (connectedGatts.size >= MAX_CONNECTIONS) return
        if (!pendingConnections.add(device.address)) {
            Timber.d("$TAG: Reconnection already pending for ${device.address}, skipping")
            return
        }
        pendingConnectionTimestamps[device.address] = System.currentTimeMillis()

        try {
            device.connectGatt(
                context,
                true, // autoConnect for obstacle-lost peers
                gattClientCallback,
                BluetoothDevice.TRANSPORT_LE
            )
            Timber.d("$TAG: AutoConnect reconnection initiated for ${device.address}")
        } catch (e: Exception) {
            pendingConnections.remove(device.address)
            Timber.e(e, "$TAG: Error auto-connecting to ${device.address}")
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

            // ── FIX: Connect as CLIENT even if peer is server-side connected ──
            // Previous bug: when peer B connected to our GATT server, we marked
            // B as isConnected=true. When we later scanned B, the check
            // `!existingPeer.isConnected` was false → we skipped client connection.
            // Result: broadcastMessage() iterates connectedGatts (client handles
            // only) → couldn't write to B → messages got stuck on this device.
            //
            // Fix: Check connectedGatts (client GATT) instead of isConnected
            // (which covers both server+client). We MUST have a client GATT
            // to write/relay messages to a peer.
            if (!connectedGatts.containsKey(address)
                && !pendingConnections.contains(address)
                && connectedGatts.size + pendingConnections.size < MAX_CONNECTIONS) {
                Timber.i("$TAG: Establishing client GATT to peer: $address (server-side connected: ${existingPeer.isConnected})")
                connectToPeer(device)
            }
        } else {
            // Brand-new peer
            discoveredPeers[address] = peer
            updatePeerCounts()
            onPeerDiscovered?.invoke(peer)
            Timber.i("$TAG: New peer discovered: $address (Coded: $isCodedPhy, RSSI: ${result.rssi})")

            // Auto-connect if we have capacity
            if (connectedGatts.size + pendingConnections.size < MAX_CONNECTIONS) {
                connectToPeer(device)
            }
        }
    }

    // ==================== Connection Management ====================

    private fun connectToPeer(device: BluetoothDevice) {
        if (connectedGatts.containsKey(device.address)) return
        if (connectedGatts.size >= MAX_CONNECTIONS) return
        // Prevent duplicate connectGatt() calls while a connection attempt
        // is still pending. Without this guard, rapid scan results trigger
        // multiple connectGatt() calls for the same address, each creating
        // a separate BluetoothGatt object. Android's BLE stack has a hard
        // limit (~7 GATT clients), and these phantom GATT handles exhaust it,
        // blocking connections to the 3rd, 4th, ... device.
        if (!pendingConnections.add(device.address)) {
            Timber.d("$TAG: Connection already pending for ${device.address}, skipping")
            return
        }
        pendingConnectionTimestamps[device.address] = System.currentTimeMillis()

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
            pendingConnections.remove(device.address)
            Timber.e(e, "$TAG: Error connecting to ${device.address}")
        }
    }

    private val gattClientCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            val address = gatt.device.address
            // Always clear pending state — the connection attempt has resolved
            pendingConnections.remove(address)
            pendingConnectionTimestamps.remove(address)

            try {
                // Handle GATT errors (status != 0) — the connection failed or was lost.
                // Common codes: 133 (GATT_ERROR), 8 (CONN_TIMEOUT), 19 (TERMINATED_BY_PEER)
                // Some OEMs fire non-zero status with STATE_DISCONNECTED, others with
                // intermediate states. Treat ANY non-zero status as disconnection.
                if (status != BluetoothGatt.GATT_SUCCESS && newState != BluetoothProfile.STATE_CONNECTED) {
                    Timber.w("$TAG: GATT error for $address: status=$status, newState=$newState")
                    connectedGatts.remove(address)
                    gatt.close() // MUST close to free the GATT client slot
                    peerMtu.remove(address)
                    peerWriteQueue.remove(address)
                    synchronized(bufferLock) {
                        incomingBuffers.remove(address)
                        bufferTimestamps.remove(address)
                    }
                    discoveredPeers[address]?.let { peer ->
                        discoveredPeers[address] = peer.copy(isConnected = false)
                    }
                    updatePeerCounts()
                    onPeerDisconnected?.invoke(address)
                    return
                }

                when (newState) {
                    BluetoothProfile.STATE_CONNECTED -> {
                        Timber.i("$TAG: Connected to $address")
                        connectedGatts[address] = gatt
                        updatePeerCounts()
                        gatt.discoverServices()

                        // Request Coded PHY upgrade if supported
                        if (isCodedPhySupported()) {
                            handler.postDelayed({
                                // Guard: only upgrade if still connected
                                if (connectedGatts.containsKey(address)) {
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

                        // ── Request high connection priority for obstacle reliability ──
                        // CONNECTION_PRIORITY_HIGH requests ~11.25ms connection interval
                        // from the controller. More frequent link-layer transmissions
                        // = more retry opportunities through walls and obstacles.
                        // This is the single biggest improvement for through-wall
                        // BLE reliability. Battery cost is acceptable for a mesh relay.
                        gatt.requestConnectionPriority(BluetoothGatt.CONNECTION_PRIORITY_HIGH)
                        Timber.d("$TAG: CONNECTION_PRIORITY_HIGH requested for $address")

                        discoveredPeers[address]?.let { peer ->
                            discoveredPeers[address] = peer.copy(isConnected = true)
                            onPeerConnected?.invoke(peer.copy(isConnected = true))
                        }
                    }
                    BluetoothProfile.STATE_DISCONNECTED -> {
                        Timber.i("$TAG: Disconnected from $address")
                        connectedGatts.remove(address)
                        gatt.close()
                        peerMtu.remove(address)
                        peerWriteQueue.remove(address)
                        synchronized(bufferLock) {
                            incomingBuffers.remove(address)
                            bufferTimestamps.remove(address)
                        }
                        updatePeerCounts()

                        discoveredPeers[address]?.let { peer ->
                            discoveredPeers[address] = peer.copy(isConnected = false)
                        }
                        onPeerDisconnected?.invoke(address)
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

                    // ── Subscribe to GATT notifications from this peer's server ──
                    // This enables the peer to push data to us via
                    // notifyCharacteristicChanged() — the second receive path
                    // alongside our GATT client writes. The existing
                    // onCharacteristicChanged handler already handles incoming
                    // notification data with fragment reassembly.
                    val characteristic = service.getCharacteristic(MESH_CHARACTERISTIC_UUID)
                    if (characteristic != null) {
                        gatt.setCharacteristicNotification(characteristic, true)

                        val cccd = characteristic.getDescriptor(CCCD_UUID)
                        if (cccd != null) {
                            cccd.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                            gatt.writeDescriptor(cccd)
                            Timber.i("$TAG: Subscribed to notifications on ${gatt.device.address}")
                        } else {
                            Timber.w("$TAG: No CCCD descriptor on ${gatt.device.address}, notifications may not work")
                        }
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
                // Drain queued writes for this peer now that the slot is free
                drainPeerWriteQueue(peerAddress)
            } else {
                Timber.w("$TAG: Write failed for $peerAddress: $status")
                activeWriteMessageId.remove(peerAddress)
                // Still try to drain queue — the failed message is lost but
                // queued messages may succeed
                drainPeerWriteQueue(peerAddress)
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

                    // Try to reassemble using length-prefix or legacy brace-counting
                    tryReassembleMessage(address)
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
        pendingConnections.clear()
        peerMtu.clear()
        updatePeerCounts()
    }

    // ==================== Data Transfer ====================

    /** Track negotiated MTU per peer (default BLE MTU = 23, payload = 20) */
    private val peerMtu = ConcurrentHashMap<String, Int>()

    /**
     * Per-peer write queue for messages that couldn't be sent immediately
     * because the peer had an active in-flight write.
     *
     * Previously, busy peers were skipped with `return@forEach` and had to
     * wait for the next relay cycle (15s). Now they're enqueued and drained
     * immediately when the current write completes (via onCharacteristicWrite).
     *
     * Maps peerAddress → queue of (data, messageId) pairs.
     */
    private val peerWriteQueue = ConcurrentHashMap<String, java.util.ArrayDeque<Pair<ByteArray, String>>>()

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

            // ── Filter 0: Queue for peers with an active in-flight write ──
            // Android BLE stack allows only one outstanding writeCharacteristic()
            // per GATT client. Instead of skipping busy peers entirely (losing
            // the message until next relay cycle), enqueue for immediate delivery
            // when the current write completes via onCharacteristicWrite callback.
            if (activeWriteMessageId.containsKey(peerBleAddress)) {
                val queue = peerWriteQueue.getOrPut(peerBleAddress) { java.util.ArrayDeque() }
                queue.offer(Pair(data, message.messageId))
                sentCount++ // Count as queued (will be sent shortly)
                Timber.d("$TAG: Peer $peerBleAddress busy, enqueued message (queue: ${queue.size})")
                return@forEach
            }

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

        // ── Second write path: GATT server notifications ──
        // Push data to peers that connected to OUR server and subscribed
        // to notifications (via CCCD write). This is the critical fix for
        // multi-hop relay: when Device D connects to Device C's GATT server
        // but C's reverse client connection to D fails (GATT error 133),
        // C can still push data to D via server notifications.
        //
        // This matches bitchat's dual-path approach:
        // BluetoothPacketBroadcaster iterates BOTH subscribedDevices
        // (server-push) AND connectedDevices (client-write).
        if (notificationSubscribers.isNotEmpty()) {
            val server = gattServer
            val gattService = server?.getService(MESH_SERVICE_UUID)
            val gattCharacteristic = gattService?.getCharacteristic(MESH_CHARACTERISTIC_UUID)

            if (server != null && gattCharacteristic != null) {
                notificationSubscribers.forEach { (subscriberAddress, subscriberDevice) ->
                    // Skip peers already handled via client GATT write above
                    if (connectedGatts.containsKey(subscriberAddress)) {
                        return@forEach
                    }

                    // Apply same 3-layer filter as client path
                    if (excludeAddresses.contains(subscriberAddress)) {
                        Timber.d("$TAG: Skipping server-notify back to sender: $subscriberAddress")
                        return@forEach
                    }
                    val subDeviceId = addressToDeviceId[subscriberAddress]
                    if (subDeviceId != null && subDeviceId == message.originDeviceMac) {
                        Timber.d("$TAG: Skipping server-notify to original author: $subscriberAddress")
                        return@forEach
                    }
                    if (subDeviceId != null && message.relayPath.contains(subDeviceId)) {
                        Timber.d("$TAG: Skipping server-notify to peer in relay path: $subscriberAddress")
                        return@forEach
                    }

                    try {
                        // Use higher default MTU for server notifications.
                        // Default BLE MTU=23 gives only 20B payload, causing
                        // a 500B message to split into 25 chunks × 200ms = 5s.
                        // Using 185 (common negotiated MTU) gives ~182B payload,
                        // reducing to 3 chunks × 200ms = 0.6s.
                        // peerMtu has the actual negotiated value if a client
                        // GATT also exists; otherwise this reasonable default
                        // works for most modern BLE devices.
                        val mtu = peerMtu.getOrDefault(subscriberAddress, 185)
                        val maxPayload = (mtu - 3).coerceAtLeast(20)

                        if (data.size <= maxPayload) {
                            gattCharacteristic.value = data
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                val result = server.notifyCharacteristicChanged(
                                    subscriberDevice, gattCharacteristic, false, data
                                )
                                if (result == BluetoothGatt.GATT_SUCCESS) {
                                    sentCount++
                                    Timber.d("$TAG: Server-notified ${data.size}B to $subscriberAddress")
                                }
                            } else {
                                @Suppress("DEPRECATION")
                                val sent = server.notifyCharacteristicChanged(
                                    subscriberDevice, gattCharacteristic, false
                                )
                                if (sent) {
                                    sentCount++
                                    Timber.d("$TAG: Server-notified ${data.size}B to $subscriberAddress")
                                }
                            }
                        } else {
                            // Chunked notification for large messages
                            val chunks = data.toList().chunked(maxPayload).map { it.toByteArray() }
                            notifyChunksSequentially(
                                server, gattCharacteristic, subscriberDevice,
                                chunks, 0, subscriberAddress
                            )
                            sentCount++
                        }
                    } catch (e: Exception) {
                        Timber.e(e, "$TAG: Error server-notifying $subscriberAddress")
                    }
                }
            }
        }

        if (sentCount > 0) {
            onMessageSent?.invoke(message.messageId, true)
        }

        Timber.i("$TAG: Broadcast message ${message.messageId} to $sentCount peers (client+server)")
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
     * Drain the per-peer write queue after a write completes.
     * Takes the next queued (data, messageId) pair and initiates the write.
     * Called from onCharacteristicWrite after the BLE slot is freed.
     */
    private fun drainPeerWriteQueue(peerAddress: String) {
        val queue = peerWriteQueue[peerAddress] ?: return
        val (data, messageId) = queue.poll() ?: run {
            peerWriteQueue.remove(peerAddress) // cleanup empty queue
            return
        }

        val gatt = connectedGatts[peerAddress] ?: run {
            // Peer disconnected — drop the entire queue
            peerWriteQueue.remove(peerAddress)
            return
        }

        try {
            val service = gatt.getService(MESH_SERVICE_UUID) ?: return
            val characteristic = service.getCharacteristic(MESH_CHARACTERISTIC_UUID) ?: return

            activeWriteMessageId[peerAddress] = messageId

            val mtu = peerMtu.getOrDefault(peerAddress, 23)
            val maxPayload = (mtu - 3).coerceAtLeast(20)

            if (data.size <= maxPayload) {
                characteristic.value = data
                characteristic.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
                if (!gatt.writeCharacteristic(characteristic)) {
                    activeWriteMessageId.remove(peerAddress)
                    Timber.w("$TAG: Failed to drain queued write to $peerAddress")
                } else {
                    Timber.d("$TAG: Drained queued write to $peerAddress (remaining: ${queue.size})")
                }
            } else {
                val chunks = data.toList().chunked(maxPayload).map { it.toByteArray() }
                writeChunksSequentially(gatt, characteristic, chunks, 0, peerAddress, messageId)
                Timber.d("$TAG: Drained queued chunked write to $peerAddress (remaining: ${queue.size})")
            }
        } catch (e: Exception) {
            Timber.e(e, "$TAG: Error draining write queue for $peerAddress")
            activeWriteMessageId.remove(peerAddress)
        }
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
                        // Guard: peer may have disconnected between scheduling and execution
                        try {
                            if (connectedGatts.containsKey(peerAddress)) {
                                writeChunksSequentially(gatt, characteristic, chunks, index + 1, peerAddress, messageId)
                            } else {
                                Timber.w("$TAG: Peer $peerAddress disconnected before chunk ${index + 1}")
                                activeWriteMessageId.remove(peerAddress)
                            }
                        } catch (e: Exception) {
                            Timber.e(e, "$TAG: Error in delayed chunk write to $peerAddress")
                            activeWriteMessageId.remove(peerAddress)
                        }
                    }, 150) // 150ms delay for through-wall reliability (link-layer retry time)
                }
            } else {
                Timber.w("$TAG: Chunk $index/${chunks.size} failed for $peerAddress")
                activeWriteMessageId.remove(peerAddress)
            }
        } catch (e: Exception) {
            Timber.e(e, "$TAG: Error writing chunk $index to $peerAddress")
            activeWriteMessageId.remove(peerAddress)
        }
    }

    /**
     * Send notification chunks sequentially via GATT server.
     * Mirror of writeChunksSequentially() but uses server-push (notifyCharacteristicChanged)
     * instead of client-write (writeCharacteristic).
     *
     * Uses a higher delay (200ms) than client writes because server notifications
     * go through a different buffer path and don't have write confirmation callbacks.
     */
    private fun notifyChunksSequentially(
        server: BluetoothGattServer,
        characteristic: BluetoothGattCharacteristic,
        device: BluetoothDevice,
        chunks: List<ByteArray>,
        index: Int,
        peerAddress: String
    ) {
        if (index >= chunks.size) {
            Timber.d("$TAG: All ${chunks.size} notification chunks sent to $peerAddress")
            return
        }
        if (!notificationSubscribers.containsKey(peerAddress)) {
            Timber.w("$TAG: Subscriber $peerAddress gone during chunked notification")
            return
        }

        try {
            characteristic.value = chunks[index]
            val sent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                server.notifyCharacteristicChanged(
                    device, characteristic, false, chunks[index]
                ) == BluetoothGatt.GATT_SUCCESS
            } else {
                @Suppress("DEPRECATION")
                server.notifyCharacteristicChanged(device, characteristic, false)
            }

            if (sent && index < chunks.size - 1) {
                handler.postDelayed({
                    // Guard: subscriber may have disconnected between scheduling and execution
                    try {
                        if (notificationSubscribers.containsKey(peerAddress)) {
                            notifyChunksSequentially(server, characteristic, device, chunks, index + 1, peerAddress)
                        } else {
                            Timber.w("$TAG: Subscriber $peerAddress gone before notification chunk ${index + 1}")
                        }
                    } catch (e: Exception) {
                        Timber.e(e, "$TAG: Error in delayed notification chunk to $peerAddress")
                    }
                }, 200) // 200ms spacing for server notification chunking
            } else if (!sent) {
                Timber.w("$TAG: Notification chunk $index/${chunks.size} failed for $peerAddress")
            }
        } catch (e: Exception) {
            Timber.e(e, "$TAG: Error notifying chunk $index to $peerAddress")
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

        // Learn this peer's actual mesh device ID from the message.
        // If the message was relayed, relayPath.last() is the device ID
        // of the peer that just sent it to us. If relayPath is empty,
        // the sender IS the original author (originDeviceMac).
        //
        // Previous bug: we always used originDeviceMac, which maps the
        // relay peer's BLE address to the original author's device ID.
        // Example: A creates message, B relays to C → C mapped
        // B's BLE address → A's device ID, corrupting Filter 2.
        val senderDeviceId = message.relayPath.lastOrNull() ?: message.originDeviceMac
        if (senderDeviceId.isNotBlank()) {
            addressToDeviceId[senderAddress] = senderDeviceId
            Timber.d("$TAG: Learned peer identity: $senderAddress → $senderDeviceId")
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
