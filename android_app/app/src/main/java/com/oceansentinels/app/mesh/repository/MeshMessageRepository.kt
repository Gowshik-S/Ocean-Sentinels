package com.oceansentinels.app.mesh.repository

import android.content.Context
import com.oceansentinels.app.data.local.database.dao.MeshMessageDao
import com.oceansentinels.app.data.local.database.entity.MeshMessageEntity
import com.oceansentinels.app.data.remote.api.OceanSentinelsApi
import com.oceansentinels.app.data.remote.dto.CreateIncidentRequestDto
import com.oceansentinels.app.data.remote.dto.MeshCheckRequestDto
import com.oceansentinels.app.domain.model.*
import com.oceansentinels.app.mesh.ble.BleMeshManager
import com.oceansentinels.app.mesh.ble.DeviceIdentifier
import com.oceansentinels.app.mesh.model.MeshMessage
import com.oceansentinels.app.mesh.model.MeshMessageStatus
import com.oceansentinels.app.mesh.model.MeshTransport
import com.oceansentinels.app.mesh.network.NetworkConnectivityManager
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import timber.log.Timber
import java.time.LocalDateTime
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository managing the mesh message lifecycle.
 *
 * Delivery strategy (priority order):
 * ────────────────────────────────────
 * 1. Internet available → Upload directly to server via Retrofit API
 * 2. Internet unavailable + BLE peers connected → Broadcast via BLE mesh
 * 3. Internet unavailable + no peers → Store in local Room DB queue
 * 4. Received from mesh + internet available → Upload to server on their behalf
 * 5. Received from mesh + no internet → Store and relay to more peers
 *
 * Auto-flush: When internet becomes available (via NetworkConnectivityManager
 * callback), all pending + relayed messages are uploaded to the server.
 *
 * Architecture comparison with bitchat-android:
 * ─────────────────────────────────────────────
 * • bitchat has NO internet fallback — pure mesh. Messages are sent via
 *   BluetoothPacketBroadcaster (actor pattern) and cached in-memory by
 *   StoreForwardManager (12h timeout, separate favorites queue).
 * • Ocean Sentinels is HYBRID: internet-priority with mesh fallback.
 *   Messages persist in Room DB (500 max, 24h expiry) and auto-flush
 *   to the server when connectivity returns.
 * • bitchat's StoreForwardManager caches per-recipient; our queue is
 *   global (all messages go to server, regardless of recipient).
 * • bitchat uses binary wire format; we use compact JSON for BLE payloads.
 *
 * Key improvement (this update):
 * forwardToMesh() provides a direct mesh-only path that skips the internet
 * check entirely. This is called by IncidentViewModel when it detects
 * no internet BEFORE attempting the API — avoiding a ~10s HTTP timeout.
 */
