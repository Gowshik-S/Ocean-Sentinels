package com.oceansentinels.app.data.remote.dto

import com.google.gson.annotations.SerializedName
import com.oceansentinels.app.domain.model.*

/**
 * Analytics DTOs for API communication
 * Aligned with actual backend response formats
 */

data class DashboardAnalyticsDto(
    @SerializedName("total_incidents") val totalIncidents: Int = 0,
    @SerializedName("active_incidents") val activeIncidents: Int = 0,
    @SerializedName("resolved_incidents") val resolvedIncidents: Int = 0,
    @SerializedName("false_alarms") val falseAlarms: Int = 0,
    @SerializedName("incidents_by_type") val incidentsByType: Map<String, Int>? = null,
    @SerializedName("recent_incidents") val recentIncidents: Int = 0,
    @SerializedName("average_response_time_hours") val averageResponseTimeHours: Double = 0.0,
    @SerializedName("last_updated") val lastUpdated: String? = null
) {
    fun toDomain(): DashboardAnalytics {
        // Derive pending = active - resolved (active includes PENDING, VERIFIED, IN_PROGRESS)
        val pendingCount = activeIncidents
        return DashboardAnalytics(
            totalIncidents = totalIncidents,
            activeIncidents = activeIncidents,
            resolvedIncidents = resolvedIncidents,
            totalRescueTeams = 0,
            totalAuthorities = 0,
            totalCitizens = 0,
            activeAlerts = activeIncidents,
            pendingCount = pendingCount,
            resolvedCount = resolvedIncidents,
            avgResponseTime = averageResponseTimeHours
        )
    }
}

data class TimelineDataPointDto(
    @SerializedName("date") val date: String? = null,
    @SerializedName("count") val count: Int = 0
) {
    fun toDomain(): TimelineDataPoint {
        return TimelineDataPoint(
            date = date ?: "",
            count = count
        )
    }
}

/**
 * Backend returns: {"timeline": [...], "period_days": int, "start_date": str, "end_date": str}
 */
data class IncidentsTimelineDto(
    @SerializedName("timeline") val timeline: List<TimelineDataPointDto>? = null,
    @SerializedName("period_days") val periodDays: Int = 30,
    @SerializedName("start_date") val startDate: String? = null,
    @SerializedName("end_date") val endDate: String? = null
) {
    fun toDomain(): IncidentsTimeline {
        val points = timeline?.map { it.toDomain() } ?: emptyList()
        return IncidentsTimeline(
            dataPoints = points,
            totalCount = points.sumOf { it.count },
            periodDays = periodDays
        )
    }
}

/**
 * Backend returns flat maps: {"by_type": {"HIGH_WAVES": 5}, "by_status": {...}, "by_urgency": {...}}
 */
data class IncidentsDistributionDto(
    @SerializedName("by_type") val byType: Map<String, Int>? = null,
    @SerializedName("by_status") val byStatus: Map<String, Int>? = null,
    @SerializedName("by_urgency") val byUrgency: Map<String, Int>? = null
) {
    fun toDomain(): IncidentsDistribution {
        return IncidentsDistribution(
            byStatus = mapToDistributionItems(byStatus),
            byHazardType = mapToDistributionItems(byType),
            byUrgency = mapToDistributionItems(byUrgency)
        )
    }

    private fun mapToDistributionItems(map: Map<String, Int>?): List<com.oceansentinels.app.domain.model.DistributionItem> {
        if (map == null) return emptyList()
        val total = map.values.sum().toFloat().coerceAtLeast(1f)
        return map.map { (label, value) ->
            com.oceansentinels.app.domain.model.DistributionItem(
                label = label.replace("_", " ").lowercase()
                    .replaceFirstChar { it.uppercase() },
                value = value,
                percentage = (value / total) * 100f
            )
        }
    }
}

/**
 * Backend returns: {"incidents": [{"lat", "lng", "type", "status"}], "total_located_incidents": int}
 */
data class GeographicIncidentDto(
    @SerializedName("lat") val lat: Double = 0.0,
    @SerializedName("lng") val lng: Double = 0.0,
    @SerializedName("type") val type: String? = null,
    @SerializedName("status") val status: String? = null
)

data class GeographicAnalyticsDto(
    @SerializedName("incidents") val incidents: List<GeographicIncidentDto>? = null,
    @SerializedName("total_located_incidents") val totalLocatedIncidents: Int = 0
) {
    fun toDomain(): GeographicAnalytics {
        val geoPoints = incidents?.map { incident ->
            GeographicData(
                regionName = incident.type?.replace("_", " ")?.lowercase()
                    ?.replaceFirstChar { it.uppercase() } ?: "Unknown",
                incidentCount = 1,
                latitude = incident.lat,
                longitude = incident.lng
            )
        } ?: emptyList()
        return GeographicAnalytics(
            regions = geoPoints,
            topRegions = geoPoints.take(5)
        )
    }
}

/**
 * Generic message response from backend (verify/deploy/resolve endpoints)
 */
data class MessageResponseDto(
    @SerializedName("message") val message: String = ""
)
