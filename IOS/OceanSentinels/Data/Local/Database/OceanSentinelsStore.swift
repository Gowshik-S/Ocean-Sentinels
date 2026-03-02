import Foundation
import SwiftData
import os

/// SwiftData container configuration.
/// Replaces Room OceanSentinelsDatabase.
enum OceanSentinelsStore {
    
    static let schema = Schema([
        IncidentEntity.self,
        MeshMessageEntity.self,
        UserEntity.self
    ])
    
    static func makeContainer() -> ModelContainer {
        let config = ModelConfiguration(
            "OceanSentinels",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}

// MARK: - Database Operations Actor

/// Thread-safe database access layer. Replaces IncidentDao, UserDao, MeshMessageDao.
@ModelActor
actor DatabaseManager {
    
    private let logger = Logger(subsystem: "com.oceansentinels.app", category: "Database")
    
    // MARK: - Incident Operations
    
    func fetchAllIncidents() throws -> [IncidentEntity] {
        let descriptor = FetchDescriptor<IncidentEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchIncident(byId id: Int) throws -> IncidentEntity? {
        let descriptor = FetchDescriptor<IncidentEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    func fetchIncident(byReferenceId refId: String) throws -> IncidentEntity? {
        let descriptor = FetchDescriptor<IncidentEntity>(
            predicate: #Predicate { $0.referenceId == refId }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    func fetchPendingSyncIncidents() throws -> [IncidentEntity] {
        let descriptor = FetchDescriptor<IncidentEntity>(
            predicate: #Predicate { $0.isPendingSync == true }
        )
        return try modelContext.fetch(descriptor)
    }
    
    func insertIncident(_ entity: IncidentEntity) throws {
        modelContext.insert(entity)
        try modelContext.save()
    }
    
    func insertIncidents(_ entities: [IncidentEntity]) throws {
        for entity in entities {
            modelContext.insert(entity)
        }
        try modelContext.save()
    }
    
    func deleteIncident(byId id: Int) throws {
        if let entity = try fetchIncident(byId: id) {
            modelContext.delete(entity)
            try modelContext.save()
        }
    }
    
    func deleteAllIncidents() throws {
        try modelContext.delete(model: IncidentEntity.self)
        try modelContext.save()
    }
    
    func countActiveIncidents() throws -> Int {
        let descriptor = FetchDescriptor<IncidentEntity>(
            predicate: #Predicate {
                $0.status == "PENDING" || $0.status == "VERIFIED" || $0.status == "IN_PROGRESS"
            }
        )
        return try modelContext.fetchCount(descriptor)
    }
    
    // MARK: - User Operations
    
    func fetchAllUsers() throws -> [UserEntity] {
        let descriptor = FetchDescriptor<UserEntity>(
            sortBy: [SortDescriptor(\.id, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchUser(byId id: Int) throws -> UserEntity? {
        let descriptor = FetchDescriptor<UserEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    func insertUser(_ entity: UserEntity) throws {
        modelContext.insert(entity)
        try modelContext.save()
    }
    
    func insertUsers(_ entities: [UserEntity]) throws {
        for entity in entities {
            modelContext.insert(entity)
        }
        try modelContext.save()
    }
    
    func deleteAllUsers() throws {
        try modelContext.delete(model: UserEntity.self)
        try modelContext.save()
    }
    
    // MARK: - Mesh Message Operations
    
    func fetchAllMeshMessages() throws -> [MeshMessageEntity] {
        let descriptor = FetchDescriptor<MeshMessageEntity>(
            sortBy: [SortDescriptor(\.createdAtMillis, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchMeshMessage(byMessageId messageId: String) throws -> MeshMessageEntity? {
        let descriptor = FetchDescriptor<MeshMessageEntity>(
            predicate: #Predicate { $0.messageId == messageId }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    func meshMessageExists(_ messageId: String) throws -> Bool {
        try fetchMeshMessage(byMessageId: messageId) != nil
    }
    
    func fetchPendingMeshMessages() throws -> [MeshMessageEntity] {
        let now = Date()
        let descriptor = FetchDescriptor<MeshMessageEntity>(
            predicate: #Predicate {
                ($0.status == "pending" || $0.status == "failed") &&
                $0.retryCount < $0.maxRetries &&
                $0.expiresAt > now
            },
            sortBy: [SortDescriptor(\.createdAtMillis)]
        )
        var results = try modelContext.fetch(descriptor)
        results.sort { $0.urgencyWeight < $1.urgencyWeight }
        return results
    }
    
    func fetchOwnPendingMeshMessages() throws -> [MeshMessageEntity] {
        let descriptor = FetchDescriptor<MeshMessageEntity>(
            predicate: #Predicate {
                $0.isOwnMessage == true &&
                ($0.status == "pending" || $0.status == "sending" || $0.status == "failed" || $0.status == "relayed")
            },
            sortBy: [SortDescriptor(\.createdAtMillis, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchDeliveredMeshMessages() throws -> [MeshMessageEntity] {
        let descriptor = FetchDescriptor<MeshMessageEntity>(
            predicate: #Predicate { $0.status == "delivered" },
            sortBy: [SortDescriptor(\.deliveredAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchRelayedUndelivered() throws -> [MeshMessageEntity] {
        let descriptor = FetchDescriptor<MeshMessageEntity>(
            predicate: #Predicate {
                ($0.status == "relayed" || ($0.status == "failed" && $0.hasBeenRelayed == true)) &&
                $0.retryCount < $0.maxRetries
            }
        )
        var results = try modelContext.fetch(descriptor)
        results.sort { $0.urgencyWeight < $1.urgencyWeight }
        return results
    }
    
    func fetchUnrelayedMessages() throws -> [MeshMessageEntity] {
        let descriptor = FetchDescriptor<MeshMessageEntity>(
            predicate: #Predicate {
                $0.hasBeenRelayed == false &&
                ($0.status == "pending" || $0.status == "sending")
            },
            sortBy: [SortDescriptor(\.createdAtMillis)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchRelayableMessages() throws -> [MeshMessageEntity] {
        let descriptor = FetchDescriptor<MeshMessageEntity>(
            predicate: #Predicate {
                $0.hasBeenRelayed == true &&
                ($0.status == "relayed" || $0.status == "pending" || $0.status == "sending")
            }
        )
        var results = try modelContext.fetch(descriptor)
        results.sort { $0.urgencyWeight < $1.urgencyWeight }
        return results
    }
    
    func fetchExpiredMeshMessages() throws -> [MeshMessageEntity] {
        let now = Date()
        let descriptor = FetchDescriptor<MeshMessageEntity>(
            predicate: #Predicate {
                $0.expiresAt <= now && $0.status != "delivered"
            }
        )
        return try modelContext.fetch(descriptor)
    }
    
    func insertMeshMessage(_ entity: MeshMessageEntity) throws {
        // Ignore if duplicate (IGNORE strategy)
        if (try? fetchMeshMessage(byMessageId: entity.messageId)) != nil {
            return
        }
        modelContext.insert(entity)
        try modelContext.save()
    }
    
    func markMeshMessageDelivered(
        messageId: String,
        transport: String,
        serverRefId: String?
    ) throws {
        if let entity = try fetchMeshMessage(byMessageId: messageId) {
            entity.status = "delivered"
            entity.deliveredAt = Date()
            entity.transport = transport
            entity.serverReferenceId = serverRefId
            try modelContext.save()
        }
    }
    
    func markMeshMessageSending(messageId: String) throws {
        if let entity = try fetchMeshMessage(byMessageId: messageId) {
            entity.status = "sending"
            try modelContext.save()
        }
    }
    
    func markMeshMessageFailed(messageId: String) throws {
        if let entity = try fetchMeshMessage(byMessageId: messageId) {
            entity.status = "failed"
            entity.retryCount += 1
            entity.lastAttemptAt = Date()
            try modelContext.save()
        }
    }
    
    func markMeshMessageRelayed(messageId: String) throws {
        if let entity = try fetchMeshMessage(byMessageId: messageId) {
            entity.status = "relayed"
            entity.hasBeenRelayed = true
            entity.retryCount = 0
            try modelContext.save()
        }
    }
    
    func updateRelayPath(messageId: String, relayPath: String) throws {
        if let entity = try fetchMeshMessage(byMessageId: messageId) {
            entity.hasBeenRelayed = true
            entity.relayPath = relayPath
            try modelContext.save()
        }
    }
    
    func resetExhaustedRetries() throws {
        let descriptor = FetchDescriptor<MeshMessageEntity>(
            predicate: #Predicate {
                $0.status == "failed" && $0.retryCount >= $0.maxRetries
            }
        )
        let messages = try modelContext.fetch(descriptor)
        for msg in messages {
            msg.retryCount = 0
            msg.status = msg.hasBeenRelayed ? "relayed" : "pending"
        }
        try modelContext.save()
    }
    
    func deleteExpiredDelivered() throws {
        let now = Date()
        let descriptor = FetchDescriptor<MeshMessageEntity>(
            predicate: #Predicate {
                $0.expiresAt <= now && $0.status == "delivered"
            }
        )
        let expired = try modelContext.fetch(descriptor)
        for msg in expired {
            modelContext.delete(msg)
        }
        try modelContext.save()
    }
    
    func deleteExpiredUndelivered() throws {
        let now = Date()
        let descriptor = FetchDescriptor<MeshMessageEntity>(
            predicate: #Predicate {
                $0.expiresAt <= now && $0.status != "delivered"
            }
        )
        let expired = try modelContext.fetch(descriptor)
        for msg in expired {
            modelContext.delete(msg)
        }
        try modelContext.save()
    }
    
    func deleteAllMeshMessages() throws {
        try modelContext.delete(model: MeshMessageEntity.self)
        try modelContext.save()
    }
    
    func getAllMeshMessageIds() throws -> [String] {
        let descriptor = FetchDescriptor<MeshMessageEntity>()
        return try modelContext.fetch(descriptor).map(\.messageId)
    }
    
    func countMeshMessages(byStatus status: String) throws -> Int {
        let descriptor = FetchDescriptor<MeshMessageEntity>(
            predicate: #Predicate { $0.status == status }
        )
        return try modelContext.fetchCount(descriptor)
    }
    
    func countOwnPending() throws -> Int {
        let descriptor = FetchDescriptor<MeshMessageEntity>(
            predicate: #Predicate {
                $0.isOwnMessage == true &&
                ($0.status == "pending" || $0.status == "sending" || $0.status == "failed")
            }
        )
        return try modelContext.fetchCount(descriptor)
    }
    
    func countDelivered() throws -> Int {
        let descriptor = FetchDescriptor<MeshMessageEntity>(
            predicate: #Predicate { $0.status == "delivered" }
        )
        return try modelContext.fetchCount(descriptor)
    }
    
    func countRelayed() throws -> Int {
        let descriptor = FetchDescriptor<MeshMessageEntity>(
            predicate: #Predicate { $0.isOwnMessage == false }
        )
        return try modelContext.fetchCount(descriptor)
    }
    
    /// Keep the most important N messages, delete the rest.
    func trimToLimit(_ limit: Int = 500) throws {
        var all = try fetchAllMeshMessages()
        all.sort {
            if $0.urgencyWeight != $1.urgencyWeight {
                return $0.urgencyWeight < $1.urgencyWeight
            }
            return $0.createdAtMillis > $1.createdAtMillis
        }
        
        if all.count > limit {
            let toDelete = all.suffix(from: limit)
            for msg in toDelete {
                modelContext.delete(msg)
            }
            try modelContext.save()
        }
    }
}
