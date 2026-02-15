package com.oceansentinels.app.mesh.repository

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import com.oceansentinels.app.data.local.database.dao.MeshMessageDao
import com.oceansentinels.app.data.local.database.entity.MeshMessageEntity
import com.oceansentinels.app.data.remote.api.OceanSentinelsApi
import com.oceansentinels.app.data.remote.dto.CreateIncidentRequestDto
import com.oceansentinels.app.domain.model.*
import com.oceansentinels.app.mesh.ble.BleMeshManager
import com.oceansentinels.app.mesh.ble.DeviceIdentifier
import com.oceansentinels.app.mesh.model.MeshMessage
import com.oceansentinels.app.mesh.model.MeshMessageStatus
import com.oceansentinels.app.mesh.model.MeshTransport
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import timber.log.Timber
import java.time.LocalDateTime
import java.util.concurrent.atomic.AtomicBoolean
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository managing the mesh message lifecycle.
 *
 * Delivery strategy:
 * 1. Internet available → Upload directly to server
 * 2. Internet unavailable → Store in local DB + broadcast via BLE mesh
 * 3. Received from mesh + internet available → Upload to server on their behalf
 * 4. Received from mesh + no internet → Store and relay to more peers
 *
 * Auto-flush: When internet becomes available, all pending messages are sent.
 */