@Singleton
class MeshMessageRepository @Inject constructor(
    private val meshMessageDao: MeshMessageDao,
    private val api: OceanSentinelsApi,
    private val bleMeshManager: BleMeshManager,
    private val deviceIdentifier: DeviceIdentifier,
    private val networkConnectivityManager: NetworkConnectivityManager,
    @ApplicationContext private val context: Context
) {
    companion object {
        private const val TAG = "MeshMessageRepo"
        /** Maximum messages to keep in local DB (FIFO) */
        const val MAX_LOCAL_MESSAGES = 500
        /** Maximum age for messages before they expire (aligned with MeshMessage.MESSAGE_LIFETIME_MS = 72h) */
        const val MESSAGE_EXPIRY_HOURS = 72L
    }

    /** Mutex to prevent concurrent queue processing from periodic + network callback */
    private val queueMutex = Mutex()

    /**
     * Thread-safe internet availability check.
     * Now delegates to the centralized NetworkConnectivityManager rather than
     * maintaining a separate AtomicBoolean (eliminates Issue #11 race condition).
     *
     * Compare with bitchat-android: bitchat never checks internet — all messages
     * go through mesh unconditionally. Our hybrid approach needs this fast-path
     * check to decide: API upload vs. BLE mesh broadcast.
     */
    fun hasInternetCached(): Boolean = networkConnectivityManager.isInternetAvailable()
    fun setInternetAvailable(available: Boolean) {
        // No-op: state is now managed by NetworkConnectivityManager's callback.
        // Kept for backward compatibility with MeshForegroundService calls.
    }

    // ==================== Create & Queue ====================

    /**
     * Create a new hazard report message.
     * If internet is available, send directly. Otherwise queue for mesh relay.
     *
     * Decision flow (mirrors bitchat-android's broadcastPacket pattern but
     * with an internet-priority layer):
     *
     * ┌─ isInternetAvailable() ──→ tryDeliverToServer()
     * │     ↓ (failed)
     * │  bleMeshManager.isRunning() && peers > 0
     * │     ↓ yes → broadcastMessage() → RELAYED
     * │     ↓ no  → PENDING (queue for later)
     * └─────────────────────────────────────────────────
     *
     * bitchat-android equivalent: BluetoothMeshService.sendMessage() →
     *   signPacketBeforeBroadcast() → connectionManager.broadcastPacket()
     *   (no internet check, always mesh)
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

        // Store in local DB first (like bitchat's StoreForwardManager caching
        // before send — ensures no data loss even if BLE write fails)
        val entity = MeshMessageEntity.fromDomain(message, isOwnMessage = true)
        meshMessageDao.insert(entity)
        meshMessageDao.trimToLimit(MAX_LOCAL_MESSAGES)

        // Try direct internet delivery first
        // Uses NetworkConnectivityManager's cached flag for instant check
        // (no system call overhead — similar to bitchat's
        // BluetoothConnectionTracker.getConnectedDevices() pattern)
        if (isInternetAvailable()) {
            val delivered = tryDeliverToServer(message)
            if (delivered) {
                return Result.success(message.copy(status = MeshMessageStatus.DELIVERED))
            }
            // Internet check passed but server delivery failed (e.g., captive portal,
            // server down) — fall through to mesh, don't return error yet
            Timber.w("$TAG: Internet available but server delivery failed, trying mesh")
        }

        // Internet failed or unavailable -> broadcast via BLE mesh
        // This mirrors bitchat's broadcastPacket() which sends to ALL
        // connected devices (both server and client GATT connections).
        // The key difference: bitchat uses binary protocol + fragmentation
        // (512B threshold, 469B max, 20ms inter-fragment delay), while we
        // use JSON + MTU-aware chunking (50ms inter-chunk delay).
        if (bleMeshManager.isRunning() && bleMeshManager.getConnectedPeerCount() > 0) {
            val sentCount = bleMeshManager.broadcastMessage(message)
            if (sentCount > 0) {
                // Update relay_path to include our device ID so that:
                // 1. Re-broadcast to new peers (relayPendingMessages) can use Filter 3
                // 2. Server description includes our device in the relay chain
                val relayPathWithSelf = listOf(deviceId)
                meshMessageDao.markRelayed(messageId)
                meshMessageDao.updateRelayPath(messageId, relayPathWithSelf.joinToString(","))
                Timber.i("$TAG: Message broadcast to $sentCount peers via BLE mesh: $messageId")
                return Result.success(message.copy(
                    status = MeshMessageStatus.RELAYED,
                    relayPath = relayPathWithSelf
                ))
            }
        }

        // No peers available -- message stays PENDING in local queue.
        // The MeshForegroundService relay processor will automatically
        // retry when peers become available or internet returns.
        //
        // Compare: bitchat's StoreForwardManager does a similar queue-and-retry
        // but only for directed messages to specific peers, not broadcasts.
        // Our approach queues ALL types since they need to reach the server.
        Timber.i("$TAG: Message queued (no peers/internet): $messageId")
        return Result.success(message.copy(status = MeshMessageStatus.PENDING))
    }

    /**
     * Forward a hazard report DIRECTLY to the mesh network, bypassing internet check.
     *
     * Called by IncidentViewModel when it has ALREADY determined that internet
     * is unavailable (via NetworkConnectivityManager.isInternetAvailable()).
     * This avoids the ~10s HTTP timeout that would occur if we tried the API
     * first on a dead connection.
     *
     * Flow: Create message → Store in DB → Broadcast to BLE peers → Queue if no peers
     *
     * This is the Ocean Sentinels equivalent of bitchat-android's direct
     * BluetoothMeshService.sendMessage() path — both skip any server/internet
     * logic and go straight to BLE broadcast:
     *
     * bitchat:  sendMessage() → signPacket() → broadcastPacket() → all peers
     * Ocean:    forwardToMesh() → store DB → broadcastMessage() → all peers
     *
     * The only difference: bitchat uses Ed25519 signatures (SecurityManager)
     * and Noise encryption for private messages. We transmit plaintext JSON
     * and rely on server-side validation after eventual upload.
     */
    suspend fun forwardToMesh(
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

        // Dedup check (same as bitchat's SecurityManager.isDuplicate() which
        // uses a hash-based message ID set with MAX_PROCESSED_MESSAGES limit)
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

        // Step 1: Persist to Room DB (crash-safe, unlike bitchat's in-memory cache)
        val entity = MeshMessageEntity.fromDomain(message, isOwnMessage = true)
        meshMessageDao.insert(entity)
        meshMessageDao.trimToLimit(MAX_LOCAL_MESSAGES)
        Timber.i("$TAG: [MESH-DIRECT] Message stored in local DB: $messageId")

        // Step 2: Broadcast to all connected BLE peers
        // Uses the same broadcastMessage() path as createAndSend() but without
        // attempting internet first. broadcastMessage() internally handles:
        //   - MTU-aware chunking (data > MTU-3 → split into chunks)
        //   - 50ms inter-chunk delay (bitchat uses 20ms for its fragments)
        //   - relay path filtering (skips peers already in relayPath)
        //   - dedup via LRU LinkedHashSet of 10,000 message IDs
        if (bleMeshManager.isRunning() && bleMeshManager.getConnectedPeerCount() > 0) {
            val sentCount = bleMeshManager.broadcastMessage(message)
            if (sentCount > 0) {
                // Update relay_path to include our device ID (same as createAndSend)
                val relayPathWithSelf = listOf(deviceId)
                meshMessageDao.markRelayed(messageId)
                meshMessageDao.updateRelayPath(messageId, relayPathWithSelf.joinToString(","))
                Timber.i("$TAG: [MESH-DIRECT] Broadcast to $sentCount peers: $messageId")
                return Result.success(message.copy(
                    status = MeshMessageStatus.RELAYED,
                    relayPath = relayPathWithSelf,
                    // Note: bitchat would also set transport here. We track transport
                    // separately in MeshMessageEntity for server upload metadata.
                ))
            }
            Timber.w("$TAG: [MESH-DIRECT] broadcastMessage returned 0 despite peers connected")
        }

        // Step 3: No peers available — stays PENDING
        // MeshForegroundService.relayPendingMessages() runs every 15s and will
        // broadcast to any newly connected peer (similar to bitchat's
        // StoreForwardManager.sendCachedMessages(peerID) on peer connect,
        // but we send to ALL new peers, not targeted by recipient).
        //
        // When internet returns, MeshForegroundService.processQueue() uploads
        // to server (no equivalent in bitchat — it's mesh-only forever).
        Timber.i("$TAG: [MESH-DIRECT] Queued locally (no BLE peers): $messageId")
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

        // Save as PENDING — NOT RELAYED.
        // The message was received from the mesh but has not been relayed
        // by THIS device yet. Saving as RELAYED made it invisible to
        // getUnrelayedMessages() (which filters status IN 'pending','sending'),
        // so if the immediate relay attempt failed (no connected peers),
        // the message was stuck and never retried by the periodic relay processor.
        val entity = MeshMessageEntity.fromDomain(
            message,
            isOwnMessage = false,
            transport = MeshTransport.BLE_CODED,
            overrideStatus = MeshMessageStatus.PENDING
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

                // Server returns the same incident for duplicate mesh_message_id.
                // Whether it's a new creation or a duplicate, we mark it DELIVERED
                // so it stops being relayed. This handles the scenario where
                // devices A, B, C, D all get internet and try to upload the
                // same mesh message — the first one creates it, the rest get
                // the existing incident back (with 'duplicate: true') and all
                // correctly mark their local copy as DELIVERED.
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
     * Process the message queue -- attempt to deliver all pending/failed messages to server.
     * Called when internet becomes available or periodically.
     * Protected by Mutex to prevent concurrent processing from periodic + network callback.
     *
     * Also verifies relayed messages: if a message was relayed via mesh and later
     * internet becomes available, this uploads it and clears the queue entry.
     */
    suspend fun processQueue() {
        if (!isInternetAvailable()) return

        queueMutex.withLock {
            val now = LocalDateTime.now().toString()

            // ── Step 0: Reset retry counts for exhausted messages ──
            // When internet just returned after an outage, messages that
            // hit max_retries during the outage deserve fresh attempts.
            // Without this, a 5-minute server outage permanently kills
            // messages (5 retries × 30s = 2.5 min > oops, game over).
            meshMessageDao.resetExhaustedRetries()

            // Clean up expired undelivered messages first
            val expired = meshMessageDao.getExpiredMessages(now)
            if (expired.isNotEmpty()) {
                expired.forEach { meshMessageDao.deleteByMessageId(it.messageId) }
                Timber.i("$TAG: Cleaned up ${expired.size} expired messages")
            }

            val pending = meshMessageDao.getPendingMessages(now)
            val relayedForOthers = meshMessageDao.getRelayedUndelivered()

            val allToDeliver = (pending + relayedForOthers).distinctBy { it.messageId }

            if (allToDeliver.isEmpty()) {
                meshMessageDao.deleteExpiredDelivered(now)
                return@withLock
            }

            Timber.i("$TAG: Processing queue: ${allToDeliver.size} messages to deliver")

            // ── Step 1: Bulk check which messages are already on the server ──
            // Another device in the mesh may have already uploaded them.
            // This avoids N individual HTTP calls that would all return duplicates.
            val alreadyDeliveredIds = bulkCheckDeliveredOnServer(
                allToDeliver.map { it.messageId }
            )

            // Mark server-confirmed messages as DELIVERED without re-uploading
            var skipCount = 0
            alreadyDeliveredIds.forEach { messageId ->
                meshMessageDao.markDelivered(
                    messageId = messageId,
                    deliveredAt = now,
                    transport = MeshTransport.BLE_CODED.value,
                    serverRefId = "mesh-dedup"
                )
                bleMeshManager.clearMessageTracking(messageId)
                skipCount++
            }
            if (skipCount > 0) {
                Timber.i("$TAG: $skipCount messages already delivered by other mesh devices")
            }

            // ── Step 2: Upload remaining undelivered messages ──
            val remainingToDeliver = allToDeliver.filter { it.messageId !in alreadyDeliveredIds }
            var deliveredCount = 0
            remainingToDeliver.forEach { entity ->
                val message = entity.toDomain()
                val delivered = tryDeliverToServer(message)
                if (delivered) {
                    deliveredCount++
                    bleMeshManager.clearMessageTracking(message.messageId)
                }
            }

            if (deliveredCount > 0 || skipCount > 0) {
                Timber.i("$TAG: Queue sync: $deliveredCount new + $skipCount already-delivered = ${deliveredCount + skipCount} total")
            }

            // Clean up expired delivered messages
            meshMessageDao.deleteExpiredDelivered(now)
        }
    }

    /**
     * Bulk check which mesh message IDs are already on the server.
     * Returns the set of IDs that are already delivered.
     * Falls back to empty set on network error (will try individual uploads instead).
     */
    private suspend fun bulkCheckDeliveredOnServer(messageIds: List<String>): Set<String> {
        if (messageIds.isEmpty()) return emptySet()
        return try {
            val response = api.checkMeshMessages(
                MeshCheckRequestDto(messageIds = messageIds)
            )
            if (response.isSuccessful && response.body() != null) {
                response.body()!!.delivered.toSet()
            } else {
                Timber.w("$TAG: Bulk check failed: ${response.code()}")
                emptySet()
            }
        } catch (e: Exception) {
            Timber.w(e, "$TAG: Bulk check network error, will try individual uploads")
            emptySet()
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
     * Get messages already relayed to some peers but eligible for re-broadcast
     * to newly connected peers. broadcastMessage handles dedup via relay path.
     */
    suspend fun getRelayableMessages(): List<MeshMessageEntity> {
        return meshMessageDao.getRelayableMessages()
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

    /**
     * Check internet availability via the centralized NetworkConnectivityManager.
     *
     * Previously this method created its own ConnectivityManager query each time,
     * which was redundant with MeshForegroundService's NetworkCallback.
     * Now uses the singleton's cached AtomicBoolean for O(1) thread-safe reads.
     *
     * Comparison:
     * • bitchat-android: Never checks internet (pure mesh, no server)
     * • bridgefy-alerts: Never checks internet (SDK handles everything)
     * • Ocean Sentinels: Checks via NetworkConnectivityManager.isInternetAvailable()
     *   to decide between API upload and BLE mesh broadcast
     */
    private fun isInternetAvailable(): Boolean {
        return networkConnectivityManager.isInternetAvailable()
    }
}
