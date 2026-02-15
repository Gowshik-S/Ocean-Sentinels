package com.oceansentinels.app.domain.repository

import com.oceansentinels.app.domain.model.*

/**
 * Repository interface for analytics operations
 */
interface AnalyticsRepository {
    
    /**
     * Get dashboard analytics overview
     */
    suspend fun getDashboardAnalytics(): Result<DashboardAnalytics>
    
    /**
     * Get incidents timeline for the specified number of days
     */
    suspend fun getIncidentsTimeline(days: Int = 30): Result<IncidentsTimeline>
    
    /**
     * Get incidents distribution by status, type, and urgency
     */
    suspend fun getIncidentsDistribution(): Result<IncidentsDistribution>
    
    /**
     * Get geographic analytics
     */
    suspend fun getGeographicAnalytics(): Result<GeographicAnalytics>
    
    /**
     * Get all analytics data at once
     */
    suspend fun getAllAnalytics(): Result<AnalyticsData>
}
