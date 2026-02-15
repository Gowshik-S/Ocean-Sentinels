package com.oceansentinels.app.domain.model

/**
 * Analytics data models for the Ocean Sentinels dashboard
 */

/**
 * Dashboard overview analytics
 */
data class DashboardAnalytics(
    val totalIncidents: Int,
    val activeIncidents: Int,
    val resolvedIncidents: Int,
    val totalRescueTeams: Int,
    val totalAuthorities: Int,
    val totalCitizens: Int,
    val coastlineWatched: String = "7,516 km",
    val activeAlerts: Int = 0,
    val pendingCount: Int = 0,
    val verifiedCount: Int = 0,
    val deployedCount: Int = 0,
    val resolvedCount: Int = 0,
    val avgVerificationTime: Double = 0.0,
    val avgResponseTime: Double = 0.0,
    val avgResolutionTime: Double = 0.0,
    val resolutionRate: Double = 0.0
)

/**
 * Incidents timeline data point
 */
data class TimelineDataPoint(
    val date: String,
    val count: Int
)

/**
 * Incidents timeline analytics
 */
data class IncidentsTimeline(
    val dataPoints: List<TimelineDataPoint>,
    val totalCount: Int,
    val periodDays: Int
)

/**
 * Distribution data item
 */
data class DistributionItem(
    val label: String,
    val value: Int,
    val percentage: Float
)

/**
 * Incidents distribution by status, hazard type, or urgency
 */
data class IncidentsDistribution(
    val byStatus: List<DistributionItem>,
    val byHazardType: List<DistributionItem>,
    val byUrgency: List<DistributionItem>
)

/**
 * Geographic analytics data
 */
data class GeographicData(
    val regionName: String,
    val incidentCount: Int,
    val latitude: Double,
    val longitude: Double
)

/**
 * Geographic analytics
 */
data class GeographicAnalytics(
    val regions: List<GeographicData>,
    val topRegions: List<GeographicData>
)

/**
 * Complete analytics data
 */
data class AnalyticsData(
    val dashboard: DashboardAnalytics,
    val timeline: IncidentsTimeline,
    val distribution: IncidentsDistribution,
    val geographic: GeographicAnalytics
)
