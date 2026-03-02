import Foundation
import CoreBluetooth
import Combine
import os

// MARK: - BLE Mesh Manager

/// Core BLE Mesh Manager for Ocean Sentinels (iOS).
///
/// Handles BLE advertising, scanning, connection management, and data transfer
/// using CoreBluetooth. Implements dual-role GATT: peripheral (advertising) +
/// central (scanning/connecting).
///
/// PHY Strategy on iOS:
/// ─────────────────────
/// • iOS has NO public API for Coded PHY advertising (CBAdvertisementData
///   does not support PHY selection). Advertising uses standard 1M PHY.
/// • iOS CAN scan for and connect to Coded PHY peripherals — the system
///   auto-negotiates PHY during connection.
/// • After connection, we request high connection priority via
///   CBConnectPeripheral options for better throughput.
///
/// Architecture (referencing bitchat iOS BLEService.swift):
/// ─────────────────────────────────────────────────────────
/// • Both use CBCentralManager + CBPeripheralManager
/// • Both use state restoration IDs for background mode
/// • bitchat uses fragmenting at the app layer; we use 4-byte length-prefix wire format
/// • bitchat has Noise encryption; we transmit plaintext JSON
/// • Both maintain subscriber/peer tracking for dual-path messaging
final class BleMeshManager: NSObject, ObservableObject {

    // MARK: - Shared Singleton

    static let shared = BleMeshManager()

    // MARK: - Constants

    /// Ocean Sentinels Mesh Service UUID
    static let meshServiceUUID = CBUUID(string: "A1C3E5F7-2B4D-6E8F-9A0B-1C2D3E4F5A6B")
    /// Ocean Sentinels Mesh Characteristic UUID (for data transfer)
    static let meshCharacteristicUUID = CBUUID(string: "B2D4F608-3C5E-7F90-AB1C-2D3E4F5061C7")

    /// State restoration identifiers (required for iOS background BLE)
    private static let centralRestorationID = "com.oceansentinels.ble.central"
    private static let peripheralRestorationID = "com.oceansentinels.ble.peripheral"

    /// Maximum BLE packet size before fragmentation
    static let maxPacketSize = 512
    /// Fragment size for BLE transmission
    static let fragmentSize = 469
    /// Scan restart interval (aligned with relay interval)
    static let scanRestartIntervalSeconds: TimeInterval = 15
    /// Duty-cycle scan ON duration — 8s to catch Coded PHY long preamble
    static let scanDutyOnSeconds: TimeInterval = 8
    /// Duty-cycle scan OFF duration — 2s pause
    static let scanDutyOffSeconds: TimeInterval = 2
    /// Stale peer timeout
    static let peerStaleTimeoutSeconds: TimeInterval = 180
    /// Maximum simultaneous connections
    static let maxConnections = 7
    /// Write confirmation timeout
    static let writeConfirmTimeoutSeconds: TimeInterval = 5
    /// Reconnection attempt interval
    static let reconnectIntervalSeconds: TimeInterval = 10
    /// Buffer stale timeout for incomplete fragment reassembly
    static let bufferStaleTimeoutSeconds: TimeInterval = 10

    private let logger = Logger(subsystem: "com.oceansentinels.app", category: "BleMesh")

    // MARK: - State

    private var centralManager: CBCentralManager?
    private var peripheralManager: CBPeripheralManager?
    private var meshCharacteristic: CBMutableCharacteristic?

    /// Discovered peers by peripheral identifier UUID string
    private var discoveredPeers: [String: MeshPeer] = [:]
    /// Connected peripheral references (client GATT handles)
    private var connectedPeripherals: [String: CBPeripheral] = [:]
    /// Centrals subscribed to our GATT server notifications
    private var subscribedCentrals: [String: CBCentral] = [:]
    /// Pending connection attempts (prevents duplicate connectPeripheral calls)
    private var pendingConnections: Set<String> = []
    /// Timestamps for pending connections — cleanup stuck entries
    private var pendingConnectionTimestamps: [String: Date] = [:]

    /// Maps BLE peripheral UUID → mesh device ID (learned from messages)
    private var addressToDeviceId: [String: String] = [:]
    /// Negotiated ATT MTU per peripheral
    private var peerMtu: [String: Int] = [:]

    /// LRU dedup cache — auto-evicts oldest entries
    private var processedMessageIds = LRUSet<String>(maxSize: 10_000)

    /// Per-device incoming data buffers for fragment reassembly
    private var incomingBuffers: [String: Data] = [:]
    private var bufferTimestamps: [String: Date] = [:]
    private let bufferLock = NSLock()

    /// Per-peer write queue for messages waiting on busy peers
    private var peerWriteQueue: [String: [(data: Data, messageId: String)]] = [:]
    /// Currently active write per peer
    private var activeWriteMessageId: [String: String] = [:]
    /// Tracks chunks remaining for multi-chunk writes per peer
    private var peerChunkedWritePending: [String: Int] = [:]
    /// Write confirmation tracking
    private var pendingWrites: [String: Set<String>] = [:]
    private var confirmedWrites: [String: Set<String>] = [:]

