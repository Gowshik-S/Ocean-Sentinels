import Foundation
import Combine
import os

// MARK: - Mesh Background Service

/// iOS equivalent of Android's MeshForegroundService.
///
/// Architecture difference from Android:
/// ─────────────────────────────────────
/// • Android: Foreground Service (START_STICKY, persistent notification)
/// • iOS: No foreground service concept. BLE continues in background via:
///   1. CoreBluetooth background modes (Info.plist: bluetooth-central, bluetooth-peripheral)
///   2. State restoration (CBCentralManager/CBPeripheralManager restoration IDs)
///   3. BGTaskScheduler for periodic queue processing (when app is suspended)
///
/// This class coordinates:
/// - BleMeshManager (BLE operations)
/// - MeshMessageRepository (DB persistence + API delivery)
/// - NetworkConnectivityManager (internet state monitoring)
/// - DeviceIdentifier (persistent UUID identity)
///
/// Lifecycle: Singleton, started/stopped from UI. CoreBluetooth handles
/// background continuation; BGTasks handle periodic server sync.
@MainActor
final class MeshBackgroundService: ObservableObject {

    static let shared = MeshBackgroundService()

    private let logger = Logger(subsystem: "com.oceansentinels.app", category: "MeshService")

    // MARK: - Constants

    /// Interval to check queue and attempt delivery (30s)
    static let queueCheckIntervalSeconds: TimeInterval = 30
    /// Interval to relay unrelayed messages (15s)
    static let relayIntervalSeconds: TimeInterval = 15
    /// Maximum messages to relay per cycle
    static let relayBatchSize = 25

    // MARK: - Dependencies

    private var meshRepository: MeshMessageRepository?
    private var bleMeshManager: BleMeshManager?
    private var deviceIdentifier: DeviceIdentifier?
    private var networkConnectivityManager: NetworkConnectivityManager?

    // MARK: - State

    @Published private(set) var isServiceRunning = false
    private var cancellables = Set<AnyCancellable>()
    private var queueProcessorTask: Task<Void, Never>?
    private var relayProcessorTask: Task<Void, Never>?

    private init() {}

    // MARK: - Setup

    /// Configure dependencies (called from DependencyContainer)
    func configure(
        meshRepository: MeshMessageRepository,
        bleMeshManager: BleMeshManager,
        deviceIdentifier: DeviceIdentifier,
        networkConnectivityManager: NetworkConnectivityManager
    ) {
        self.meshRepository = meshRepository
        self.bleMeshManager = bleMeshManager
        self.deviceIdentifier = deviceIdentifier
        self.networkConnectivityManager = networkConnectivityManager
    }

    // MARK: - Lifecycle

    /// Start the mesh network
    func startMesh() {
        guard !isServiceRunning else { return }
        guard let bleMeshManager, let deviceIdentifier, let networkConnectivityManager else {
            logger.error("MeshBackgroundService not configured — call configure() first")
            return
        }

        // Get persistent device identity
        let deviceId = deviceIdentifier.getDeviceId()
        let meshId = deviceIdentifier.getMeshIdBytes()

        // Set up callbacks
        setupBleMeshCallbacks()

        // Start BLE mesh
        bleMeshManager.start(deviceId: deviceId, meshId: meshId)

        // Start monitoring network connectivity
        networkConnectivityManager.startMonitoring()

        // Listen for connectivity changes
        networkConnectivityManager.$isOnline
            .removeDuplicates()
            .sink { [weak self] online in
                Task { @MainActor in
                    self?.onConnectivityChanged(online)
                }
            }
            .store(in: &cancellables)

        isServiceRunning = true

        // Start periodic tasks
        startQueueProcessor()
        startRelayProcessor()

        logger.info("Mesh started (iOS — CoreBluetooth background modes active)")
    }

    /// Stop the mesh network
    func stopMesh() {
        guard isServiceRunning else { return }
        isServiceRunning = false

        bleMeshManager?.stop()
        networkConnectivityManager?.stopMonitoring()

        queueProcessorTask?.cancel()
        relayProcessorTask?.cancel()
        cancellables.removeAll()

        logger.info("Mesh stopped")
    }

    // MARK: - BLE Callbacks

