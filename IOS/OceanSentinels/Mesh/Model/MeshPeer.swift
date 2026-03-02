import Foundation

// MARK: - Mesh Peer

/// Represents a discovered BLE mesh peer.
struct MeshPeer: Identifiable, Equatable {
    var id: String { address }
    
    /// BLE peripheral identifier (UUID string on iOS)
    let address: String
    /// Display name (if available from advertisement)
    let name: String?
    /// Signal strength
    var rssi: Int
    /// Whether this peer was discovered via Coded PHY (Long Range)
    let isCodedPhy: Bool
    /// Primary PHY used: 1=1M, 2=2M, 3=Coded
    let primaryPhy: Int
    /// Secondary PHY used
    let secondaryPhy: Int
    /// Last seen timestamp (millis)
    var lastSeenMillis: Int64
    /// Whether this peer is currently connected
    var isConnected: Bool
    /// Whether this peer has the Ocean Sentinels mesh service
    var hasOceanService: Bool
    /// Number of messages relayed through this peer
    var messagesRelayed: Int
    
    static let staleTimeoutSeconds: Int64 = 180
    
    init(
        address: String,
        name: String? = nil,
        rssi: Int = -100,
        isCodedPhy: Bool = false,
        primaryPhy: Int = 1,
        secondaryPhy: Int = 0,
        lastSeenMillis: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        isConnected: Bool = false,
        hasOceanService: Bool = false,
        messagesRelayed: Int = 0
    ) {
        self.address = address
        self.name = name
        self.rssi = rssi
        self.isCodedPhy = isCodedPhy
        self.primaryPhy = primaryPhy
        self.secondaryPhy = secondaryPhy
        self.lastSeenMillis = lastSeenMillis
        self.isConnected = isConnected
        self.hasOceanService = hasOceanService
        self.messagesRelayed = messagesRelayed
    }
    
    /// Time since last seen in seconds
    func secondsSinceLastSeen() -> Int64 {
        (Int64(Date().timeIntervalSince1970 * 1000) - lastSeenMillis) / 1000
    }
    
    /// Whether this peer is considered stale (not seen for 180s)
    var isStale: Bool {
        secondsSinceLastSeen() > Self.staleTimeoutSeconds
    }
    
    /// PHY description for display
    var phyDescription: String {
        if isCodedPhy { return "Coded PHY (Long Range)" }
        if primaryPhy == 2 { return "2M PHY (High Speed)" }
        return "1M PHY (Standard)"
    }
}

// MARK: - Mesh Network Status

/// Overall mesh network status.
struct MeshNetworkStatus: Equatable {
    var isRunning: Bool = false
    var isBleAvailable: Bool = false
    /// Whether Coded PHY (Long Range) is supported by this device
    /// Note: iOS has no public API for Coded PHY advertising,
    /// but CAN scan/connect to Coded PHY peripherals.
    var isCodedPhySupported: Bool = false
    var isAdvertising: Bool = false
    var isScanning: Bool = false
    var connectedPeerCount: Int = 0
    var discoveredPeerCount: Int = 0
    var pendingMessageCount: Int = 0
    var deliveredMessageCount: Int = 0
    var relayedMessageCount: Int = 0
    var hasInternet: Bool = false
    var activeTransport: MeshTransport = .localQueue
    var errorMessage: String? = nil
}