    private var localDeviceId: String = ""
    private var localMeshId: Data = Data(count: 8)

    // MARK: - Published State

    @Published private(set) var isRunning = false
    @Published private(set) var isAdvertising = false
    @Published private(set) var isScanning = false
    @Published private(set) var connectedPeerCount = 0
    @Published private(set) var discoveredPeerCount = 0

    // MARK: - Callbacks

    var onPeerDiscovered: ((MeshPeer) -> Void)?
    var onPeerConnected: ((MeshPeer) -> Void)?
    var onPeerDisconnected: ((String) -> Void)?
    /// Called when a valid mesh message is received from a peer.
    /// Parameters: (message, senderPeripheralUUID)
    var onMessageReceived: ((MeshMessage, String) -> Void)?
    var onMessageSent: ((String, Bool) -> Void)?
    var onError: ((String) -> Void)?

    // MARK: - Timers

    private var scanDutyCycleTimer: Timer?
    private var scanRestartTimer: Timer?
    private var peerCleanupTimer: Timer?
    private var reconnectionTimer: Timer?

    // MARK: - Capability Detection

    /// Check if BLE is available and powered on
    func isBleAvailable() -> Bool {
        centralManager?.state == .poweredOn
    }

    /// Check if Coded PHY is supported (iOS can scan but not advertise Coded PHY)
    /// ⚠️ iOS has no public API to query Coded PHY support.
    /// We assume modern iPhones (≥ iPhone 8, iOS 13+) support it for scanning.
    func isCodedPhySupported() -> Bool {
        if #available(iOS 13.0, *) {
            return true // Modern iPhones support scanning Coded PHY
        }
        return false
    }

    /// iOS cannot advertise with Coded PHY — always returns false
    func isExtendedAdvertisingSupported() -> Bool {
        // ⚠️ ANDROID ONLY — needs iOS equivalent
        // iOS has no LE Extended Advertising API for apps.
        // CBPeripheralManager always uses legacy advertising.
        return false
    }

    /// Full Long Range support check — on iOS, limited to scanning only
    func isLongRangeSupported() -> Bool {
        // iOS can receive Coded PHY but cannot advertise with it
        return false
    }

    // MARK: - Lifecycle

    /// Start the mesh network (advertising + scanning + GATT server)
    func start(deviceId: String, meshId: Data) {
        guard !isRunning else {
            logger.warning("Mesh already running")
            return
        }

        localDeviceId = deviceId
        localMeshId = meshId
        isRunning = true

        logger.info("Starting mesh network (iOS — 1M PHY advertising, Coded PHY scanning supported)")

        // Initialize CoreBluetooth managers with state restoration
        // (required for background BLE on iOS)
        centralManager = CBCentralManager(
            delegate: self,
            queue: DispatchQueue(label: "com.oceansentinels.ble.central", qos: .userInitiated),
            options: [
                CBCentralManagerOptionRestoreIdentifierKey: Self.centralRestorationID,
                CBCentralManagerOptionShowPowerAlertKey: true
            ]
        )

        peripheralManager = CBPeripheralManager(
            delegate: self,
            queue: DispatchQueue(label: "com.oceansentinels.ble.peripheral", qos: .userInitiated),
            options: [
                CBPeripheralManagerOptionRestoreIdentifierKey: Self.peripheralRestorationID
            ]
        )

        startPeerCleanup()
        startReconnectionLoop()
    }

    /// Stop the mesh network
    func stop() {
        guard isRunning else { return }
        isRunning = false

        logger.info("Stopping mesh network")

        stopScanning()
        stopAdvertising()
        disconnectAll()

        // Clear all in-memory state
        incomingBuffers.removeAll()
        bufferTimestamps.removeAll()
        discoveredPeers.removeAll()
        pendingConnections.removeAll()
        pendingConnectionTimestamps.removeAll()
        subscribedCentrals.removeAll()
        peerMtu.removeAll()
        addressToDeviceId.removeAll()
        processedMessageIds.removeAll()
        pendingWrites.removeAll()
        confirmedWrites.removeAll()
        activeWriteMessageId.removeAll()
        peerWriteQueue.removeAll()
        peerChunkedWritePending.removeAll()

        scanDutyCycleTimer?.invalidate()
        scanRestartTimer?.invalidate()
        peerCleanupTimer?.invalidate()
        reconnectionTimer?.invalidate()

        centralManager = nil
        peripheralManager = nil

        updatePeerCounts()
    }

    // MARK: - GATT Server (Peripheral Role)

    private func startGattServer() {
        guard let pm = peripheralManager else { return }

        let characteristic = CBMutableCharacteristic(
            type: Self.meshCharacteristicUUID,
            properties: [.read, .write, .writeWithoutResponse, .notify],
            value: nil,
            permissions: [.readable, .writeable]
        )

        let service = CBMutableService(type: Self.meshServiceUUID, primary: true)
        service.characteristics = [characteristic]

        self.meshCharacteristic = characteristic
        pm.add(service)

        logger.info("GATT server started")
    }

    // MARK: - Advertising (Peripheral Role)

    private func startAdvertising() {
        guard let pm = peripheralManager, pm.state == .poweredOn else { return }


        // iOS advertising constraints:
        // - Cannot use Coded PHY (no API)
        // - Limited advertisement payload (~28 bytes)
        // - Service UUID + local name fit within limit
        // - Service data (meshId) goes in scan response automatically
        let advertisementData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [Self.meshServiceUUID],
            CBAdvertisementDataLocalNameKey: "OceanMesh"
        ]

        pm.startAdvertising(advertisementData)
        isAdvertising = true
        logger.info("Advertising started (1M PHY — iOS cannot advertise Coded PHY)")
    }

    private func stopAdvertising() {
        peripheralManager?.stopAdvertising()
        isAdvertising = false
    }

    // MARK: - Scanning (Central Role)

    private func startScanning() {
        guard let cm = centralManager, cm.state == .poweredOn else { return }

        cm.scanForPeripherals(
            withServices: [Self.meshServiceUUID],
            options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: true
                // iOS auto-negotiates PHY — no manual PHY selection for scanning
            ]
        )

        isScanning = true
        logger.info("Scanning started")

        // Duty-cycle: 8s ON, 2s OFF to prevent iOS background throttling
        scheduleDutyCycle()
    }

    private func stopScanning() {
        centralManager?.stopScan()
        isScanning = false
        scanDutyCycleTimer?.invalidate()
    }

    private func scheduleDutyCycle() {
        scanDutyCycleTimer?.invalidate()
        scanDutyCycleTimer = Timer.scheduledTimer(
            withTimeInterval: Self.scanDutyOnSeconds,
            repeats: false
        ) { [weak self] _ in
            guard let self, self.isRunning else { return }
            self.stopScanning()

            // OFF period, then restart
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.scanDutyOffSeconds) { [weak self] in
                guard let self, self.isRunning else { return }
                self.startScanning()
            }
        }
    }

    // MARK: - Connection Management

    private func connectToPeer(_ peripheral: CBPeripheral) {
        let uuid = peripheral.identifier.uuidString
        guard !connectedPeripherals.keys.contains(uuid) else { return }
        guard connectedPeripherals.count + pendingConnections.count < Self.maxConnections else { return }
        guard pendingConnections.insert(uuid).inserted else {
            logger.debug("Connection already pending for \(uuid)")
            return
        }
        pendingConnectionTimestamps[uuid] = Date()

        centralManager?.connect(peripheral, options: [
            // Request high connection priority for mesh reliability
            CBConnectPeripheralOptionNotifyOnConnectionKey: true,
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true,
            CBConnectPeripheralOptionNotifyOnNotificationKey: true
        ])
    }

    private func disconnectAll() {
        for (_, peripheral) in connectedPeripherals {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        connectedPeripherals.removeAll()
        pendingConnections.removeAll()
        peerMtu.removeAll()
        updatePeerCounts()
    }

    /// Attempt to reconnect to known disconnected peers
    private func attemptReconnections() {
        guard isRunning else { return }
        let now = Date()

        // Cleanup stale pending connections (>15s)
        let staleThreshold: TimeInterval = 15
        let stalePending = pendingConnectionTimestamps.filter { now.timeIntervalSince($0.value) > staleThreshold }
        for (uuid, _) in stalePending {
            pendingConnections.remove(uuid)
            pendingConnectionTimestamps.removeValue(forKey: uuid)
            logger.debug("Cleared stale pending connection for \(uuid)")
        }

        for (_, peer) in discoveredPeers where !connectedPeripherals.keys.contains(peer.address) {
            guard !pendingConnections.contains(peer.address) else { continue }
            guard !peer.isStale else { continue }
            guard connectedPeripherals.count + pendingConnections.count < Self.maxConnections else { break }

            // Retrieve the CBPeripheral from the central manager's known peripherals
            let peripherals = centralManager?.retrievePeripherals(withIdentifiers: [UUID(uuidString: peer.address)].compactMap { $0 }) ?? []
            if let peripheral = peripherals.first {
                logger.debug("Attempting reconnection to \(peer.address)")
                connectToPeer(peripheral)
            }
        }
    }

    // MARK: - Data Transfer

    /// Send a mesh message to all connected peers (flooding broadcast).
    /// Returns the number of peers it was sent to.
    func broadcastMessage(_ message: MeshMessage, excludeAddresses: Set<String> = []) -> Int {
        let data = message.toBytes()
        var sentCount = 0

        pendingWrites[message.messageId] = []
        confirmedWrites[message.messageId] = []

        // Path 1: Client writes to connected peripherals
        for (uuid, peripheral) in connectedPeripherals {
            // Filter 0: Queue for peers with active in-flight write
            if activeWriteMessageId[uuid] != nil {
                var queue = peerWriteQueue[uuid] ?? []
                queue.append((data: data, messageId: message.messageId))
                peerWriteQueue[uuid] = queue
                sentCount += 1
                logger.debug("Peer \(uuid) busy, enqueued message (queue: \(queue.count))")
                continue
            }

            // Filter 1: Skip the immediate relay sender
            if excludeAddresses.contains(uuid) {
                logger.debug("Skipping relay back to sender: \(uuid)")
                continue
            }

            // Filter 2: Skip the original message author
            if let peerDeviceId = addressToDeviceId[uuid],
               peerDeviceId == message.originDeviceMac {
                logger.debug("Skipping broadcast to original author: \(uuid)")
                continue
            }

            // Filter 3: Skip peers already in the relay path
            if let peerDeviceId = addressToDeviceId[uuid],
               message.relayPath.contains(peerDeviceId) {
                logger.debug("Skipping peer already in relay path: \(uuid)")
                continue
            }

            if writeToPeer(peripheral: peripheral, data: data, messageId: message.messageId) {
                sentCount += 1
            }
        }

        // Path 2: Server notifications to subscribed centrals
        if let characteristic = meshCharacteristic, !subscribedCentrals.isEmpty {
            for (centralUUID, central) in subscribedCentrals {
                // Skip centrals already handled via client path
                guard !connectedPeripherals.keys.contains(centralUUID) else { continue }

                // Apply same 3-layer filter
                if excludeAddresses.contains(centralUUID) { continue }
                if let devId = addressToDeviceId[centralUUID],
                   devId == message.originDeviceMac { continue }
                if let devId = addressToDeviceId[centralUUID],
                   message.relayPath.contains(devId) { continue }

                let mtu = peerMtu[centralUUID] ?? 185
                let maxPayload = max(mtu - 3, 20)

                if data.count <= maxPayload {
                    let sent = peripheralManager?.updateValue(
                        data, for: characteristic, onSubscribedCentrals: [central]
                    ) ?? false
                    if sent { sentCount += 1 }
                } else {
                    // Chunked notification
                    let chunks = data.chunked(into: maxPayload)
                    notifyChunksSequentially(
                        characteristic: characteristic,
                        central: central,
                        chunks: chunks,
                        index: 0,
                        centralUUID: centralUUID
                    )
                    sentCount += 1
                }
            }
        }

        if sentCount > 0 {
            onMessageSent?(message.messageId, true)
        }

        logger.info("Broadcast message \(message.messageId) to \(sentCount) peers (client+server)")
        return sentCount
    }

    /// Write data to a specific peripheral
    private func writeToPeer(peripheral: CBPeripheral, data: Data, messageId: String) -> Bool {
        let uuid = peripheral.identifier.uuidString

        guard let service = peripheral.services?.first(where: { $0.uuid == Self.meshServiceUUID }),
              let characteristic = service.characteristics?.first(where: { $0.uuid == Self.meshCharacteristicUUID }) else {
            logger.warning("Service/characteristic not found on \(uuid)")
            return false
        }

        activeWriteMessageId[uuid] = messageId
        pendingWrites[messageId]?.insert(uuid)

        // Get effective MTU payload size
        let mtu = peripheral.maximumWriteValueLength(for: .withResponse)
        peerMtu[uuid] = mtu + 3 // Store full MTU (payload + 3 ATT header)
        let maxPayload = max(mtu, 20)

        if data.count <= maxPayload {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            logger.debug("Sent \(data.count)B to \(uuid)")
            return true
        } else {
            let chunks = data.chunked(into: maxPayload)
            peerChunkedWritePending[uuid] = chunks.count
            writeChunksSequentially(
                peripheral: peripheral,
                characteristic: characteristic,
                chunks: chunks,
                index: 0,
                peerUUID: uuid,
                messageId: messageId
            )
            return true
        }
    }

    /// Write chunks sequentially with delays
    private func writeChunksSequentially(
        peripheral: CBPeripheral,
        characteristic: CBCharacteristic,
        chunks: [Data],
        index: Int,
        peerUUID: String,
        messageId: String
    ) {
        guard index < chunks.count else {
            logger.debug("All \(chunks.count) chunks sent to \(peerUUID)")
            return
        }
        guard connectedPeripherals[peerUUID] != nil else {
            logger.warning("Peer \(peerUUID) disconnected during chunked write")
            peerChunkedWritePending.removeValue(forKey: peerUUID)
            activeWriteMessageId.removeValue(forKey: peerUUID)
            return
        }

        peripheral.writeValue(chunks[index], for: characteristic, type: .withResponse)

        if index < chunks.count - 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                guard let self, self.connectedPeripherals[peerUUID] != nil else { return }
                self.writeChunksSequentially(
                    peripheral: peripheral,
                    characteristic: characteristic,
                    chunks: chunks,
                    index: index + 1,
                    peerUUID: peerUUID,
                    messageId: messageId
                )
            }
        }
    }

    /// Send notification chunks sequentially via GATT server
    private func notifyChunksSequentially(
        characteristic: CBMutableCharacteristic,
        central: CBCentral,
        chunks: [Data],
        index: Int,
        centralUUID: String
    ) {
        guard index < chunks.count else { return }
        guard subscribedCentrals[centralUUID] != nil else { return }

        let sent = peripheralManager?.updateValue(
            chunks[index], for: characteristic, onSubscribedCentrals: [central]
        ) ?? false

        if sent, index < chunks.count - 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.notifyChunksSequentially(
                    characteristic: characteristic,
                    central: central,
                    chunks: chunks,
                    index: index + 1,
                    centralUUID: centralUUID
                )
            }
        }
    }

    /// Send to a specific connected peer
    func sendToPeer(_ message: MeshMessage, peerAddress: String) -> Bool {
        guard let peripheral = connectedPeripherals[peerAddress] else { return false }
        return writeToPeer(peripheral: peripheral, data: message.toBytes(), messageId: message.messageId)
    }

    // MARK: - Incoming Data Handling

    /// Try to reassemble a complete message from accumulated buffer data.
    /// Supports two wire formats: length-prefix (new) and legacy brace-counting (old).
    private func tryReassembleMessage(address: String) -> MeshMessage? {
        guard let accumulated = incomingBuffers[address], !accumulated.isEmpty else { return nil }

        let isLegacyFormat = accumulated[0] == UInt8(ascii: "{")

        if isLegacyFormat {
            guard let json = String(data: accumulated, encoding: .utf8)?.trimmingCharacters(in: .whitespaces) else { return nil }
            if json.hasPrefix("{") && json.hasSuffix("}") {
                if let message = MeshMessage.fromJsonData(Data(json.utf8)) {
                    incomingBuffers.removeValue(forKey: address)
                    bufferTimestamps.removeValue(forKey: address)
                    return message
                }
                let openBraces = json.filter { $0 == "{" }.count
                let closeBraces = json.filter { $0 == "}" }.count
                if openBraces == closeBraces {
                    logger.warning("Malformed legacy JSON from \(address), clearing buffer")
                    incomingBuffers.removeValue(forKey: address)
                    bufferTimestamps.removeValue(forKey: address)
                }
            }
        } else {
            guard accumulated.count >= 4 else { return nil }

            let expectedLen = Int(accumulated[0]) << 24 |
                              Int(accumulated[1]) << 16 |
                              Int(accumulated[2]) << 8 |
                              Int(accumulated[3])

            guard expectedLen > 0, expectedLen <= 1_048_576 else {
                logger.warning("Invalid length prefix (\(expectedLen)) from \(address), clearing buffer")
                incomingBuffers.removeValue(forKey: address)
                bufferTimestamps.removeValue(forKey: address)
                return nil
            }

            if accumulated.count >= 4 + expectedLen {
                let payload = accumulated.subdata(in: 4..<(4 + expectedLen))
                incomingBuffers.removeValue(forKey: address)
                bufferTimestamps.removeValue(forKey: address)
                if let message = MeshMessage.fromJsonData(payload) {
                    return message
                }
                logger.warning("Length-prefix payload invalid JSON from \(address) (len=\(expectedLen))")
            }
        }
        return nil
    }

    /// Handle a fully parsed message from a peer
    private func handleIncomingData(_ message: MeshMessage, senderAddress: String) {
        guard !isDuplicate(message.messageId) else {
            logger.debug("Duplicate message ignored: \(message.messageId)")
            return
        }

        markProcessed(message.messageId)

        // Learn peer identity from message
        let senderDeviceId = message.relayPath.last ?? message.originDeviceMac
        if !senderDeviceId.isEmpty {
            addressToDeviceId[senderAddress] = senderDeviceId
            logger.debug("Learned peer identity: \(senderAddress) → \(senderDeviceId)")
        }

        logger.info("Received message \(message.messageId) from \(senderAddress) (hop: \(message.hopCount))")
        onMessageReceived?(message, senderAddress)
    }

    /// Accumulate incoming data and try reassembly
    private func accumulateAndReassemble(data: Data, fromAddress address: String) {
        bufferLock.lock()
        defer { bufferLock.unlock() }

        let now = Date()

        // Check for stale buffer
        if let lastWrite = bufferTimestamps[address],
           now.timeIntervalSince(lastWrite) > Self.bufferStaleTimeoutSeconds {
            incomingBuffers.removeValue(forKey: address)
        }

        var buffer = incomingBuffers[address] ?? Data()
        buffer.append(data)
        incomingBuffers[address] = buffer
        bufferTimestamps[address] = now

        if let message = tryReassembleMessage(address: address) {
            handleIncomingData(message, senderAddress: address)
        }
    }

    // MARK: - Deduplication

    func isDuplicate(_ messageId: String) -> Bool {
        processedMessageIds.contains(messageId)
    }

    func markProcessed(_ messageId: String) {
        processedMessageIds.insert(messageId)
    }

    // MARK: - Peer Management

    func getDiscoveredPeers() -> [MeshPeer] {
        Array(discoveredPeers.values)
    }

    func getConnectedPeers() -> [MeshPeer] {
        discoveredPeers.values.filter { $0.isConnected }
    }

    func getConnectedPeerCount() -> Int {
        connectedPeripherals.count
    }

    func getConfirmedDeliveryCount(_ messageId: String) -> Int {
        confirmedWrites[messageId]?.count ?? 0
    }

    func isMessageConfirmedByAnyPeer(_ messageId: String) -> Bool {
        (confirmedWrites[messageId]?.count ?? 0) > 0
    }

    func clearMessageTracking(_ messageId: String) {
        pendingWrites.removeValue(forKey: messageId)
        confirmedWrites.removeValue(forKey: messageId)
    }

    func getLocalDeviceId() -> String { localDeviceId }

    // MARK: - Periodic Tasks

    private func startPeerCleanup() {
        peerCleanupTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self, self.isRunning else { return }

            let now = Date()
            let staleAddresses = self.discoveredPeers.filter {
                now.timeIntervalSince1970 * 1000 - Double($0.value.lastSeenMillis) > Self.peerStaleTimeoutSeconds * 1000
            }.map { $0.key }

            for address in staleAddresses {
                self.discoveredPeers.removeValue(forKey: address)
                if let peripheral = self.connectedPeripherals.removeValue(forKey: address) {
                    self.centralManager?.cancelPeripheralConnection(peripheral)
                }
                self.logger.debug("Removed stale peer: \(address)")
            }

            if !staleAddresses.isEmpty {
                self.updatePeerCounts()
            }
        }
    }

    private func startReconnectionLoop() {
        reconnectionTimer = Timer.scheduledTimer(withTimeInterval: Self.reconnectIntervalSeconds, repeats: true) { [weak self] _ in
            self?.attemptReconnections()
        }
    }

    private func updatePeerCounts() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.connectedPeerCount = self.connectedPeripherals.count
            self.discoveredPeerCount = self.discoveredPeers.count
        }
    }

    /// Drain the per-peer write queue after a write completes
    private func drainPeerWriteQueue(_ peerUUID: String) {
        guard var queue = peerWriteQueue[peerUUID], !queue.isEmpty else {
            peerWriteQueue.removeValue(forKey: peerUUID)
            return
        }

        let (data, messageId) = queue.removeFirst()
        peerWriteQueue[peerUUID] = queue.isEmpty ? nil : queue

        guard let peripheral = connectedPeripherals[peerUUID] else {
            peerWriteQueue.removeValue(forKey: peerUUID)
            return
        }

        _ = writeToPeer(peripheral: peripheral, data: data, messageId: messageId)
    }
}

