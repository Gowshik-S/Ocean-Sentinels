import Foundation
import os

/// Implementation of AnalyticsRepository.
/// Replaces Kotlin AnalyticsRepositoryImpl.
final class AnalyticsRepositoryImpl: AnalyticsRepository {
    
    private let api: OceanSentinelsAPI
    private let logger = Logger(subsystem: "com.oceansentinels.app", category: "AnalyticsRepo")
    
    init(api: OceanSentinelsAPI) {
        self.api = api
    }
    
    func getDashboardAnalytics() async throws -> DashboardAnalytics {
        logger.debug("Fetching dashboard analytics")
        let response = try await api.getDashboardAnalytics()
        return response.toDomain()
    }
    
    func getIncidentsTimeline(days: Int) async throws -> IncidentsTimeline {
        logger.debug("Fetching incidents timeline for \(days) days")
        let response = try await api.getIncidentsTimeline(days: days)
        return response.toDomain()
    }
    
    func getIncidentsDistribution() async throws -> IncidentsDistribution {
        logger.debug("Fetching incidents distribution")
        let response = try await api.getIncidentsDistribution()
        return response.toDomain()
    }
    
    func getGeographicAnalytics() async throws -> GeographicAnalytics {
        logger.debug("Fetching geographic analytics")
        let response = try await api.getGeographicAnalytics()
        return response.toDomain()
    }
    
    func getAllAnalytics() async throws -> AnalyticsData {
        async let dashboard = getDashboardAnalytics()
        async let timeline = getIncidentsTimeline(days: 30)
        async let distribution = getIncidentsDistribution()
        async let geographic = getGeographicAnalytics()
        
        return try await AnalyticsData(
            dashboard: dashboard,
            timeline: timeline,
            distribution: distribution,
            geographic: geographic
        )
    }
}
