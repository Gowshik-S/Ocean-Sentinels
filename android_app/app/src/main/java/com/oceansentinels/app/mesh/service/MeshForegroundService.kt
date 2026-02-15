package com.oceansentinels.app.mesh.service

import android.app.*
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.oceansentinels.app.R
import com.oceansentinels.app.mesh.ble.BleMeshManager
import com.oceansentinels.app.mesh.ble.DeviceIdentifier
import com.oceansentinels.app.mesh.model.MeshMessage
import com.oceansentinels.app.mesh.model.MeshMessageStatus
import com.oceansentinels.app.mesh.model.MeshTransport
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

    private val serviceScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var connectivityManager: ConnectivityManager? = null
    private var hasInternet = false
    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    override fun onCreate() {
        super.onCreate()
        Timber.i("$TAG: Service created")

        connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager

        // Initialize hasInternet with actual state before async callback
        hasInternet = isInternetAvailable()

        createNotificationChannel()
        registerNetworkCallback()
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
        unregisterNetworkCallback()
        super.onDestroy()
        Timber.i("$TAG: Service destroyed")
    }

    // ==================== Mesh Lifecycle ====================

    private fun startMesh() {
        if (_isServiceRunning.value) return

        val notification = createNotification("Mesh network starting...")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
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

            // When a new peer connects, try to relay unrelayed messages
            serviceScope.launch {
                relayPendingMessages()
            }
        }

        bleMeshManager.onPeerDisconnected = { address ->
            updateNotification(
                "Mesh active • ${bleMeshManager.getConnectedPeerCount()} peers connected"
            )
        }

        bleMeshManager.onMessageReceived = { message ->
            serviceScope.launch {
                handleReceivedMessage(message)
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
     * 2. If we have internet → upload to server
     * 3. If no internet → relay to other peers (recursive mesh)
     */
    private suspend fun handleReceivedMessage(message: MeshMessage) {
        // Check deduplication in DB
        if (meshRepository.isMessageKnown(message.messageId)) {
            Timber.d("$TAG: Message already known: ${message.messageId}")
            return
        }

        // Store original in local DB
        meshRepository.saveReceivedMessage(message)

        // Try to deliver to server first
        if (hasInternet) {
            val delivered = meshRepository.tryDeliverToServer(message)
            if (delivered) {
                Timber.i("$TAG: Relayed message delivered to server: ${message.messageId}")
                return
            }
        }

        // No internet or delivery failed → relay to other peers using persistent device ID
        val deviceId = deviceIdentifier.getDeviceId()
        val relayed = message.relay(deviceId)
        if (relayed != null) {
            val sentCount = bleMeshManager.broadcastMessage(relayed)
            if (sentCount > 0) {
                // Update the relay path in DB to reflect this device relayed it
                meshRepository.markRelayedByThisDevice(
                    message.messageId, deviceId, relayed.relayPath
                )
                Timber.i("$TAG: Relayed message ${message.messageId} to $sentCount peers")
            }
        }
    }

    /**
     * Process the message queue and try to deliver via internet.
     * Called periodically and when internet becomes available.
     */
    private fun startQueueProcessor() {
        serviceScope.launch {
            while (isActive && _isServiceRunning.value) {
                if (hasInternet) {
                    meshRepository.processQueue()
                }
                delay(QUEUE_CHECK_INTERVAL_MS)
            }
        }
    }

    /**
     * Periodically relay unrelayed messages to connected peers.
     */
    private fun startRelayProcessor() {
        serviceScope.launch {
            while (isActive && _isServiceRunning.value) {
                if (!hasInternet) {
                    relayPendingMessages()
                }
                delay(RELAY_INTERVAL_MS)
            }
        }
    }

    private suspend fun relayPendingMessages() {
        val messages = meshRepository.getUnrelayedMessages()
        val deviceId = deviceIdentifier.getDeviceId()
        messages.forEach { entity ->
            val message = entity.toDomain()
            val relayed = message.relay(deviceId)
            if (relayed != null) {
                val sentCount = bleMeshManager.broadcastMessage(relayed)
                if (sentCount > 0) {
                    meshRepository.markRelayedByThisDevice(
                        message.messageId, deviceId, relayed.relayPath
                    )
                }
            }
        }
    }

    private fun flushQueue() {
        serviceScope.launch {
            if (hasInternet) {
                meshRepository.processQueue()
            }
        }
    }

    // ==================== Network Monitoring ====================

    private fun registerNetworkCallback() {
        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .addCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
            .build()

        networkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                Timber.i("$TAG: Internet available")
                hasInternet = true
                // Immediately try to flush the queue
                serviceScope.launch {
                    meshRepository.processQueue()
                }
            }

            override fun onLost(network: Network) {
                Timber.i("$TAG: Internet lost — mesh relay mode active")
                hasInternet = false
            }
        }

        try {
            connectivityManager?.registerNetworkCallback(request, networkCallback!!)
        } catch (e: Exception) {
            Timber.e(e, "$TAG: Error registering network callback")
        }

        // Check current state
        hasInternet = isInternetAvailable()
    }

    private fun unregisterNetworkCallback() {
        networkCallback?.let {
            try {
                connectivityManager?.unregisterNetworkCallback(it)
            } catch (e: Exception) {
                Timber.e(e, "$TAG: Error unregistering network callback")
            }
        }
    }

    private fun isInternetAvailable(): Boolean {
        val network = connectivityManager?.activeNetwork ?: return false
        val capabilities = connectivityManager?.getNetworkCapabilities(network) ?: return false
        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
    }

    fun hasInternet(): Boolean = hasInternet

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
