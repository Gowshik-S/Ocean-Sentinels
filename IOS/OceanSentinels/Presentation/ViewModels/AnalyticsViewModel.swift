import Foundation
import Observation

// MARK: - AnalyticsViewModel

/// ViewModel for analytics — dashboard, timeline, distribution, and geographic data.
@Observable
@MainActor
final class AnalyticsViewModel {

    // MARK: - State

    var dashboardAnalytics: DashboardAnalytics?
    var timeline: IncidentsTimeline?
    var distribution: IncidentsDistribution?
    var geographic: GeographicAnalytics?
    var isLoading: Bool = false
    var error: String?
    var timelinePeriod: Int = 30

    // MARK: - Dependencies

    private let analyticsRepository: any AnalyticsRepository

    // MARK: - Init

    init(analyticsRepository: any AnalyticsRepository) {
        self.analyticsRepository = analyticsRepository
        loadAllAnalytics()
    }

    // MARK: - Load All

    /// Load all analytics data in one call.
    func loadAllAnalytics() {
        Task {
            isLoading = true
            error = nil

            do {
                let data = try await analyticsRepository.getAllAnalytics()
                dashboardAnalytics = data.dashboard
                timeline = data.timeline
                distribution = data.distribution
                geographic = data.geographic
                AppLogger.analytics.debug("Analytics loaded successfully")
            } catch {
                self.error = error.localizedDescription
                AppLogger.analytics.error("Failed to load analytics: \(error.localizedDescription)")
            }

            isLoading = false
        }
    }

    // MARK: - Individual Loads

    /// Load dashboard analytics only.
    func loadDashboardAnalytics() {
        Task {
            isLoading = true

            do {
                dashboardAnalytics = try await analyticsRepository.getDashboardAnalytics()
            } catch {
                self.error = error.localizedDescription
            }

            isLoading = false
        }
    }

    /// Load timeline for specified period.
    func loadTimeline(days: Int = 30) {
        Task {
            isLoading = true
            timelinePeriod = days

            do {
                timeline = try await analyticsRepository.getIncidentsTimeline(days: days)
            } catch {
                self.error = error.localizedDescription
            }

            isLoading = false
        }
    }

    /// Load distribution data.
    func loadDistribution() {
        Task {
            isLoading = true

            do {
                distribution = try await analyticsRepository.getIncidentsDistribution()
            } catch {
                self.error = error.localizedDescription
            }

            isLoading = false
        }
    }

    /// Load geographic analytics.
    func loadGeographic() {
        Task {
            isLoading = true

            do {
                geographic = try await analyticsRepository.getGeographicAnalytics()
            } catch {
                self.error = error.localizedDescription
            }

            isLoading = false
        }
    }

    // MARK: - Actions

    /// Refresh all analytics.
    func refresh() {
        loadAllAnalytics()
    }

    func clearError() {
        error = nil
    }
}
