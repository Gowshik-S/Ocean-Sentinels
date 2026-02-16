package com.oceansentinels.app.mesh.model

import java.security.MessageDigest
import java.time.Instant

/**
 * Represents a mesh message that can be relayed between devices.
 * Each message has a unique deterministic ID to prevent spam/duplicates.
 *
 * Flow: Internet → BLE PHY Coded Mesh → Normal BLE → Local Queue
 *
 * Relay strategy (time-based, NOT hop-limited):
 * ─────────────────────────────────────────────
 * The message has NO hop-count TTL limit. It will keep relaying across
 * devices indefinitely until one of these conditions is met:
 *   1. A device with internet delivers it to the server → DELIVERED
 *   2. The message exceeds MESSAGE_LIFETIME_MS (72 hours) → expired, dropped
 *   3. The relay path reaches MAX_RELAY_PATH (255 devices) → loop safety, dropped
 *
 * Why no hop TTL:
 *   In disaster/ocean scenarios, there may be 10, 20, or even 50+ devices
 *   in a chain before reaching one with internet. A TTL of 7 would silently
 *   kill hazard reports. Instead, we use TIME-based expiry (72h) which allows
 *   the message to survive across any number of hops.
 *
 * Loop prevention is handled by 3 independent mechanisms:
 *   - relayPath: list of device IDs that have relayed (broadcastMessage
 *     skips peers already in the path)
 *   - LRU dedup cache: BleMeshManager.processedMessageIds (10,000 entries)
 *   - DB dedup: MeshRepository.isMessageKnown() checks by messageId
 *
 * Comparison with bitchat-android:
 *   bitchat uses TTL=7 (MESSAGE_TTL_HOPS) because it's a general chat app.
 *   Ocean Sentinels is a safety-critical hazard reporting system where
 *   message loss = potential human harm, so we use time-based expiry instead.
 */
