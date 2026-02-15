package com.oceansentinels.app.data.repository

import com.oceansentinels.app.data.remote.api.OceanSentinelsApi
import com.oceansentinels.app.domain.model.*
import com.oceansentinels.app.domain.repository.AnalyticsRepository
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Implementation of AnalyticsRepository
 */
@Singleton
class AnalyticsRepositoryImpl @Inject constructor(
    private val api: OceanSentinelsApi
) : AnalyticsRepository {

    override suspend fun getDashboardAnalytics(): Result<DashboardAnalytics> {
        return try {
            Timber.d("Fetching dashboard analytics")
            
            val response = api.getDashboardAnalytics()
            
            if (response.isSuccessful && response.body() != null) {
                val analytics = response.body()!!.toDomain()
                Timber.d("Dashboard analytics fetched successfully")
                Result.success(analytics)
            } else {
                val errorBody = response.errorBody()?.string() ?: "Unknown error"
                Timber.e("Failed to fetch dashboard analytics: $errorBody")
                Result.failure(Exception("Failed to fetch dashboard analytics"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error fetching dashboard analytics")
            Result.failure(e)
        }
    }

    override suspend fun getIncidentsTimeline(days: Int): Result<IncidentsTimeline> {
        return try {
            Timber.d("Fetching incidents timeline for $days days")
            
            val response = api.getIncidentsTimeline(days)
            
            if (response.isSuccessful && response.body() != null) {
                val timeline = response.body()!!.toDomain()
                Timber.d("Timeline fetched successfully with ${timeline.dataPoints.size} points")
                Result.success(timeline)
            } else {
                Result.failure(Exception("Failed to fetch incidents timeline"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error fetching incidents timeline")
            Result.failure(e)
        }
    }

    override suspend fun getIncidentsDistribution(): Result<IncidentsDistribution> {
        return try {
            Timber.d("Fetching incidents distribution")
            
            val response = api.getIncidentsDistribution()
            
            if (response.isSuccessful && response.body() != null) {
                val distribution = response.body()!!.toDomain()
                Timber.d("Distribution fetched successfully")
                Result.success(distribution)
            } else {
                Result.failure(Exception("Failed to fetch incidents distribution"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error fetching incidents distribution")
            Result.failure(e)
        }
    }

    override suspend fun getGeographicAnalytics(): Result<GeographicAnalytics> {
        return try {
            Timber.d("Fetching geographic analytics")
            
            val response = api.getGeographicAnalytics()
            
            if (response.isSuccessful && response.body() != null) {
                val geographic = response.body()!!.toDomain()
                Timber.d("Geographic analytics fetched successfully")
                Result.success(geographic)
            } else {
                Result.failure(Exception("Failed to fetch geographic analytics"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error fetching geographic analytics")
            Result.failure(e)
        }
    }

    override suspend fun getAllAnalytics(): Result<AnalyticsData> {
        return try {
            val dashboard = getDashboardAnalytics().getOrThrow()
            val timeline = getIncidentsTimeline().getOrThrow()
            val distribution = getIncidentsDistribution().getOrThrow()
            val geographic = getGeographicAnalytics().getOrThrow()
            
            Result.success(
                AnalyticsData(
                    dashboard = dashboard,
                    timeline = timeline,
                    distribution = distribution,
                    geographic = geographic
                )
            )
        } catch (e: Exception) {
            Timber.e(e, "Error fetching all analytics")
            Result.failure(e)
        }
    }
}
