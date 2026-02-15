package com.oceansentinels.app.mesh.model

import java.security.MessageDigest
import java.time.Instant

/**
 * Represents a mesh message that can be relayed between devices.
 * Each message has a unique deterministic ID to prevent spam/duplicates.
 *
 * Flow: Internet → BLE PHY Coded Mesh → Normal BLE → Local Queue
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
    /** TTL: decremented at each hop, dropped at 0. Default 7. */
    val ttl: Int = DEFAULT_TTL,
    /** Number of hops this message has taken */
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
        const val DEFAULT_TTL = 7
        const val MAX_RELAY_PATH = 20

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

    /** Create a relayed copy with decremented TTL and updated path */
    fun relay(relayDeviceMac: String): MeshMessage? {
        if (ttl <= 1) return null // TTL expired
        if (relayPath.contains(relayDeviceMac)) return null // Loop detected
        if (relayPath.size >= MAX_RELAY_PATH) return null // Path too long

        return copy(
            ttl = ttl - 1,
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
            append("\"ttl\":$ttl,")
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