@Singleton
class MeshMessageRepository @Inject constructor(
    private val meshMessageDao: MeshMessageDao,
    private val api: OceanSentinelsApi,
    private val bleMeshManager: BleMeshManager,
    private val deviceIdentifier: DeviceIdentifier,
    @ApplicationContext private val context: Context
) {
    companion object {
        private const val TAG = "MeshMessageRepo"
        /** Maximum messages to keep in local DB (FIFO) */
        const val MAX_LOCAL_MESSAGES = 500
        /** Maximum age for messages before they expire */
        const val MESSAGE_EXPIRY_HOURS = 24L
    }

    /** Mutex to prevent concurrent queue processing from periodic + network callback */
    private val queueMutex = Mutex()

    /** Thread-safe internet availability flag (Issue #11) */
    private val _hasInternet = AtomicBoolean(false)
    fun hasInternetCached(): Boolean = _hasInternet.get()
    fun setInternetAvailable(available: Boolean) { _hasInternet.set(available) }

    // ==================== Create & Queue ====================

    /**
     * Create a new hazard report message.
     * If internet is available, send directly. Otherwise queue for mesh relay.
     */
    suspend fun createAndSend(
        hazardType: HazardType,
        location: String,
        latitude: Double?,
        longitude: Double?,
        description: String,
        urgency: UrgencyLevel,
        contactInfo: String?,
        photoUrl: String?,
        reporterUserId: Int?
    ): Result<MeshMessage> {
        val deviceId = deviceIdentifier.getDeviceId()
        val fingerprint = deviceIdentifier.getDeviceFingerprint()
        val timestamp = System.currentTimeMillis()

        val messageId = MeshMessage.generateMessageId(
            deviceId, timestamp, hazardType.value, latitude, longitude, description
        )

        // Check if already exists (prevent double-submit)
        if (meshMessageDao.exists(messageId)) {
            Timber.w("$TAG: Duplicate message detected: $messageId")
            val existing = meshMessageDao.getByMessageId(messageId)
            return if (existing != null) Result.success(existing.toDomain())
            else Result.failure(Exception("Duplicate message"))
        }

        val message = MeshMessage(
            messageId = messageId,
            originDeviceMac = deviceId,
            originDeviceFingerprint = fingerprint,
            hazardType = hazardType.value,
            location = location,
            latitude = latitude,
            longitude = longitude,
            description = description,
            urgency = urgency.value,
            createdAtMillis = timestamp,
            photoUrl = photoUrl,
            contactInfo = contactInfo,
            reporterUserId = reporterUserId
        )

        // Store in local DB
        val entity = MeshMessageEntity.fromDomain(message, isOwnMessage = true)
        meshMessageDao.insert(entity)
        meshMessageDao.trimToLimit(MAX_LOCAL_MESSAGES)

        // Try direct internet delivery first
        if (isInternetAvailable()) {
            val delivered = tryDeliverToServer(message)
            if (delivered) {
                return Result.success(message.copy(status = MeshMessageStatus.DELIVERED))
            }
        }

        // Internet failed or unavailable → broadcast via BLE mesh
        if (bleMeshManager.isRunning()) {
            val sentCount = bleMeshManager.broadcastMessage(message)
            if (sentCount > 0) {
                meshMessageDao.markRelayed(messageId)
                Timber.i("$TAG: Message broadcast to $sentCount peers via BLE mesh: $messageId")
                return Result.success(message.copy(status = MeshMessageStatus.RELAYED))
            }
        }

        Timber.i("$TAG: Message queued for mesh delivery: $messageId")
        return Result.success(message.copy(status = MeshMessageStatus.PENDING))
    }

    /**
     * Save a message received from the mesh network.
     */
    suspend fun saveReceivedMessage(message: MeshMessage) {
        if (meshMessageDao.exists(message.messageId)) {
            Timber.d("$TAG: Already have message ${message.messageId}")
            return
        }

        val entity = MeshMessageEntity.fromDomain(
            message,
            isOwnMessage = false,
            transport = MeshTransport.BLE_CODED,
            overrideStatus = MeshMessageStatus.RELAYED
        )

        meshMessageDao.insert(entity)
        meshMessageDao.trimToLimit(MAX_LOCAL_MESSAGES)
        Timber.i("$TAG: Saved received message: ${message.messageId}")
    }

    // ==================== Delivery ====================

    /**
     * Try to deliver a message to the server via internet API.
     */
    suspend fun tryDeliverToServer(message: MeshMessage): Boolean {
        try {
            meshMessageDao.markSending(message.messageId)

            val dto = CreateIncidentRequestDto(
                hazardType = message.hazardType,
                location = message.location,
                latitude = message.latitude,
                longitude = message.longitude,
                description = buildServerDescription(message),
                urgency = message.urgency,
                contactInfo = message.contactInfo,
                meshMessageId = message.messageId
            )

            val response = api.createIncident(dto)

            if (response.isSuccessful && response.body() != null) {
                val serverRefId = response.body()!!.referenceId
                val transport = if (message.hopCount > 0) MeshTransport.BLE_CODED else MeshTransport.INTERNET

                meshMessageDao.markDelivered(
                    messageId = message.messageId,
                    deliveredAt = LocalDateTime.now().toString(),
                    transport = transport.value,
                    serverRefId = serverRefId
                )

                Timber.i("$TAG: Message delivered to server: ${message.messageId} → $serverRefId")
                return true
            } else {
                val error = response.errorBody()?.string() ?: "Unknown error"
                Timber.e("$TAG: Server rejected message: $error")
                meshMessageDao.markFailed(message.messageId, LocalDateTime.now().toString())
                return false
            }
        } catch (e: Exception) {
            Timber.e(e, "$TAG: Failed to deliver to server")
            meshMessageDao.markFailed(message.messageId, LocalDateTime.now().toString())
            return false
        }
    }

    /**
     * Build enriched description for server, including mesh relay info.
     */
    private fun buildServerDescription(message: MeshMessage): String {
        return buildString {
            append(message.description)
            if (message.hopCount > 0) {
                append("\n\n--- Mesh Relay Info ---")
                append("\nOriginal device: ${message.originDeviceFingerprint}")
                append("\nHops: ${message.hopCount}")
                append("\nRelay path: ${message.relayPath.joinToString(" → ")}")
                append("\nOriginal timestamp: ${message.createdAtMillis}")
            }
        }
    }

    // ==================== Queue Processing ====================

    /**
     * Process the message queue — attempt to deliver all pending/failed messages to server.
     * Called when internet becomes available or periodically.
     * Protected by Mutex to prevent concurrent processing from periodic + network callback.
     */
    suspend fun processQueue() {
        if (!isInternetAvailable()) return

        queueMutex.withLock {
            val now = LocalDateTime.now().toString()

            // Issue #10: Clean up expired undelivered messages first
            val expired = meshMessageDao.getExpiredMessages(now)
            if (expired.isNotEmpty()) {
                expired.forEach { meshMessageDao.deleteByMessageId(it.messageId) }
                Timber.i("$TAG: Cleaned up ${expired.size} expired messages")
            }

            val pending = meshMessageDao.getPendingMessages(now)
            val relayedForOthers = meshMessageDao.getRelayedUndelivered()

            val allToDeliver = (pending + relayedForOthers).distinctBy { it.messageId }

            Timber.i("$TAG: Processing queue: ${allToDeliver.size} messages")

            allToDeliver.forEach { entity ->
                val message = entity.toDomain()
                tryDeliverToServer(message)
            }

            // Clean up expired delivered messages
            meshMessageDao.deleteExpiredDelivered(now)
        }
    }

    // ==================== Relay ====================

    /**
     * Mark a message as relayed to mesh peers.
     */
    suspend fun markRelayed(messageId: String) {
        meshMessageDao.markRelayed(messageId)
    }

    /**
     * Mark a message as relayed by this device, persisting the updated relay path.
     * Issue #13: Ensures relay path is stored in DB for proper hop tracking.
     */
    suspend fun markRelayedByThisDevice(
        messageId: String,
        deviceId: String,
        relayPath: List<String>
    ) {
        meshMessageDao.markRelayed(messageId)
        meshMessageDao.updateRelayPath(messageId, relayPath.joinToString(","))
        Timber.d("$TAG: Marked relayed by $deviceId, path: $relayPath")
    }

    /**
     * Get messages that need to be relayed to mesh peers.
     */
    suspend fun getUnrelayedMessages(): List<MeshMessageEntity> {
        return meshMessageDao.getUnrelayedMessages()
    }

    /**
     * Check if a message ID is already known (for deduplication).
     */
    suspend fun isMessageKnown(messageId: String): Boolean {
        return meshMessageDao.exists(messageId)
    }

    // ==================== Queries for UI ====================

    /** All messages as flow */
    fun getAllMessages(): Flow<List<MeshMessage>> {
        return meshMessageDao.getAllMessages().map { entities ->
            entities.map { it.toDomain() }
        }
    }

    /** Own pending messages */
    fun getPendingMessages(): Flow<List<MeshMessage>> {
        return meshMessageDao.getPendingMessagesFlow().map { entities ->
            entities.map { it.toDomain() }
        }
    }

    /** Delivered messages */
    fun getDeliveredMessages(): Flow<List<MeshMessage>> {
        return meshMessageDao.getDeliveredMessages().map { entities ->
            entities.map { it.toDomain() }
        }
    }

    /** Own messages */
    fun getOwnMessages(): Flow<List<MeshMessage>> {
        return meshMessageDao.getOwnMessages().map { entities ->
            entities.map { it.toDomain() }
        }
    }

    /** Messages relayed for others */
    fun getRelayedMessages(): Flow<List<MeshMessage>> {
        return meshMessageDao.getRelayedMessages().map { entities ->
            entities.map { it.toDomain() }
        }
    }

    /** Count pending own messages */
    suspend fun countPending(): Int = meshMessageDao.countOwnPending()

    /** Count delivered messages */
    suspend fun countDelivered(): Int = meshMessageDao.countDelivered()

    /** Count messages relayed for others */
    suspend fun countRelayed(): Int = meshMessageDao.countRelayed()

    // ==================== Utilities ====================

    private fun isInternetAvailable(): Boolean {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = cm.activeNetwork ?: return false
        val capabilities = cm.getNetworkCapabilities(network) ?: return false
        val available = capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
        _hasInternet.set(available)
        return available
    }
}