// MARK: - CBCentralManagerDelegate

extension BleMeshManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            logger.info("Central manager powered on")
            if isRunning {
                startScanning()
            }
        case .poweredOff:
            logger.warning("Bluetooth powered off")
            isScanning = false
        case .unauthorized:
            logger.error("Bluetooth unauthorized")
            onError?("Bluetooth permission not granted")
        case .unsupported:
            logger.error("BLE not supported on this device")
            onError?("BLE not supported")
        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        // State restoration for background BLE
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            for peripheral in peripherals {
                peripheral.delegate = self
                let uuid = peripheral.identifier.uuidString
                connectedPeripherals[uuid] = peripheral
                logger.info("Restored peripheral: \(uuid)")
            }
            updatePeerCounts()
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let uuid = peripheral.identifier.uuidString

        // Skip self (not possible on iOS — central can't discover its own peripheral)
        let peer = MeshPeer(
            address: uuid,
            name: peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String,
            rssi: RSSI.intValue,
            isCodedPhy: false, // iOS doesn't expose PHY info in scan results
            primaryPhy: 1,
            lastSeenMillis: Int64(Date().timeIntervalSince1970 * 1000),
            isConnected: connectedPeripherals.keys.contains(uuid),
            hasOceanService: true // Found via service UUID filter
        )

        if let existing = discoveredPeers[uuid] {
            // Update existing peer
            discoveredPeers[uuid] = MeshPeer(
                address: uuid,
                name: peer.name ?? existing.name,
                rssi: RSSI.intValue,
                isCodedPhy: existing.isCodedPhy,
                primaryPhy: existing.primaryPhy,
                lastSeenMillis: Int64(Date().timeIntervalSince1970 * 1000),
                isConnected: existing.isConnected,
                hasOceanService: existing.hasOceanService,
                messagesRelayed: existing.messagesRelayed
            )
            updatePeerCounts()

            // Connect if no client handle
            if !connectedPeripherals.keys.contains(uuid),
               !pendingConnections.contains(uuid),
               connectedPeripherals.count + pendingConnections.count < Self.maxConnections {
                connectToPeer(peripheral)
            }
        } else {
            // Brand new peer
            discoveredPeers[uuid] = peer
            updatePeerCounts()
            onPeerDiscovered?(peer)
            logger.info("New peer discovered: \(uuid) (RSSI: \(RSSI.intValue))")

            if connectedPeripherals.count + pendingConnections.count < Self.maxConnections {
                connectToPeer(peripheral)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let uuid = peripheral.identifier.uuidString
        pendingConnections.remove(uuid)
        pendingConnectionTimestamps.removeValue(forKey: uuid)

        peripheral.delegate = self
        connectedPeripherals[uuid] = peripheral
        updatePeerCounts()

        // Discover services
        peripheral.discoverServices([Self.meshServiceUUID])

        // Update peer state
        if let existing = discoveredPeers[uuid] {
            let updated = MeshPeer(
                address: uuid,
                name: existing.name,
                rssi: existing.rssi,
                isCodedPhy: existing.isCodedPhy,
                primaryPhy: existing.primaryPhy,
                lastSeenMillis: Int64(Date().timeIntervalSince1970 * 1000),
                isConnected: true,
                hasOceanService: existing.hasOceanService,
                messagesRelayed: existing.messagesRelayed
            )
            discoveredPeers[uuid] = updated
            onPeerConnected?(updated)
        }

        logger.info("Connected to \(uuid)")
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        let uuid = peripheral.identifier.uuidString
        pendingConnections.remove(uuid)
        pendingConnectionTimestamps.removeValue(forKey: uuid)
        logger.warning("Failed to connect to \(uuid): \(error?.localizedDescription ?? "unknown")")

        cleanupPeerState(uuid)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        let uuid = peripheral.identifier.uuidString
        pendingConnections.remove(uuid)
        pendingConnectionTimestamps.removeValue(forKey: uuid)

        connectedPeripherals.removeValue(forKey: uuid)
        cleanupPeerState(uuid)

        logger.info("Disconnected from \(uuid)")
        onPeerDisconnected?(uuid)
    }

    private func cleanupPeerState(_ uuid: String) {
        peerMtu.removeValue(forKey: uuid)
        peerWriteQueue.removeValue(forKey: uuid)
        peerChunkedWritePending.removeValue(forKey: uuid)
        activeWriteMessageId.removeValue(forKey: uuid)

        bufferLock.lock()
        incomingBuffers.removeValue(forKey: uuid)
        bufferTimestamps.removeValue(forKey: uuid)
        bufferLock.unlock()

        if let existing = discoveredPeers[uuid] {
            discoveredPeers[uuid] = MeshPeer(
                address: uuid,
                name: existing.name,
                rssi: existing.rssi,
                isCodedPhy: existing.isCodedPhy,
                primaryPhy: existing.primaryPhy,
                lastSeenMillis: existing.lastSeenMillis,
                isConnected: false,
                hasOceanService: existing.hasOceanService,
                messagesRelayed: existing.messagesRelayed
            )
        }
        updatePeerCounts()
    }
}

