import Foundation
import Observation
import Combine

// MARK: - Task Lifecycle Helper

/// Non-actor-isolated bag that cancels its tasks on deinit.
/// Avoids @MainActor isolation issues when cleaning up from deinit.
private final class TaskBag {
    var tasks: [Task<Void, Never>] = []
    deinit { tasks.forEach { $0.cancel() } }
}

// MARK: - MeshViewModel

/// ViewModel for the Mesh Network screen.
/// Manages mesh service state, message queue, and peer list.
@Observable
@MainActor
final class MeshViewModel {

    // MARK: - UI State

    var meshStatus: MeshNetworkStatus = MeshNetworkStatus()
    var isLoading: Bool = false
    var error: String?
    var sendState: MeshSendState = .idle
    var selectedTab: MeshTab = .queue

    // MARK: - Data

    var allMessages: [MeshMessage] = []
    var pendingMessages: [MeshMessage] = []
    var deliveredMessages: [MeshMessage] = []
    var relayedMessages: [MeshMessage] = []

    // MARK: - Dependencies

    private let meshRepository: MeshMessageRepository
    private let bleMeshManager: BleMeshManager

    // Observation tasks — held in a non-actor-isolated bag so deinit cancels safely
    private let taskBag = TaskBag()

    // MARK: - Init

    init(meshRepository: MeshMessageRepository, bleMeshManager: BleMeshManager) {
        self.meshRepository = meshRepository
        self.bleMeshManager = bleMeshManager

        updateMeshCapabilities()
        startObservation()
    }

    // MARK: - Mesh Service Control

    /// Start the mesh background service.
    func startMeshService() {
        MeshBackgroundService.shared.startMesh()
        meshStatus.isRunning = true
    }

    /// Stop the mesh background service.
    func stopMeshService() {
        MeshBackgroundService.shared.stopMesh()
        meshStatus.isRunning = false
    }

    /// Toggle mesh service on/off.
    func toggleMeshService() {
        if meshStatus.isRunning {
            stopMeshService()
        } else {
            startMeshService()
        }
    }

    // MARK: - Report Hazard via Mesh

    /// Submit a hazard report through the mesh network.
    /// Auto-determines transport: Internet → Mesh → Local Queue
    func reportHazard(
        hazardType: HazardType,
        location: String,
        latitude: Double?,
        longitude: Double?,
        description: String,
        urgency: UrgencyLevel,
        contactInfo: String? = nil,
        photoUrl: String? = nil,
        reporterUserId: Int? = nil
    ) {
        Task {
            sendState = .sending

            let result = await meshRepository.createAndSend(
                hazardType: hazardType,
                location: location,
                latitude: latitude,
                longitude: longitude,
                description: description,
                urgency: urgency,
                contactInfo: contactInfo,
                photoUrl: photoUrl,
                reporterUserId: reporterUserId
            )

            switch result {
            case .success(let message):
                let transport: MeshTransport = switch message.status {
                case .delivered: .internet
                case .relayed: .bleCoded
                default: .localQueue
                }

                sendState = .success(
                    messageId: message.messageId,
                    transport: transport,
                    status: message.status
                )
                AppLogger.mesh.info("Report submitted: \(message.messageId) via \(message.status.rawValue)")

            case .failure(let error):
                sendState = .error(error.localizedDescription)
                AppLogger.mesh.error("Failed to submit report: \(error.localizedDescription)")
            }
        }
    }

    /// Reset the send state back to idle.
    func resetSendState() {
        sendState = .idle
    }

    // MARK: - Tab Selection

    func selectTab(_ tab: MeshTab) {
        selectedTab = tab
    }

    // MARK: - Capabilities & Observation

    private func updateMeshCapabilities() {
        meshStatus.isBleAvailable = bleMeshManager.isBleAvailable()
        meshStatus.isCodedPhySupported = bleMeshManager.isCodedPhySupported()
    }

    private func startObservation() {
        // Observe connected peer count via Combine publisher
        let peerTask = Task { [weak self] in
            guard let self else { return }
            for await count in bleMeshManager.$connectedPeerCount.values {
                self.meshStatus.connectedPeerCount = count
            }
        }
        taskBag.tasks.append(peerTask)

        // Observe discovered peer count
        let discoveredTask = Task { [weak self] in
            guard let self else { return }
            for await count in bleMeshManager.$discoveredPeerCount.values {
                self.meshStatus.discoveredPeerCount = count
            }
        }
        taskBag.tasks.append(discoveredTask)

        // Observe running state
        let runningTask = Task { [weak self] in
            guard let self else { return }
            for await running in bleMeshManager.$isRunning.values {
                self.meshStatus.isRunning = running
            }
        }
        taskBag.tasks.append(runningTask)

        // Observe advertising state
        let advertisingTask = Task { [weak self] in
            guard let self else { return }
            for await advertising in bleMeshManager.$isAdvertising.values {
                self.meshStatus.isAdvertising = advertising
            }
        }
        taskBag.tasks.append(advertisingTask)

        // Observe scanning state
        let scanningTask = Task { [weak self] in
            guard let self else { return }
            for await scanning in bleMeshManager.$isScanning.values {
                self.meshStatus.isScanning = scanning
            }
        }
        taskBag.tasks.append(scanningTask)

        // Periodically refresh message lists
        let messageTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.refreshMessages()
                try? await Task.sleep(for: .seconds(5))
            }
        }
        taskBag.tasks.append(messageTask)
    }

    private func refreshMessages() async {
        let all = await meshRepository.getAllMessages()
        let pending = all.filter { $0.status == .pending || $0.status == .sending || $0.status == .failed }
        let delivered = all.filter { $0.status == .delivered }
        let relayed = all.filter { $0.hopCount > 0 }

        await MainActor.run {
            self.allMessages = all
            self.pendingMessages = pending
            self.deliveredMessages = delivered
            self.relayedMessages = relayed

            self.meshStatus.pendingMessageCount = pending.count
            self.meshStatus.deliveredMessageCount = delivered.count
            self.meshStatus.relayedMessageCount = relayed.count
        }
    }

    func clearError() {
        error = nil
    }
}

// MARK: - MeshSendState

/// State for mesh message sending.
enum MeshSendState: Equatable {
    case idle
    case sending
    case success(messageId: String, transport: MeshTransport, status: MeshMessageStatus)
    case error(String)
}

// MARK: - MeshTab

/// Tabs for the mesh screen.
enum MeshTab: String, CaseIterable {
    case all = "All"
    case queue = "Queue"
    case delivered = "Delivered"
    case relayed = "Relayed"
    case peers = "Peers"

    var title: String { rawValue }
}
