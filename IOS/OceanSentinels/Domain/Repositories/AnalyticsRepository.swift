import Foundation

/// Repository protocol for analytics and dashboard data.
protocol AnalyticsRepository {

    /// Fetches the main dashboard analytics summary.
    func getDashboardAnalytics() async throws -> DashboardAnalytics

    /// Fetches the incidents timeline for a given number of days.
    func getIncidentsTimeline(days: Int) async throws -> IncidentsTimeline

    /// Fetches the distribution of incidents by status, hazard type, and urgency.
    func getIncidentsDistribution() async throws -> IncidentsDistribution

    /// Fetches geographic analytics data for incident regions.
    func getGeographicAnalytics() async throws -> GeographicAnalytics

    /// Fetches all analytics data in a single call.
    func getAllAnalytics() async throws -> AnalyticsData
}