// MARK: - CBPeripheralDelegate

extension BleMeshManager: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        guard error == nil else {
            logger.warning("Service discovery failed for \(peripheral.identifier.uuidString): \(error!.localizedDescription)")
            return
        }

        if let service = peripheral.services?.first(where: { $0.uuid == Self.meshServiceUUID }) {
            peripheral.discoverCharacteristics([Self.meshCharacteristicUUID], for: service)
            logger.info("Ocean Sentinels service found on \(peripheral.identifier.uuidString)")

            let uuid = peripheral.identifier.uuidString
            if let existing = discoveredPeers[uuid] {
                discoveredPeers[uuid] = MeshPeer(
                    address: uuid,
                    name: existing.name,
                    rssi: existing.rssi,
                    isCodedPhy: existing.isCodedPhy,
                    primaryPhy: existing.primaryPhy,
                    lastSeenMillis: existing.lastSeenMillis,
                    isConnected: existing.isConnected,
                    hasOceanService: true,
                    messagesRelayed: existing.messagesRelayed
                )
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        guard error == nil else { return }

        if let characteristic = service.characteristics?.first(where: { $0.uuid == Self.meshCharacteristicUUID }) {
            // Subscribe to notifications from this peer
            peripheral.setNotifyValue(true, for: characteristic)
            logger.info("Subscribed to notifications on \(peripheral.identifier.uuidString)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        let uuid = peripheral.identifier.uuidString

        // Multi-chunk guard
        if let chunksLeft = peerChunkedWritePending[uuid], chunksLeft > 1 {
            peerChunkedWritePending[uuid] = chunksLeft - 1
            logger.debug("Chunk ACK from \(uuid) (\(chunksLeft - 1) remaining)")
            return
        }
        peerChunkedWritePending.removeValue(forKey: uuid)

        if error == nil {
            if let messageId = activeWriteMessageId.removeValue(forKey: uuid) {
                confirmedWrites[messageId]?.insert(uuid)
                logger.info("Write confirmed for message \(messageId) to \(uuid)")
            }
        } else {
            activeWriteMessageId.removeValue(forKey: uuid)
            logger.warning("Write failed for \(uuid): \(error!.localizedDescription)")
        }

        drainPeerWriteQueue(uuid)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard error == nil,
              characteristic.uuid == Self.meshCharacteristicUUID,
              let value = characteristic.value else { return }

        let uuid = peripheral.identifier.uuidString
        accumulateAndReassemble(data: value, fromAddress: uuid)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let error {
            logger.warning("Notification state update failed for \(peripheral.identifier.uuidString): \(error.localizedDescription)")
        }
    }
}

// MARK: - CBPeripheralManagerDelegate

extension BleMeshManager: CBPeripheralManagerDelegate {

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            logger.info("Peripheral manager powered on")
            if isRunning {
                startGattServer()
                startAdvertising()
            }
        case .poweredOff:
            logger.warning("Peripheral manager powered off")
            isAdvertising = false
        default:
            break
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String: Any]) {
        // State restoration for background advertising
        logger.info("Peripheral manager restored state")
        if let services = dict[CBPeripheralManagerRestoredStateServicesKey] as? [CBMutableService] {
            for service in services {
                if let chars = service.characteristics {
                    meshCharacteristic = chars.first(where: {
                        $0.uuid == Self.meshCharacteristicUUID
                    }) as? CBMutableCharacteristic
                }
            }
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: (any Error)?) {
        if let error {
            logger.error("Failed to add GATT service: \(error.localizedDescription)")
        } else {
            logger.info("GATT service added successfully")
        }
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: (any Error)?) {
        if let error {
            logger.error("Advertising failed: \(error.localizedDescription)")
            isAdvertising = false
        } else {
            logger.info("Advertising started successfully")
            isAdvertising = true
        }
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        let uuid = central.identifier.uuidString
        subscribedCentrals[uuid] = central
        logger.info("Central subscribed: \(uuid) (total: \(self.subscribedCentrals.count))")
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        let uuid = central.identifier.uuidString
        subscribedCentrals.removeValue(forKey: uuid)
        logger.info("Central unsubscribed: \(uuid) (total: \(self.subscribedCentrals.count))")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        if request.characteristic.uuid == Self.meshCharacteristicUUID {
            request.value = localMeshId
            peripheral.respond(to: request, withResult: .success)
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if request.characteristic.uuid == Self.meshCharacteristicUUID,
               let value = request.value {
                let uuid = request.central.identifier.uuidString
                accumulateAndReassemble(data: value, fromAddress: uuid)

                // Mark hasOceanService — this central wrote to our mesh characteristic
                if let existing = discoveredPeers[uuid], !existing.hasOceanService {
                    discoveredPeers[uuid] = MeshPeer(
                        address: uuid,
                        name: existing.name,
                        rssi: existing.rssi,
                        isCodedPhy: existing.isCodedPhy,
                        primaryPhy: existing.primaryPhy,
                        lastSeenMillis: existing.lastSeenMillis,
                        isConnected: existing.isConnected,
                        hasOceanService: true,
                        messagesRelayed: existing.messagesRelayed
                    )
                }
            }
        }

        // Respond to the first request (iOS sends all in batch)
        if let first = requests.first {
            peripheral.respond(to: first, withResult: .success)
        }
    }
}

// MARK: - LRU Set

/// Thread-safe LRU set for message deduplication.
/// Auto-evicts oldest entries when maxSize is exceeded.
final class LRUSet<Element: Hashable> {
    private var set = Set<Element>()
    private var order: [Element] = []
    private let maxSize: Int
    private let lock = NSLock()

    init(maxSize: Int) {
        self.maxSize = maxSize
    }

    func contains(_ element: Element) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return set.contains(element)
    }

    func insert(_ element: Element) {
        lock.lock()
        defer { lock.unlock() }

        if set.insert(element).inserted {
            order.append(element)
            while set.count > maxSize, let oldest = order.first {
                order.removeFirst()
                set.remove(oldest)
            }
        }
    }

    func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        set.removeAll()
        order.removeAll()
    }
}

// MARK: - Data Chunking Extension

extension Data {
    /// Split data into chunks of the given size
    func chunked(into size: Int) -> [Data] {
        stride(from: 0, to: count, by: size).map { offset in
            let end = Swift.min(offset + size, count)
            return subdata(in: offset..<end)
        }
    }
}
