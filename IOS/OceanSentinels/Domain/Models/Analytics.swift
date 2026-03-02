import Foundation

// MARK: - DashboardAnalytics

struct DashboardAnalytics: Codable, Equatable {
    let totalIncidents: Int
    let activeIncidents: Int
    let resolvedIncidents: Int
    let totalRescueTeams: Int
    let totalAuthorities: Int
    let totalCitizens: Int
    let coastlineWatched: Double
    let activeAlerts: Int
    let pendingCount: Int
    let verifiedCount: Int
    let deployedCount: Int
    let resolvedCount: Int
    let avgVerificationTime: Double
    let avgResponseTime: Double
    let avgResolutionTime: Double
    let resolutionRate: Float
}

// MARK: - TimelineDataPoint

struct TimelineDataPoint: Codable, Equatable, Identifiable {
    let date: String
    let count: Int

    var id: String { date }
}

// MARK: - IncidentsTimeline

struct IncidentsTimeline: Codable, Equatable {
    let dataPoints: [TimelineDataPoint]
    let totalCount: Int
    let periodDays: Int
}

// MARK: - DistributionItem

struct DistributionItem: Codable, Equatable, Identifiable {
    let label: String
    let value: Int
    let percentage: Float

    var id: String { label }
}

// MARK: - IncidentsDistribution

struct IncidentsDistribution: Codable, Equatable {
    let byStatus: [DistributionItem]
    let byHazardType: [DistributionItem]
    let byUrgency: [DistributionItem]
}

// MARK: - GeographicData

struct GeographicData: Codable, Equatable, Identifiable {
    let regionName: String
    let incidentCount: Int
    let latitude: Double
    let longitude: Double

    var id: String { regionName }
}

// MARK: - GeographicAnalytics

struct GeographicAnalytics: Codable, Equatable {
    let regions: [GeographicData]
    let topRegions: [GeographicData]
}

// MARK: - AnalyticsData

struct AnalyticsData: Codable, Equatable {
    let dashboard: DashboardAnalytics
    let timeline: IncidentsTimeline
    let distribution: IncidentsDistribution
    let geographic: GeographicAnalytics
}
