package com.oceansentinels.app.mesh.service

import android.app.*
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.oceansentinels.app.R
import com.oceansentinels.app.mesh.ble.BleMeshManager
import com.oceansentinels.app.mesh.ble.DeviceIdentifier
import com.oceansentinels.app.mesh.model.MeshMessage
import com.oceansentinels.app.mesh.model.MeshMessageStatus
import com.oceansentinels.app.mesh.model.MeshTransport
import com.oceansentinels.app.mesh.network.NetworkConnectivityManager
import com.oceansentinels.app.mesh.repository.MeshMessageRepository
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import timber.log.Timber
import javax.inject.Inject

/**
 * Foreground Service for BLE Mesh operations.
 * Runs continuously to maintain BLE advertising, scanning, and message relay.
 *
 * Lifecycle: START_STICKY for auto-restart on kill.
 * ForegroundServiceType: connectedDevice + dataSync
 *
 * Architecture comparison with bitchat-android:
 * ─────────────────────────────────────────────
 * • bitchat's BluetoothMeshService (1433 lines) coordinates:
 *   - BluetoothConnectionManager (orchestrator)
 *   - BluetoothGattServerManager (advertising + GATT server)
 *   - BluetoothGattClientManager (scanning + GATT client)
 *   - BluetoothPacketBroadcaster (actor-serialized sending)
 *   - PacketProcessor (per-peer actor for handling)
 *   - PacketRelayManager (adaptive probability relay)
 *   - StoreForwardManager (in-memory offline cache)
 *   - SecurityManager (dedup + signatures + Noise)
 *   All pure-mesh, no internet component.
 *
 * • Our MeshForegroundService coordinates:
 *   - BleMeshManager (combined BLE controller)
 *   - MeshMessageRepository (Room DB persistence + API delivery)
 *   - NetworkConnectivityManager (internet state monitoring)
 *   - DeviceIdentifier (persistent UUID identity)
 *   Hybrid internet+mesh with automatic routing.
 *
 * Key difference: bitchat uses PeerManager for peer lifecycle and
 * StoreForwardManager for caching. We use Room DB for persistence
 * and processQueue() for internet auto-flush — more resilient to
 * process death but heavier on storage I/O.
 *
 * Network monitoring now delegates to the centralized
 * NetworkConnectivityManager singleton (single NetworkCallback
 * registration point for the entire app).
 */
@AndroidEntryPoint
class MeshForegroundService : Service() {

