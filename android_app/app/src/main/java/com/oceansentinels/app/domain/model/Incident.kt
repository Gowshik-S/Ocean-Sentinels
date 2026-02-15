package com.oceansentinels.app.domain.model

import java.time.LocalDateTime

/**
 * Incident domain model representing a coastal hazard report
 */
data class Incident(
    val id: Int,
    val referenceId: String,
    val hazardType: HazardType,
    val location: String,
    val latitude: Double? = null,
    val longitude: Double? = null,
    val description: String,
    val urgency: UrgencyLevel,
    val status: IncidentStatus,
    val reporterId: Int,
    val verifiedById: Int? = null,
    val photoUrl: String? = null,
    val contactInfo: String? = null,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime? = null,
    val verifiedAt: LocalDateTime? = null,
    val resolvedAt: LocalDateTime? = null,
    val assignedToId: Int? = null,
    val assignedAt: LocalDateTime? = null
) {
    val hasLocation: Boolean
        get() = latitude != null && longitude != null
    
    val isPending: Boolean
        get() = status == IncidentStatus.PENDING
    
    val isActive: Boolean
        get() = status in listOf(IncidentStatus.PENDING, IncidentStatus.VERIFIED, IncidentStatus.IN_PROGRESS)
    
    val isResolved: Boolean
        get() = status == IncidentStatus.RESOLVED
    
    val canBeVerified: Boolean
        get() = status == IncidentStatus.PENDING
    
    val canBeDeployed: Boolean
        get() = status == IncidentStatus.VERIFIED
    
    val canBeResolved: Boolean
        get() = status == IncidentStatus.IN_PROGRESS
}

/**
 * Hazard types that can be reported
 */
enum class HazardType(val value: String, val displayName: String, val icon: String) {
    HIGH_WAVES("high_waves", "High Waves", "waves"),
    STRONG_CURRENTS("strong_currents", "Strong Currents", "cyclone"),
    FLOODING("flooding", "Coastal Flooding", "water_drop"),
    TSUNAMI("tsunami", "Tsunami Warning", "warning"),
    DEBRIS("debris", "Debris/Pollution", "delete"),
    EROSION("erosion", "Coastal Erosion", "terrain"),
    STORM("storm", "Storm Alert", "thunderstorm"),
    OTHER("other", "Other Hazard", "help");
    
    companion object {
        fun fromValue(value: String): HazardType {
            return entries.find { it.value == value.lowercase().replace("-", "_") } ?: OTHER
        }
    }
}

/**
 * Urgency levels for incidents
 */
enum class UrgencyLevel(val value: String, val displayName: String, val priority: Int) {
    LOW("low", "Low", 1),
    MEDIUM("medium", "Medium", 2),
    HIGH("high", "High", 3),
    CRITICAL("critical", "Critical", 4);
    
    companion object {
        fun fromValue(value: String): UrgencyLevel {
            return entries.find { it.value == value.lowercase() } ?: LOW
        }
    }
}

/**
 * Incident status
 */
enum class IncidentStatus(val value: String, val displayName: String) {
    PENDING("pending", "Pending"),
    VERIFIED("verified", "Verified"),
    IN_PROGRESS("in_progress", "In Progress"),
    RESOLVED("resolved", "Resolved"),
    CLOSED("closed", "Closed");
    
    companion object {
        fun fromValue(value: String): IncidentStatus {
            return entries.find { it.value == value.lowercase() } ?: PENDING
        }
    }
}

/**
 * Data for creating a new incident report
 */
data class CreateIncidentRequest(
    val hazardType: HazardType,
    val location: String,
    val latitude: Double? = null,
    val longitude: Double? = null,
    val description: String,
    val urgency: UrgencyLevel = UrgencyLevel.LOW,
    val contactInfo: String? = null,
    val photoUrl: String? = null
)

/**
 * Incident list with pagination
 */
data class IncidentListResult(
    val incidents: List<Incident>,
    val total: Int,
    val page: Int,
    val size: Int,
    val hasNext: Boolean,
    val hasPrev: Boolean
)

/**
 * Filters for querying incidents
 */
data class IncidentFilters(
    val status: IncidentStatus? = null,
    val hazardType: HazardType? = null,
    val urgency: UrgencyLevel? = null,
    val searchQuery: String? = null,
    val page: Int = 1,
    val size: Int = 20
)