data class MeshMessage(
    /** Unique deterministic ID: SHA-256(deviceMac + timestamp + payload) → first 32 hex chars */
    val messageId: String,
    /** Device MAC address of the original sender */
    val originDeviceMac: String,
    /** Unique device fingerprint (MAC + Android ID combo) */
    val originDeviceFingerprint: String,
    /** Hazard type from the incident report */
    val hazardType: String,
    /** Location description */
    val location: String,
    /** GPS latitude */
    val latitude: Double?,
    /** GPS longitude */
    val longitude: Double?,
    /** Description of the hazard */
    val description: String,
    /** Urgency level: low, medium, high, critical */
    val urgency: String,
    /** Unix timestamp (millis) when the report was created */
    val createdAtMillis: Long,
    /**
     * Hop counter: incremented at each relay hop for diagnostics.
     * NOT used to kill the message — we use time-based expiry instead.
     * Kept in the JSON wire format for monitoring/debugging how many
     * hops a message took before reaching a server.
     */
    val hopCount: Int = 0,
    /** Delivery status */
    val status: MeshMessageStatus = MeshMessageStatus.PENDING,
    /** List of device MACs that have relayed this message (for loop prevention) */
    val relayPath: List<String> = emptyList(),
    /** Photo URL if any */
    val photoUrl: String? = null,
    /** Contact info if any */
    val contactInfo: String? = null,
    /** The reporter's user ID in Ocean Sentinels (if logged in) */
    val reporterUserId: Int? = null,
    /** Reference ID from server (assigned after successful upload) */
    val serverReferenceId: String? = null
) {
    companion object {
        /**
         * Message lifetime in milliseconds (72 hours).
         * After this, the message is considered expired and will not be
         * relayed further. This replaces the old hop-based TTL=7 which
         * was too restrictive for disaster scenarios.
         *
         * 72 hours gives ample time for a hazard report to propagate
         * through a large mesh until reaching an internet-connected device.
         */
        const val MESSAGE_LIFETIME_MS = 72L * 60 * 60 * 1000 // 72 hours

        /**
         * Maximum relay path length (loop safety bound).
         * 255 allows a message to traverse up to 255 unique devices.
         * With S=8 Coded PHY (~400m per hop), that's ~102 km theoretical max.
         * In practice, dedup + relayPath filters prevent loops long before this.
         */
        const val MAX_RELAY_PATH = 255

        /**
         * Generate a deterministic unique message ID from components.
         * This ensures the same report produces the same ID — preventing spam.
         */
        fun generateMessageId(
            deviceMac: String,
            timestampMillis: Long,
            hazardType: String,
            latitude: Double?,
            longitude: Double?,
            description: String
        ): String {
            val payload = buildString {
                append(deviceMac)
                append("|")
                append(timestampMillis)
                append("|")
                append(hazardType)
                append("|")
                append(latitude ?: "null")
                append("|")
                append(longitude ?: "null")
                append("|")
                append(description)
            }

            val digest = MessageDigest.getInstance("SHA-256")
            val hash = digest.digest(payload.toByteArray())
            return hash.take(16).joinToString("") { "%02x".format(it) }
        }

        /**
         * Generate a device fingerprint combining MAC + a secondary unique value.
         */
        fun generateDeviceFingerprint(mac: String, androidId: String): String {
            val payload = "$mac|$androidId"
            val digest = MessageDigest.getInstance("SHA-256")
            val hash = digest.digest(payload.toByteArray())
            return hash.take(8).joinToString("") { "%02x".format(it) }
        }
    }

    /**
     * Check if this message has expired based on creation time.
     * Uses time-based expiry (MESSAGE_LIFETIME_MS = 72 hours) instead of
     * hop-based TTL, because in ocean/disaster scenarios a message may
     * need to traverse dozens of hops before finding internet.
     */
    fun isExpired(): Boolean {
        return (System.currentTimeMillis() - createdAtMillis) > MESSAGE_LIFETIME_MS
    }

    /**
     * Create a relayed copy with updated path and incremented hop count.
     *
     * Returns null if:
     *   - Message has expired (>72 hours old) — time-based safety bound
     *   - This device already relayed (loop detected via relayPath)
     *   - Relay path reached MAX_RELAY_PATH (255) — hard loop ceiling
     *
     * Does NOT check hop-based TTL. The message will keep relaying until
     * it reaches a server or expires by time. This is critical for
     * disaster/ocean mesh where the chain of offline devices can be
     * arbitrarily long.
     *
     * Comparison with bitchat-android:
     *   bitchat's PacketRelayManager.handlePacketRelay():
     *     if (packet.ttl == 0) return   ← hop-based kill
     *     relayPacket = packet.copy(ttl = ttl - 1)
     *
     *   Ocean Sentinels (this method):
     *     if (isExpired()) return null   ← time-based kill (72h)
     *     copy(hopCount = hopCount + 1)  ← count hops for diagnostics only
     */
    fun relay(relayDeviceMac: String): MeshMessage? {
        if (isExpired()) return null // Time-based expiry (72 hours)
        if (relayPath.contains(relayDeviceMac)) return null // Loop detected
        if (relayPath.size >= MAX_RELAY_PATH) return null // Hard upper bound

        return copy(
            hopCount = hopCount + 1,
            relayPath = relayPath + relayDeviceMac
        )
    }

    /** Serialize to a compact byte array for BLE transmission */
    fun toBytes(): ByteArray {
        val json = toJson()
        return json.toByteArray(Charsets.UTF_8)
    }

    /** Serialize to JSON string */
    fun toJson(): String {
        return buildString {
            append("{")
            append("\"id\":\"$messageId\",")
            append("\"mac\":\"$originDeviceMac\",")
            append("\"fp\":\"$originDeviceFingerprint\",")
            append("\"ht\":\"$hazardType\",")
            append("\"loc\":\"$location\",")
            latitude?.let { append("\"lat\":$it,") }
            longitude?.let { append("\"lng\":$it,") }
            append("\"desc\":\"${description.replace("\"", "\\\"")}\",")
            append("\"urg\":\"$urgency\",")
            append("\"ts\":$createdAtMillis,")
            append("\"hops\":$hopCount,")
            append("\"path\":[${relayPath.joinToString(",") { "\"$it\"" }}]")
            photoUrl?.let { append(",\"photo\":\"$it\"") }
            contactInfo?.let { append(",\"contact\":\"${it.replace("\"", "\\\"")}\"") }
            reporterUserId?.let { append(",\"uid\":$it") }
            append("}")
        }
    }
}

/**
 * Delivery status of a mesh message
 */
enum class MeshMessageStatus(val value: String) {
    /** Waiting in local queue, not yet sent */
    PENDING("pending"),
    /** Currently being sent via mesh */
    SENDING("sending"),
    /** Relayed to at least one peer */
    RELAYED("relayed"),
    /** Successfully delivered to server (via internet) */
    DELIVERED("delivered"),
    /** Failed to deliver after all attempts */
    FAILED("failed");

    companion object {
        fun fromValue(value: String): MeshMessageStatus {
            return entries.find { it.value == value } ?: PENDING
        }
    }
}

/**
 * Transport method used for delivery
 */
enum class MeshTransport(val value: String) {
    /** Direct internet upload */
    INTERNET("internet"),
    /** BLE PHY Coded (Long Range) mesh */
    BLE_CODED("ble_coded"),
    /** Standard BLE 1M PHY */
    BLE_STANDARD("ble_standard"),
    /** Queued locally, waiting for any transport */
    LOCAL_QUEUE("local_queue");

    companion object {
        fun fromValue(value: String): MeshTransport {
            return entries.find { it.value == value } ?: LOCAL_QUEUE
        }
    }
}