    companion object {
        private const val TAG = "MeshForegroundService"
        const val NOTIFICATION_ID = 9001
        const val CHANNEL_ID = "ocean_mesh_service"
        const val CHANNEL_NAME = "Mesh Network"

        const val ACTION_START = "com.oceansentinels.mesh.START"
        const val ACTION_STOP = "com.oceansentinels.mesh.STOP"
        const val ACTION_FLUSH_QUEUE = "com.oceansentinels.mesh.FLUSH"

        /** Interval to check queue and attempt delivery */
        const val QUEUE_CHECK_INTERVAL_MS = 30_000L
        /** Interval to relay unrelayed messages */
        const val RELAY_INTERVAL_MS = 15_000L

        /**
         * Maximum messages to relay per cycle.
         * Caps the relay loop to prevent unbounded blocking:
         * Without this, 500 queued msgs × 200ms inter-write delay = 100s per cycle.
         * With cap: 25 msgs × 200ms = 5s max, allowing the service to remain responsive.
         */
        const val RELAY_BATCH_SIZE = 25

        private val _isServiceRunning = MutableStateFlow(false)
        val isServiceRunning = _isServiceRunning.asStateFlow()

        fun start(context: Context) {
            val intent = Intent(context, MeshForegroundService::class.java).apply {
                action = ACTION_START
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, MeshForegroundService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }
    }

    @Inject
    lateinit var meshRepository: MeshMessageRepository

    @Inject
    lateinit var bleMeshManager: BleMeshManager

    @Inject
    lateinit var deviceIdentifier: DeviceIdentifier

    @Inject
    lateinit var networkConnectivityManager: NetworkConnectivityManager

    private val serviceScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    /**
     * Connectivity listener reference — stored so we can remove it in onDestroy.
     * Replaces the old local `hasInternet` cache which could become stale
     * between callback fire and coroutine execution.
     */
    private val connectivityListener: (Boolean) -> Unit = { online ->
        onConnectivityChanged(online)
    }

    override fun onCreate() {
        super.onCreate()
        Timber.i("$TAG: Service created")

        // Use centralized NetworkConnectivityManager instead of local callback.
        // This eliminates the duplicate NetworkCallback registration that was
        // previously split between this service and MeshMessageRepository.

        // Register for connectivity change events
        // When internet becomes available → flush queue to server
        // When internet is lost → switch to mesh relay mode
        networkConnectivityManager.addConnectivityListener(connectivityListener)
        networkConnectivityManager.startMonitoring()

        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startMesh()
            ACTION_STOP -> stopMesh()
            ACTION_FLUSH_QUEUE -> flushQueue()
            else -> startMesh()
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        stopMesh()
        serviceScope.cancel()
        networkConnectivityManager.removeConnectivityListener(connectivityListener)
        networkConnectivityManager.stopMonitoring()
        super.onDestroy()
        Timber.i("$TAG: Service destroyed")
    }

    // ==================== Mesh Lifecycle ====================

    private fun startMesh() {
        if (_isServiceRunning.value) return

        val notification = createNotification("Mesh network starting...")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // API 34+: Declare both connectedDevice (BLE mesh) and dataSync (HTTP uploads)
            startForeground(
                NOTIFICATION_ID, notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE or
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
            )
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID, notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        // Get persistent device identity (not MAC — broken since Android 6)
        val deviceId = deviceIdentifier.getDeviceId()
        val meshId = deviceIdentifier.getMeshIdBytes()

        // Set up callbacks
        setupBleMeshCallbacks()

        // Start BLE mesh
        bleMeshManager.start(deviceId, meshId)

        _isServiceRunning.value = true
        updateNotification("Mesh active • Scanning for peers...")

        // Start periodic tasks
        startQueueProcessor()
        startRelayProcessor()

        Timber.i("$TAG: Mesh started (Coded PHY: ${bleMeshManager.isLongRangeSupported()})")
    }

    private fun stopMesh() {
        _isServiceRunning.value = false
        bleMeshManager.stop()
        serviceScope.coroutineContext.cancelChildren()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        Timber.i("$TAG: Mesh stopped")
    }

    private fun setupBleMeshCallbacks() {
        bleMeshManager.onPeerDiscovered = { peer ->
            updateNotification(
                "Mesh active • ${bleMeshManager.getConnectedPeerCount()} connected, " +
                "${bleMeshManager.getDiscoveredPeers().size} discovered"
            )
        }

        bleMeshManager.onPeerConnected = { peer ->
            Timber.i("$TAG: Peer connected: ${peer.address} (${peer.phyDescription})")
            updateNotification(
                "Mesh active • ${bleMeshManager.getConnectedPeerCount()} peers connected"
            )

            // When a new peer connects, burst all pending messages to them.
            // Delay allows GATT service discovery + MTU negotiation to complete
            // before we attempt writes. The reverse client connection (added in
            // gattServerCallback fix) fires its own onPeerConnected which also
            // triggers this, ensuring burst works for both directions.
            //
            // ── FIX: Always relay on peer connect, regardless of internet ──
            // Previous bug: `if (!hasInternet)` guard suppressed relay when this
            // device had internet. Result: Device D (connected to C which has
            // internet) never received relayed messages because C "swallowed"
            // them by uploading to server instead of forwarding to D.
            // Mesh relay must ALWAYS happen — server delivery is a parallel path.
            serviceScope.launch {
                delay(2000) // Wait for service discovery + MTU negotiation
                relayPendingMessages()
            }
        }

        bleMeshManager.onPeerDisconnected = { address ->
            updateNotification(
                "Mesh active • ${bleMeshManager.getConnectedPeerCount()} peers connected"
            )
        }

        bleMeshManager.onMessageReceived = { message, senderBleAddress ->
            serviceScope.launch {
                handleReceivedMessage(message, senderBleAddress)
            }
        }

        bleMeshManager.onError = { error ->
            Timber.e("$TAG: BLE Error: $error")
            updateNotification("Mesh error: $error")
        }
    }

    // ==================== Message Handling ====================

    /**
     * Handle a message received from the mesh network.
     * 1. Store in local DB
     * 2. If we have internet -> upload to server (mesh relay not needed)
     * 3. If no internet -> relay to all available peers, excluding the sender
     *
     * @param message       The received mesh message
     * @param senderBleAddress The BLE MAC of the peer that sent/relayed this
     *                        message to us. Used to exclude them from relay.
     *
     * Line-by-line comparison with bitchat-android:
     * ─────────────────────────────────────────────────────────────────
     * bitchat's MessageHandler.handleReceivedPacket() (MessageHandler.kt ~L340):
     *   1. Checks dedup via seenPackets LRU set
     *   2. If local delivery target → deliver to app layer
     *   3. If relay needed → PacketRelayManager.relayPacket(packet, relayAddress)
     *      relayAddress = BLE MAC of the peer that forwarded the packet
     *   4. PacketRelayManager calls BluetoothPacketBroadcaster.broadcastSinglePacketInternal()
     *      which skips both relayAddress AND the original senderID
     *
     * Our equivalent flow:
     *   1. Dedup via meshRepository.isMessageKnown()
     *   2. Try server delivery if internet available
     *   3. If relay needed → broadcastMessage(relayed, excludeAddresses)
     *      where excludeAddresses = setOf(senderBleAddress)
     *   4. broadcastMessage() applies 3-layer filter:
     *      (a) excludeAddresses check (matches bitchat's relayAddress)
     *      (b) addressToDeviceId mapping (matches bitchat's senderID)
     *      (c) relayPath check (extra safety, no bitchat equivalent)
     */
    private suspend fun handleReceivedMessage(message: MeshMessage, senderBleAddress: String) {
        // ── Deduplication: 3-layer check ──
        //
        // Layer 1: BleMeshManager.processedMessageIds (LRU in-memory set)
        //   → Already handled before this callback fires (handleIncomingData)
        //
        // Layer 2: DB existence check
        //   → If we already have this message in ANY status (PENDING/RELAYED/DELIVERED),
        //     drop silently. This prevents re-processing and infinite relay loops.
        if (meshRepository.isMessageKnown(message.messageId)) {
            Timber.d("$TAG: Message already known: ${message.messageId}, dropping")
            return
        }

        // Layer 3: New message — save to DB
        meshRepository.saveReceivedMessage(message)

        // ── Step 1: ALWAYS relay to mesh peers FIRST (burst behavior) ──
        // This is the critical fix: relay BEFORE server delivery so the message
        // keeps propagating through the mesh immediately. Without this, a device
        // with internet would "swallow" the message (upload to server, return,
        // never forward) — killing the chain for any downstream peers without internet.
        //
        // The message must BURST to all connected peers the moment it arrives.
        val deviceId = deviceIdentifier.getDeviceId()
        val relayed = message.relay(deviceId)
        if (relayed != null) {
            val sentCount = bleMeshManager.broadcastMessage(
                relayed,
                excludeAddresses = setOf(senderBleAddress)
            )
            if (sentCount > 0) {
                meshRepository.markRelayedByThisDevice(
                    message.messageId, deviceId, relayed.relayPath
                )
                Timber.i("$TAG: Burst-relayed message ${message.messageId} to $sentCount peers (excluded sender: $senderBleAddress)")
            } else {
                Timber.d("$TAG: No connected peers to relay ${message.messageId}, queued for later")
            }
        }

        // ── Step 2: If internet available, ALSO deliver to server ──
        // The server deduplicates by mesh_message_id (UNIQUE constraint).
        // This runs AFTER relay so the message isn't held on this device.
        // Always read fresh from NetworkConnectivityManager to avoid stale cache.
        if (networkConnectivityManager.isInternetAvailable()) {
            val delivered = meshRepository.tryDeliverToServer(message)
            if (delivered) {
                Timber.i("$TAG: Received message also delivered to server: ${message.messageId}")
            }
            // If server delivery fails, message stays PENDING/RELAYED in DB
            // and processQueue() will retry when internet is stable.
        }
    }

    /**
     * Process the message queue and try to deliver via internet.
     * Called periodically and when internet becomes available.
     */
    private fun startQueueProcessor() {
        serviceScope.launch {
            while (isActive && _isServiceRunning.value) {
                if (networkConnectivityManager.isInternetAvailable()) {
                    meshRepository.processQueue()
                }
                delay(QUEUE_CHECK_INTERVAL_MS)
            }
        }
    }

    /**
     * Periodically relay unrelayed messages to connected peers.
     * Runs regardless of internet status — even when internet is available,
     * we still relay to mesh peers so all devices in the network receive
     * messages (group-chat behavior). Server upload is handled separately
     * by processQueue().
     */
    private fun startRelayProcessor() {
        serviceScope.launch {
            while (isActive && _isServiceRunning.value) {
                relayPendingMessages()
                delay(RELAY_INTERVAL_MS)
            }
        }
    }

    /**
     * Relay pending messages to connected peers.
     * Sends to ALL available peers that haven't received the message yet.
     * Also re-broadcasts already-relayed messages to newly connected peers.
     *
     * Unlike handleReceivedMessage(), this is called periodically from the
     * relay processor (every RELAY_INTERVAL_MS) and when a new peer connects.
     * There's no specific "sender" to exclude here because these are queued
     * messages, so we rely on broadcastMessage()'s built-in filters:
     *   - addressToDeviceId[peer] == originDeviceMac -> skip author
     *   - relayPath.contains(peerDeviceId) -> skip already-relayed peers
     *
     * This matches bitchat's periodic relay behavior where the relay processor
     * re-broadcasts queued packets without a specific relayAddress exclusion.
     */
    private suspend fun relayPendingMessages() {
        if (bleMeshManager.getConnectedPeerCount() == 0) {
            Timber.d("$TAG: No connected peers, skipping relay attempt")
            return
        }

        // Get both unrelayed AND already-relayed-but-not-delivered messages
        // so we can reach new peers that connected after the first relay
        val unrelayed = meshRepository.getUnrelayedMessages()
        val alreadyRelayed = meshRepository.getRelayableMessages()
        val allMessages = (unrelayed + alreadyRelayed)
            .distinctBy { it.messageId }
            .take(RELAY_BATCH_SIZE) // Cap to prevent unbounded relay cycles

        val deviceId = deviceIdentifier.getDeviceId()
        var relayedCount = 0

        allMessages.forEachIndexed { index, entity ->
            // Space out BLE writes between messages to prevent write conflicts.
            // Android BLE stack allows only one outstanding writeCharacteristic()
            // per GATT client. Without this delay, rapid consecutive writes can
            // silently fail on some OEMs, causing messages to appear "stuck".
            if (index > 0) delay(200)
            val message = entity.toDomain()

            // For messages WE already relayed (has_been_relayed=true),
            // our deviceId is already in the relayPath. Calling
            // message.relay(deviceId) returns null (loop detected),
            // which silently killed all re-broadcasts to new peers.
            //
            // Fix: If we already relayed, broadcast the stored version
            // as-is (relayPath already contains our ID). For new messages,
            // call relay() to add our ID and increment hops.
            val messageToSend = if (entity.hasBeenRelayed) {
                // Already relayed by us — re-broadcast to new peers without
                // modifying relay path. broadcastMessage() skips peers
                // already in the relay chain via its 3-layer filter.
                message
            } else {
                // Not yet relayed by us — add our device ID to relay path
                message.relay(deviceId)
            }

            if (messageToSend != null) {
                val sentCount = bleMeshManager.broadcastMessage(messageToSend)
                if (sentCount > 0) {
                    if (!entity.hasBeenRelayed) {
                        // First successful relay — mark in DB
                        val updatedPath = if (message.relayPath.contains(deviceId)) {
                            message.relayPath
                        } else {
                            message.relayPath + deviceId
                        }
                        meshRepository.markRelayedByThisDevice(
                            message.messageId, deviceId, updatedPath
                        )
                    }
                    relayedCount++
                }
            }
        }

        if (relayedCount > 0) {
            Timber.i("$TAG: Relayed $relayedCount messages to peers")
            updateNotification(
                "Mesh active • ${bleMeshManager.getConnectedPeerCount()} peers, $relayedCount relayed"
            )
        }
    }

    private fun flushQueue() {
        serviceScope.launch {
            // Always read fresh state from centralized manager
            val internetNow = networkConnectivityManager.checkInternetNow()
            if (internetNow) {
                // Internet available -- send to server
                meshRepository.processQueue()
            } else {
                // No internet -- relay to connected mesh peers
                relayPendingMessages()
            }
        }
    }

    // ==================== Network State Handling ====================

    /**
     * Called by NetworkConnectivityManager when connectivity changes.
     *
     * This is the central routing decision point for the service:
     *
     * Internet AVAILABLE (online = true):
     * ───────────────────────────────────
     * → Immediately flush message queue to server via processQueue()
     * → processQueue() uploads ALL pending + relayed-but-undelivered messages
     * → After upload, clears BLE write tracking for those messages
     *
     * This is similar to bitchat's StoreForwardManager.sendCachedMessages()
     * which fires when an offline peer reconnects — but instead of sending
     * to a BLE peer, we upload to the HTTP API.
     *
     * Internet LOST (online = false):
     * ───────────────────────────────
     * → Switch to mesh-relay mode
     * → relayProcessor (every 15s) broadcasts pending messages to BLE peers
     * → All new reports from IncidentViewModel are routed directly to mesh
     *   via forwardToMesh() (no HTTP timeout wait)
     *
     * bitchat-android equivalent: bitchat is ALWAYS in "relay mode" since
     * it has no server. Its PacketRelayManager handles forwarding decisions
     * with adaptive probability based on network size. We always flood
     * because hazard reports are high-priority safety data.
     */
    private fun onConnectivityChanged(online: Boolean) {
        if (online) {
            Timber.i("$TAG: Internet available — flushing queue to server")
            updateNotification("Mesh active • Internet available, syncing queue...")
            // Immediately flush the entire queue: deliver pending and
            // verify already-relayed messages with backend
            serviceScope.launch {
                meshRepository.processQueue()
            }
        } else {
            Timber.i("$TAG: Internet lost — mesh relay mode active")
            updateNotification("Mesh active • Offline, relay mode")
            // Trigger an immediate relay attempt so any pending messages
            // start flowing through the mesh right away (don't wait for
            // the next 15s interval)
            serviceScope.launch {
                relayPendingMessages()
            }
        }
    }

    fun hasInternet(): Boolean = networkConnectivityManager.isInternetAvailable()

    // ==================== BLE Manager Access ====================

    fun getMeshManager(): BleMeshManager = bleMeshManager

    // ==================== Notifications ====================

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Ocean Sentinels BLE Mesh Network Service"
                setShowBadge(false)
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(text: String): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Ocean Sentinels Mesh")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_dialog_info) // TODO: Replace with app icon
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    private fun updateNotification(text: String) {
        val notification = createNotification(text)
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.notify(NOTIFICATION_ID, notification)
    }
}
