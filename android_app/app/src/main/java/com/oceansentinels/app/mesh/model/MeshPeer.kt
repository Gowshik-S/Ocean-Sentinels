package com.oceansentinels.app.mesh.model

/**
 * Represents a discovered BLE mesh peer.
 */
data class MeshPeer(
    /** BLE device address */
    val address: String,
    /** Display name (if available from advertisement) */
    val name: String?,
    /** Signal strength */
    val rssi: Int,
    /** Whether this peer was discovered via Coded PHY (Long Range) */
    val isCodedPhy: Boolean,
    /** Primary PHY used: 1=1M, 2=2M, 3=Coded */
    val primaryPhy: Int,
    /** Secondary PHY used */
    val secondaryPhy: Int,
    /** Last seen timestamp (millis) */
    val lastSeenMillis: Long,
    /** Whether this peer is currently connected */
    val isConnected: Boolean = false,
    /** Whether this peer has the Ocean Sentinels mesh service */
    val hasOceanService: Boolean = false,
    /** Number of messages relayed through this peer */
    val messagesRelayed: Int = 0
) {
    /** Time since last seen in seconds */
    fun secondsSinceLastSeen(): Long {
        return (System.currentTimeMillis() - lastSeenMillis) / 1000
    }

    /** Whether this peer is considered stale (not seen for 180s) */
    val isStale: Boolean
        get() = secondsSinceLastSeen() > STALE_TIMEOUT_SECONDS

    /** PHY description for display */
    val phyDescription: String
        get() = when {
            isCodedPhy -> "Coded PHY (Long Range)"
            primaryPhy == 2 -> "2M PHY (High Speed)"
            else -> "1M PHY (Standard)"
        }

    companion object {
        const val STALE_TIMEOUT_SECONDS = 180L
    }
}

/**
 * Overall mesh network status
 */
data class MeshNetworkStatus(
    /** Whether the mesh service is running */
    val isRunning: Boolean = false,
    /** Whether BLE is available and enabled */
    val isBleAvailable: Boolean = false,
    /** Whether Coded PHY (Long Range) is supported */
    val isCodedPhySupported: Boolean = false,
    /** Whether currently advertising */
    val isAdvertising: Boolean = false,
    /** Whether currently scanning */
    val isScanning: Boolean = false,
    /** Number of connected peers */
    val connectedPeerCount: Int = 0,
    /** Number of discovered (but not connected) peers */
    val discoveredPeerCount: Int = 0,
    /** Total messages in queue */
    val pendingMessageCount: Int = 0,
    /** Total messages successfully delivered */
    val deliveredMessageCount: Int = 0,
    /** Total messages relayed for others */
    val relayedMessageCount: Int = 0,
    /** Whether internet is available */
    val hasInternet: Boolean = false,
    /** Current transport being used */
    val activeTransport: MeshTransport = MeshTransport.LOCAL_QUEUE,
    /** Error message if any */
    val errorMessage: String? = null
)