    private func setupBleMeshCallbacks() {
        guard let bleMeshManager else { return }

        bleMeshManager.onPeerDiscovered = { [weak self] peer in
            self?.logger.debug("Peer discovered: \(peer.address)")
        }

        bleMeshManager.onPeerConnected = { [weak self] peer in
            guard let self else { return }
            self.logger.info("Peer connected: \(peer.address) (\(peer.phyDescription))")

            // Burst all pending messages to newly connected peer
            // Always relay regardless of internet status
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2)) // Wait for service discovery + MTU
                await self.relayPendingMessages()
            }
        }

        bleMeshManager.onPeerDisconnected = { [weak self] address in
            self?.logger.info("Peer disconnected: \(address)")
        }

        bleMeshManager.onMessageReceived = { [weak self] message, senderAddress in
            Task { @MainActor in
                await self?.handleReceivedMessage(message, senderAddress: senderAddress)
            }
        }

        bleMeshManager.onError = { [weak self] error in
            self?.logger.error("BLE Error: \(error)")
        }
    }

    // MARK: - Message Handling

    /// Handle a message received from the mesh network.
    /// 1. Store in local DB
    /// 2. ALWAYS relay to mesh peers FIRST (burst behavior)
    /// 3. If internet available, ALSO deliver to server
    private func handleReceivedMessage(_ message: MeshMessage, senderAddress: String) async {
        guard let meshRepository, let bleMeshManager, let deviceIdentifier else { return }

        // Dedup: DB existence check
        let isKnown = await meshRepository.isMessageKnown(message.messageId)
        if isKnown {
            logger.debug("Message already known: \(message.messageId), dropping")
            return
        }

        // Save to DB
        await meshRepository.saveReceivedMessage(message)

        // Step 1: ALWAYS relay to mesh peers FIRST
        let deviceId = deviceIdentifier.getDeviceId()
        if let relayed = message.relay(relayDeviceId: deviceId) {
            let sentCount = bleMeshManager.broadcastMessage(
                relayed,
                excludeAddresses: [senderAddress]
            )
            if sentCount > 0 {
                await meshRepository.markRelayedByThisDevice(
                    messageId: message.messageId,
                    deviceId: deviceId,
                    relayPath: relayed.relayPath
                )
                logger.info("Burst-relayed message \(message.messageId) to \(sentCount) peers")
            }
        }

        // Step 2: If internet available, ALSO deliver to server
        if networkConnectivityManager?.isInternetAvailable() == true {
            let delivered = await meshRepository.tryDeliverToServer(message)
            if delivered {
                logger.info("Received message also delivered to server: \(message.messageId)")
            }
        }
    }

    // MARK: - Periodic Tasks

    /// Periodically check queue and deliver via internet
    private func startQueueProcessor() {
        queueProcessorTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                if self?.networkConnectivityManager?.isInternetAvailable() == true {
                    await self?.meshRepository?.processQueue()
                }
                try? await Task.sleep(for: .seconds(Self.queueCheckIntervalSeconds))
            }
        }
    }

    /// Periodically relay pending messages to connected peers
    private func startRelayProcessor() {
        relayProcessorTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                await self?.relayPendingMessages()
                try? await Task.sleep(for: .seconds(Self.relayIntervalSeconds))
            }
        }
    }

    /// Relay pending messages to connected peers
    private func relayPendingMessages() async {
        guard let meshRepository, let bleMeshManager, let deviceIdentifier else { return }
        guard bleMeshManager.getConnectedPeerCount() > 0 else {
            logger.debug("No connected peers, skipping relay attempt")
            return
        }

        let deviceId = deviceIdentifier.getDeviceId()

        // Get both unrelayed AND already-relayed-but-not-delivered messages
        let unrelayed = await meshRepository.getUnrelayedMessages()
        let alreadyRelayed = await meshRepository.getRelayableMessages()

        // Deduplicate and cap at batch size
        var seen = Set<String>()
        let allMessages = (unrelayed + alreadyRelayed).filter { msg in
            seen.insert(msg.messageId).inserted
        }.prefix(Self.relayBatchSize)

        var relayedCount = 0

        for (index, entity) in allMessages.enumerated() {
            // Space out BLE writes to prevent conflicts
            if index > 0 {
                try? await Task.sleep(for: .milliseconds(200))
            }

            let message = entity.toDomain()

            // For already-relayed messages: re-broadcast as-is
            // For new messages: call relay() to add our device ID
            let messageToSend: MeshMessage?
            if entity.hasBeenRelayed {
                messageToSend = message
            } else {
                messageToSend = message.relay(relayDeviceId: deviceId)
            }

            if let msg = messageToSend {
                let sentCount = bleMeshManager.broadcastMessage(msg)
                if sentCount > 0 {
                    if !entity.hasBeenRelayed {
                        let updatedPath = message.relayPath.contains(deviceId)
                            ? message.relayPath
                            : message.relayPath + [deviceId]
                        await meshRepository.markRelayedByThisDevice(
                            messageId: message.messageId,
                            deviceId: deviceId,
                            relayPath: updatedPath
                        )
                    }
                    relayedCount += 1
                }
            }
        }

        if relayedCount > 0 {
            logger.info("Relayed \(relayedCount) messages to peers")
        }
    }

    // MARK: - Network State

    private func onConnectivityChanged(_ online: Bool) {
        if online {
            logger.info("Internet available — flushing queue to server")
            Task { @MainActor in
                await meshRepository?.processQueue()
            }
        } else {
            logger.info("Internet lost — mesh relay mode active")
            Task { @MainActor in
                await relayPendingMessages()
            }
        }
    }

    func hasInternet() -> Bool {
        networkConnectivityManager?.isInternetAvailable() ?? false
    }
}
