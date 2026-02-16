package com.oceansentinels.app.data.remote.dto

import com.google.gson.annotations.SerializedName
import com.oceansentinels.app.domain.model.*
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

/**
 * Incident DTOs for API communication
 */

data class IncidentDto(
    @SerializedName("id") val id: Int,
    @SerializedName("reference_id") val referenceId: String,
    @SerializedName("hazard_type") val hazardType: String,
    @SerializedName("location") val location: String,
    @SerializedName("latitude") val latitude: Double?,
    @SerializedName("longitude") val longitude: Double?,
    @SerializedName("description") val description: String,
    @SerializedName("urgency") val urgency: String,
    @SerializedName("status") val status: String,
    @SerializedName("reporter_id") val reporterId: Int,
    @SerializedName("verified_by_id") val verifiedById: Int?,
    @SerializedName("photo_url") val photoUrl: String?,
    @SerializedName("contact_info") val contactInfo: String?,
    @SerializedName("created_at") val createdAt: String,
    @SerializedName("updated_at") val updatedAt: String?,
    @SerializedName("verified_at") val verifiedAt: String?,
    @SerializedName("resolved_at") val resolvedAt: String?,
    @SerializedName("assigned_to_id") val assignedToId: Int? = null,
    @SerializedName("assigned_at") val assignedAt: String? = null
) {
    fun toDomain(): Incident {
        return Incident(
            id = id,
            referenceId = referenceId,
            hazardType = HazardType.fromValue(hazardType),
            location = location,
            latitude = latitude,
            longitude = longitude,
            description = description,
            urgency = UrgencyLevel.fromValue(urgency),
            status = IncidentStatus.fromValue(status),
            reporterId = reporterId,
            verifiedById = verifiedById,
            photoUrl = photoUrl,
            contactInfo = contactInfo,
            createdAt = createdAt.parseDateTime() ?: LocalDateTime.now(),
            updatedAt = updatedAt?.parseDateTime(),
            verifiedAt = verifiedAt?.parseDateTime(),
            resolvedAt = resolvedAt?.parseDateTime(),
            assignedToId = assignedToId,
            assignedAt = assignedAt?.parseDateTime()
        )
    }
}

data class IncidentListResponseDto(
    @SerializedName("incidents") val incidents: List<IncidentDto>,
    @SerializedName("total") val total: Int,
    @SerializedName("page") val page: Int,
    @SerializedName("size") val size: Int,
    @SerializedName("has_next") val hasNext: Boolean,
    @SerializedName("has_prev") val hasPrev: Boolean
) {
    fun toDomain(): IncidentListResult {
        return IncidentListResult(
            incidents = incidents.map { it.toDomain() },
            total = total,
            page = page,
            size = size,
            hasNext = hasNext,
            hasPrev = hasPrev
        )
    }
}

data class CreateIncidentRequestDto(
    @SerializedName("hazard_type") val hazardType: String,
    @SerializedName("location") val location: String,
    @SerializedName("latitude") val latitude: Double?,
    @SerializedName("longitude") val longitude: Double?,
    @SerializedName("description") val description: String,
    @SerializedName("urgency") val urgency: String,
    @SerializedName("contact_info") val contactInfo: String?,
    @SerializedName("mesh_message_id") val meshMessageId: String? = null
) {
    companion object {
        fun fromDomain(request: CreateIncidentRequest): CreateIncidentRequestDto {
            return CreateIncidentRequestDto(
                hazardType = request.hazardType.value,
                location = request.location,
                latitude = request.latitude,
                longitude = request.longitude,
                description = request.description,
                urgency = request.urgency.value,
                contactInfo = request.contactInfo
            )
        }
    }
}

// Extension function for parsing date strings
private fun String.parseDateTime(): LocalDateTime? {
    return try {
        LocalDateTime.parse(this, DateTimeFormatter.ISO_DATE_TIME)
    } catch (e: Exception) {
        try {
            LocalDateTime.parse(this.replace("Z", ""), DateTimeFormatter.ISO_LOCAL_DATE_TIME)
        } catch (e: Exception) {
            null
        }
    }
}

/**
 * Request DTO for bulk mesh message status check.
 * Sent when a device comes online to discover which queued messages
 * have already been uploaded to the server by other mesh devices.
 */
data class MeshCheckRequestDto(
    @SerializedName("message_ids") val messageIds: List<String>
)

/**
 * Response DTO for bulk mesh message status check.
 * 'delivered' = already in the server DB (can stop relaying)
 * 'unknown' = not yet on server (keep relaying or deliver ourselves)
 */
data class MeshCheckResponseDto(
    @SerializedName("delivered") val delivered: List<String>,
    @SerializedName("unknown") val unknown: List<String>
)
