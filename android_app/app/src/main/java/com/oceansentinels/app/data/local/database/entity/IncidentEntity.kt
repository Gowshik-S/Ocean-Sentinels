package com.oceansentinels.app.data.local.database.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import com.oceansentinels.app.domain.model.*
import java.time.LocalDateTime

/**
 * Incident entity for Room database (offline caching)
 */
@Entity(tableName = "incidents")
data class IncidentEntity(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: Int,
    
    @ColumnInfo(name = "reference_id")
    val referenceId: String,
    
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
    
    @ColumnInfo(name = "status")
    val status: String,
    
    @ColumnInfo(name = "reporter_id")
    val reporterId: Int,
    
    @ColumnInfo(name = "verified_by_id")
    val verifiedById: Int?,
    
    @ColumnInfo(name = "photo_url")
    val photoUrl: String?,
    
    @ColumnInfo(name = "contact_info")
    val contactInfo: String?,
    
    @ColumnInfo(name = "created_at")
    val createdAt: LocalDateTime,
    
    @ColumnInfo(name = "updated_at")
    val updatedAt: LocalDateTime?,
    
    @ColumnInfo(name = "verified_at")
    val verifiedAt: LocalDateTime?,
    
    @ColumnInfo(name = "resolved_at")
    val resolvedAt: LocalDateTime?,
    
    @ColumnInfo(name = "assigned_to_id", defaultValue = "NULL")
    val assignedToId: Int? = null,
    
    @ColumnInfo(name = "assigned_at", defaultValue = "NULL")
    val assignedAt: LocalDateTime? = null,
    
    @ColumnInfo(name = "cached_at")
    val cachedAt: LocalDateTime = LocalDateTime.now(),
    
    @ColumnInfo(name = "is_pending_sync")
    val isPendingSync: Boolean = false
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
            createdAt = createdAt,
            updatedAt = updatedAt,
            verifiedAt = verifiedAt,
            resolvedAt = resolvedAt,
            assignedToId = assignedToId,
            assignedAt = assignedAt
        )
    }
    
    companion object {
        fun fromDomain(incident: Incident, isPendingSync: Boolean = false): IncidentEntity {
            return IncidentEntity(
                id = incident.id,
                referenceId = incident.referenceId,
                hazardType = incident.hazardType.value,
                location = incident.location,
                latitude = incident.latitude,
                longitude = incident.longitude,
                description = incident.description,
                urgency = incident.urgency.value,
                status = incident.status.value,
                reporterId = incident.reporterId,
                verifiedById = incident.verifiedById,
                photoUrl = incident.photoUrl,
                contactInfo = incident.contactInfo,
                createdAt = incident.createdAt,
                updatedAt = incident.updatedAt,
                verifiedAt = incident.verifiedAt,
                resolvedAt = incident.resolvedAt,
                assignedToId = incident.assignedToId,
                assignedAt = incident.assignedAt,
                isPendingSync = isPendingSync
            )
        }
    }
}
