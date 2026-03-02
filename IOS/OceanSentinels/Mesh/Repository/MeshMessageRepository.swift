import Foundation
import SwiftData
import Combine
import os

// MARK: - Mesh Message Repository

/// Repository managing the mesh message lifecycle.
///
/// Delivery strategy (priority order):
/// ────────────────────────────────────
/// 1. Internet available → Upload directly to server via API
/// 2. Internet unavailable + BLE peers connected → Broadcast via BLE mesh
/// 3. Internet unavailable + no peers → Store in local SwiftData queue
/// 4. Received from mesh + internet available → Upload to server on their behalf
/// 5. Received from mesh + no internet → Store and relay to more peers
///
/// Auto-flush: When internet becomes available (via NetworkConnectivityManager),
/// all pending + relayed messages are uploaded to the server.
///
/// Replaces Android MeshMessageRepository (Room DAO + Retrofit API + Hilt DI).
/// Uses SwiftData (DatabaseManager actor) + URLSession (OceanSentinelsAPI).
actor MeshMessageRepository {

    private let logger = Logger(subsystem: "com.oceansentinels.app", category: "MeshMsgRepo")

    /// Maximum messages to keep in local DB (FIFO)
    static let maxLocalMessages = 500
    /// Maximum age for messages (72h, aligned with MeshMessage.messageLifetimeMs)
    static let messageExpiryHours: Int64 = 72

    // MARK: - Dependencies

    private let databaseManager: DatabaseManager
    private let api: OceanSentinelsAPI
    private let bleMeshManager: BleMeshManager
    private let deviceIdentifier: DeviceIdentifier
    private let networkConnectivityManager: NetworkConnectivityManager

    /// Mutex to prevent concurrent queue processing
    private var isProcessingQueue = false

    init(
        databaseManager: DatabaseManager,
        api: OceanSentinelsAPI,
        bleMeshManager: BleMeshManager,
        deviceIdentifier: DeviceIdentifier,
        networkConnectivityManager: NetworkConnectivityManager
    ) {
        self.databaseManager = databaseManager
        self.api = api
        self.bleMeshManager = bleMeshManager
        self.deviceIdentifier = deviceIdentifier
        self.networkConnectivityManager = networkConnectivityManager
    }

    // MARK: - Create & Queue

    /// Create a new hazard report message.
    /// Internet-first with mesh fallback.
    func createAndSend(
        hazardType: HazardType,
        location: String,
        latitude: Double?,
        longitude: Double?,
        description: String,
        urgency: UrgencyLevel,
        contactInfo: String?,
        photoUrl: String?,
        reporterUserId: Int?
    ) async -> Result<MeshMessage, Error> {
        let deviceId = deviceIdentifier.getDeviceId()
        let fingerprint = deviceIdentifier.getDeviceFingerprint()
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)

        let messageId = MeshMessage.generateMessageId(
            deviceId: deviceId,
            timestampMillis: timestamp,
            hazardType: hazardType.value,
            latitude: latitude,
            longitude: longitude,
            description: description
        )

        // Check if already exists (prevent double-submit)
        if (try? await databaseManager.meshMessageExists(messageId)) == true {
            logger.warning("Duplicate message detected: \(messageId)")
            if let existing = try? await databaseManager.fetchMeshMessage(byMessageId: messageId) {
                return .success(existing.toDomain())
            }
            return .failure(NSError(domain: "MeshRepo", code: -1, userInfo: [NSLocalizedDescriptionKey: "Duplicate message"]))
        }

        let message = MeshMessage(
            messageId: messageId,
            originDeviceMac: deviceId,
            originDeviceFingerprint: fingerprint,
            hazardType: hazardType.value,
            location: location,
            latitude: latitude,
            longitude: longitude,
            description: description,
            urgency: urgency.value,
            createdAtMillis: timestamp,
            photoUrl: photoUrl,
            contactInfo: contactInfo,
            reporterUserId: reporterUserId
        )

        // Store in local DB first (crash-safe)
        let entity = MeshMessageEntity.fromDomain(message, isOwnMessage: true)
        try? await databaseManager.insertMeshMessage(entity)
        try? await databaseManager.trimToLimit(Self.maxLocalMessages)

        // Try direct internet delivery first
        if networkConnectivityManager.isInternetAvailable() {
            let delivered = await tryDeliverToServer(message)
            if delivered {
                return .success(MeshMessage(
                    messageId: message.messageId,
                    originDeviceMac: message.originDeviceMac,
                    originDeviceFingerprint: message.originDeviceFingerprint,
                    hazardType: message.hazardType,
                    location: message.location,
                    latitude: message.latitude,
                    longitude: message.longitude,
                    description: message.description,
                    urgency: message.urgency,
                    createdAtMillis: message.createdAtMillis,
                    status: .delivered,
                    photoUrl: message.photoUrl,
                    contactInfo: message.contactInfo,
                    reporterUserId: message.reporterUserId
                ))
            }
            logger.warning("Internet available but server delivery failed, trying mesh")
        }

        // Internet failed → try BLE mesh
        if await bleMeshManager.isRunning, await bleMeshManager.getConnectedPeerCount() > 0 {
            let sentCount = await bleMeshManager.broadcastMessage(message)
            if sentCount > 0 {
                let relayPathWithSelf = [deviceId]
                try? await databaseManager.markMeshMessageRelayed(messageId: messageId)
                try? await databaseManager.updateRelayPath(messageId: messageId, relayPath: relayPathWithSelf.joined(separator: ","))
                logger.info("Message broadcast to \(sentCount) peers via BLE mesh: \(messageId)")
                return .success(MeshMessage(
                    messageId: message.messageId,
                    originDeviceMac: message.originDeviceMac,
                    originDeviceFingerprint: message.originDeviceFingerprint,
                    hazardType: message.hazardType,
                    location: message.location,
                    latitude: message.latitude,
                    longitude: message.longitude,
                    description: message.description,
                    urgency: message.urgency,
                    createdAtMillis: message.createdAtMillis,
                    status: .relayed,
                    relayPath: relayPathWithSelf,
                    photoUrl: message.photoUrl,
                    contactInfo: message.contactInfo,
                    reporterUserId: message.reporterUserId
                ))
            }
        }

        // No peers — stays PENDING in queue
        logger.info("Message queued (no peers/internet): \(messageId)")
        return .success(message)
    }

    /// Forward a hazard report DIRECTLY to the mesh network, bypassing internet check.
    /// Called when internet is already known to be unavailable.
    func forwardToMesh(
        hazardType: HazardType,
        location: String,
        latitude: Double?,
        longitude: Double?,
        description: String,
        urgency: UrgencyLevel,
        contactInfo: String?,
        photoUrl: String?,
        reporterUserId: Int?
    ) async -> Result<MeshMessage, Error> {
        let deviceId = deviceIdentifier.getDeviceId()
        let fingerprint = deviceIdentifier.getDeviceFingerprint()
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)

        let messageId = MeshMessage.generateMessageId(
            deviceId: deviceId,
            timestampMillis: timestamp,
            hazardType: hazardType.value,
            latitude: latitude,
            longitude: longitude,
            description: description
        )

        if (try? await databaseManager.meshMessageExists(messageId)) == true {
            logger.warning("Duplicate message detected: \(messageId)")
            if let existing = try? await databaseManager.fetchMeshMessage(byMessageId: messageId) {
                return .success(existing.toDomain())
            }
            return .failure(NSError(domain: "MeshRepo", code: -1, userInfo: [NSLocalizedDescriptionKey: "Duplicate message"]))
        }

        let message = MeshMessage(
            messageId: messageId,
            originDeviceMac: deviceId,
            originDeviceFingerprint: fingerprint,
            hazardType: hazardType.value,
            location: location,
            latitude: latitude,
            longitude: longitude,
            description: description,
            urgency: urgency.value,
            createdAtMillis: timestamp,
            photoUrl: photoUrl,
            contactInfo: contactInfo,
            reporterUserId: reporterUserId
        )

        // Store in DB
        let entity = MeshMessageEntity.fromDomain(message, isOwnMessage: true)
        try? await databaseManager.insertMeshMessage(entity)
        try? await databaseManager.trimToLimit(Self.maxLocalMessages)
        logger.info("[MESH-DIRECT] Message stored in local DB: \(messageId)")

        // Broadcast to BLE peers
        if await bleMeshManager.isRunning, await bleMeshManager.getConnectedPeerCount() > 0 {
            let sentCount = await bleMeshManager.broadcastMessage(message)
            if sentCount > 0 {
                let relayPathWithSelf = [deviceId]
                try? await databaseManager.markMeshMessageRelayed(messageId: messageId)
                try? await databaseManager.updateRelayPath(messageId: messageId, relayPath: relayPathWithSelf.joined(separator: ","))
                logger.info("[MESH-DIRECT] Broadcast to \(sentCount) peers: \(messageId)")
                return .success(MeshMessage(
                    messageId: message.messageId,
                    originDeviceMac: message.originDeviceMac,
                    originDeviceFingerprint: message.originDeviceFingerprint,
                    hazardType: message.hazardType,
                    location: message.location,
                    latitude: message.latitude,
                    longitude: message.longitude,
                    description: message.description,
                    urgency: message.urgency,
                    createdAtMillis: message.createdAtMillis,
                    status: .relayed,
                    relayPath: relayPathWithSelf,
                    photoUrl: message.photoUrl,
                    contactInfo: message.contactInfo,
                    reporterUserId: message.reporterUserId
                ))
            }
        }

        logger.info("[MESH-DIRECT] Queued locally (no BLE peers): \(messageId)")
        return .success(message)
    }

    /// Save a message received from the mesh network
    func saveReceivedMessage(_ message: MeshMessage) async {
        guard (try? await databaseManager.meshMessageExists(message.messageId)) != true else {
            logger.debug("Already have message \(message.messageId)")
            return
        }

        let entity = MeshMessageEntity.fromDomain(
            message,
            isOwnMessage: false,
            transport: .bleCoded,
            overrideStatus: .pending
        )

        try? await databaseManager.insertMeshMessage(entity)
        try? await databaseManager.trimToLimit(Self.maxLocalMessages)
        logger.info("Saved received message: \(message.messageId)")
    }

    // MARK: - Delivery

    /// Try to deliver a message to the server via API
    func tryDeliverToServer(_ message: MeshMessage) async -> Bool {
        do {
            try await databaseManager.markMeshMessageSending(messageId: message.messageId)

            let dto = CreateIncidentRequestDTO(
                hazardType: message.hazardType,
                location: message.location,
                latitude: message.latitude,
                longitude: message.longitude,
                description: buildServerDescription(message),
                urgency: message.urgency,
                contactInfo: message.contactInfo,
                meshMessageId: message.messageId
            )

            let response = try await api.createIncident(request: dto)
            let transport: MeshTransport = message.hopCount > 0 ? .bleCoded : .internet

            try await databaseManager.markMeshMessageDelivered(
                messageId: message.messageId,
                transport: transport.value,
                serverRefId: response.referenceId
            )

            logger.info("Message delivered to server: \(message.messageId) → \(response.referenceId)")
            return true
        } catch {
            logger.error("Failed to deliver to server: \(error.localizedDescription)")
            try? await databaseManager.markMeshMessageFailed(
                messageId: message.messageId
            )
            return false
        }
    }

    /// Build enriched description for server with mesh relay info
    private func buildServerDescription(_ message: MeshMessage) -> String {
        var desc = message.description
        if message.hopCount > 0 {
            desc += "\n\n--- Mesh Relay Info ---"
            desc += "\nOriginal device: \(message.originDeviceFingerprint)"
            desc += "\nHops: \(message.hopCount)"
            desc += "\nRelay path: \(message.relayPath.joined(separator: " → "))"
            desc += "\nOriginal timestamp: \(message.createdAtMillis)"
        }
        return desc
    }

    // MARK: - Queue Processing

    /// Process the message queue — deliver all pending/failed messages to server.
    /// Protected by flag to prevent concurrent processing.
    func processQueue() async {
        guard networkConnectivityManager.isInternetAvailable() else { return }
        guard !isProcessingQueue else { return }
        isProcessingQueue = true
        defer { isProcessingQueue = false }

        // Step 0: Reset retry counts for exhausted messages
        try? await databaseManager.resetExhaustedRetries()

        // Clean up expired undelivered messages
        try? await databaseManager.deleteExpiredUndelivered()

        let pending = (try? await databaseManager.fetchPendingMeshMessages()) ?? []
        let relayedForOthers = (try? await databaseManager.fetchRelayedUndelivered()) ?? []

        // Deduplicate
        var seen = Set<String>()
        let allToDeliver = (pending + relayedForOthers).filter { seen.insert($0.messageId).inserted }

        guard !allToDeliver.isEmpty else {
            try? await databaseManager.deleteExpiredDelivered()
            return
        }

        logger.info("Processing queue: \(allToDeliver.count) messages to deliver")

        // Step 1: Bulk check which messages are already on the server
        let alreadyDeliveredIds = await bulkCheckDeliveredOnServer(
            messageIds: allToDeliver.map { $0.messageId }
        )

        // Mark server-confirmed messages as DELIVERED
        var skipCount = 0
        for messageId in alreadyDeliveredIds {
            try? await databaseManager.markMeshMessageDelivered(
                messageId: messageId,
                transport: MeshTransport.bleCoded.value,
                serverRefId: "mesh-dedup"
            )
            await MainActor.run {
                bleMeshManager.clearMessageTracking(messageId)
            }
            skipCount += 1
        }

        if skipCount > 0 {
            logger.info("\(skipCount) messages already delivered by other mesh devices")
        }

        // Step 2: Upload remaining undelivered messages
        let remainingToDeliver = allToDeliver.filter { !alreadyDeliveredIds.contains($0.messageId) }
        var deliveredCount = 0
        for entity in remainingToDeliver {
            let message = entity.toDomain()
            let delivered = await tryDeliverToServer(message)
            if delivered {
                deliveredCount += 1
                await MainActor.run {
                    bleMeshManager.clearMessageTracking(message.messageId)
                }
            }
        }

        if deliveredCount > 0 || skipCount > 0 {
            logger.info("Queue sync: \(deliveredCount) new + \(skipCount) already-delivered")
        }

        try? await databaseManager.deleteExpiredDelivered()
    }

    /// Bulk check which mesh message IDs are already on the server
    private func bulkCheckDeliveredOnServer(messageIds: [String]) async -> Set<String> {
        guard !messageIds.isEmpty else { return [] }
        do {
            let request = MeshCheckRequestDTO(messageIds: messageIds)
            let response = try await api.checkMeshMessages(request: request)
            return Set(response.delivered)
        } catch {
            logger.warning("Bulk check failed: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Relay

    /// Mark a message as relayed by this device
    func markRelayedByThisDevice(messageId: String, deviceId: String, relayPath: [String]) async {
        try? await databaseManager.markMeshMessageRelayed(messageId: messageId)
        try? await databaseManager.updateRelayPath(messageId: messageId, relayPath: relayPath.joined(separator: ","))
        logger.debug("Marked relayed by \(deviceId), path: \(relayPath)")
    }

    /// Get messages that need to be relayed
    func getUnrelayedMessages() async -> [MeshMessageEntity] {
        (try? await databaseManager.fetchUnrelayedMessages()) ?? []
    }

    /// Get messages eligible for re-broadcast to new peers
    func getRelayableMessages() async -> [MeshMessageEntity] {
        (try? await databaseManager.fetchRelayableMessages()) ?? []
    }

    /// Check if a message ID is already known (for deduplication)
    func isMessageKnown(_ messageId: String) async -> Bool {
        (try? await databaseManager.meshMessageExists(messageId)) == true
    }

    // MARK: - Queries for UI

    /// All messages
    func getAllMessages() async -> [MeshMessage] {
        let entities = (try? await databaseManager.fetchAllMeshMessages()) ?? []
        return entities.map { $0.toDomain() }
    }

    /// Own pending messages
    func getOwnPendingMessages() async -> [MeshMessage] {
        let entities = (try? await databaseManager.fetchOwnPendingMeshMessages()) ?? []
        return entities.map { $0.toDomain() }
    }

    /// Count pending own messages
    func countPending() async -> Int {
        (try? await databaseManager.countOwnPending()) ?? 0
    }

    /// Count delivered messages
    func countDelivered() async -> Int {
        (try? await databaseManager.countDelivered()) ?? 0
    }

    /// Count messages relayed for others
    func countRelayed() async -> Int {
        (try? await databaseManager.countRelayed()) ?? 0
    }
}
