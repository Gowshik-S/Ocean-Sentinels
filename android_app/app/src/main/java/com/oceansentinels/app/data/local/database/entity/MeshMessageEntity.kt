package com.oceansentinels.app.data.local.database.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.oceansentinels.app.mesh.model.MeshMessage
import com.oceansentinels.app.mesh.model.MeshMessageStatus
import com.oceansentinels.app.mesh.model.MeshTransport
import java.time.LocalDateTime
import java.time.Instant
import java.time.ZoneId

/**
 * Room entity for mesh message queue.
 * Stores messages that need to be sent to the server, either directly
 * via internet or relayed through the BLE mesh network.
 */
@Entity(
    tableName = "mesh_messages",
    indices = [
        Index(value = ["message_id"], unique = true),
        Index(value = ["status"]),
        Index(value = ["created_at"]),
        Index(value = ["origin_device_mac"])
    ]
)
data class MeshMessageEntity(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "local_id")
    val localId: Long = 0,

    @ColumnInfo(name = "message_id")
    val messageId: String,

    @ColumnInfo(name = "origin_device_mac")
    val originDeviceMac: String,

    @ColumnInfo(name = "origin_device_fingerprint")
    val originDeviceFingerprint: String,

    @ColumnInfo(name = "hazard_type")
    val hazardType: String,

    @ColumnInfo(name = "location")
    val location: String,

    @ColumnInfo(name = "latitude")
    val latitude: Double?,

    @ColumnInfo(name = "longitude")
    val longitude: Double?,

    @ColumnInfo(name = "description")
    val description: String,

    @ColumnInfo(name = "urgency")
    val urgency: String,

    @ColumnInfo(name = "created_at_millis")
    val createdAtMillis: Long,

    @ColumnInfo(name = "ttl")
    val ttl: Int = 0, // Legacy column, kept for Room schema compat. No longer used for relay decisions.

    @ColumnInfo(name = "hop_count")
    val hopCount: Int,

    @ColumnInfo(name = "status")
    val status: String,

    @ColumnInfo(name = "transport")
    val transport: String = MeshTransport.LOCAL_QUEUE.value,

    @ColumnInfo(name = "relay_path")
    val relayPath: String = "", // Comma-separated MAC addresses

    @ColumnInfo(name = "photo_url")
    val photoUrl: String? = null,

    @ColumnInfo(name = "contact_info")
    val contactInfo: String? = null,

    @ColumnInfo(name = "reporter_user_id")
    val reporterUserId: Int? = null,

    @ColumnInfo(name = "server_reference_id")
    val serverReferenceId: String? = null,

    @ColumnInfo(name = "retry_count")
    val retryCount: Int = 0,

    @ColumnInfo(name = "max_retries")
    val maxRetries: Int = 5,

    @ColumnInfo(name = "last_attempt_at")
    val lastAttemptAt: LocalDateTime? = null,

    @ColumnInfo(name = "delivered_at")
    val deliveredAt: LocalDateTime? = null,

    @ColumnInfo(name = "created_at")
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @ColumnInfo(name = "expires_at")
    val expiresAt: LocalDateTime = LocalDateTime.now().plusHours(72),

    /** Whether this message was created by this device (vs received from mesh) */
    @ColumnInfo(name = "is_own_message")
    val isOwnMessage: Boolean = true,

    /** Whether this message has been relayed to other peers */
    @ColumnInfo(name = "has_been_relayed")
    val hasBeenRelayed: Boolean = false
) {
    fun toDomain(): MeshMessage {
        return MeshMessage(
            messageId = messageId,
            originDeviceMac = originDeviceMac,
            originDeviceFingerprint = originDeviceFingerprint,
            hazardType = hazardType,
            location = location,
            latitude = latitude,
            longitude = longitude,
            description = description,
            urgency = urgency,
            createdAtMillis = createdAtMillis,
            hopCount = hopCount,
            status = MeshMessageStatus.fromValue(status),
            relayPath = if (relayPath.isBlank()) emptyList() else relayPath.split(",").filter { it.isNotBlank() },
            photoUrl = photoUrl,
            contactInfo = contactInfo,
            reporterUserId = reporterUserId,
            serverReferenceId = serverReferenceId
        )
    }

    companion object {
        fun fromDomain(
            message: MeshMessage,
            isOwnMessage: Boolean = true,
            transport: MeshTransport = MeshTransport.LOCAL_QUEUE,
            overrideStatus: MeshMessageStatus? = null
        ): MeshMessageEntity {
            return MeshMessageEntity(
                messageId = message.messageId,
                originDeviceMac = message.originDeviceMac,
                originDeviceFingerprint = message.originDeviceFingerprint,
                hazardType = message.hazardType,
                location = message.location,
                latitude = message.latitude,
                longitude = message.longitude,
                description = message.description,
                urgency = message.urgency,
                createdAtMillis = message.createdAtMillis,
                hopCount = message.hopCount,
                status = (overrideStatus ?: message.status).value,
                transport = transport.value,
                relayPath = message.relayPath.joinToString(","),
                photoUrl = message.photoUrl,
                contactInfo = message.contactInfo,
                reporterUserId = message.reporterUserId,
                serverReferenceId = message.serverReferenceId,
                isOwnMessage = isOwnMessage
            )
        }
    }
}
