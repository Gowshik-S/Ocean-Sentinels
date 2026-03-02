import Foundation

// MARK: - Analytics DTOs

struct DashboardAnalyticsDTO: Codable {
    let totalIncidents: Int
    let activeIncidents: Int
    let resolvedIncidents: Int
    let falseAlarms: Int
    let incidentsByType: [String: Int]?
    let recentIncidents: Int
    let averageResponseTimeHours: Double
    let lastUpdated: String?
    
    enum CodingKeys: String, CodingKey {
        case totalIncidents = "total_incidents"
        case activeIncidents = "active_incidents"
        case resolvedIncidents = "resolved_incidents"
        case falseAlarms = "false_alarms"
        case incidentsByType = "incidents_by_type"
        case recentIncidents = "recent_incidents"
        case averageResponseTimeHours = "average_response_time_hours"
        case lastUpdated = "last_updated"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalIncidents = (try? container.decode(Int.self, forKey: .totalIncidents)) ?? 0
        activeIncidents = (try? container.decode(Int.self, forKey: .activeIncidents)) ?? 0
        resolvedIncidents = (try? container.decode(Int.self, forKey: .resolvedIncidents)) ?? 0
        falseAlarms = (try? container.decode(Int.self, forKey: .falseAlarms)) ?? 0
        incidentsByType = try? container.decode([String: Int].self, forKey: .incidentsByType)
        recentIncidents = (try? container.decode(Int.self, forKey: .recentIncidents)) ?? 0
        averageResponseTimeHours = (try? container.decode(Double.self, forKey: .averageResponseTimeHours)) ?? 0
        lastUpdated = try? container.decode(String.self, forKey: .lastUpdated)
    }
    
    func toDomain() -> DashboardAnalytics {
        DashboardAnalytics(
            totalIncidents: totalIncidents,
            activeIncidents: activeIncidents,
            resolvedIncidents: resolvedIncidents,
            totalRescueTeams: 0,
            totalAuthorities: 0,
            totalCitizens: 0,
            coastlineWatched: 0,
            activeAlerts: activeIncidents,
            pendingCount: activeIncidents,
            verifiedCount: 0,
            deployedCount: 0,
            resolvedCount: resolvedIncidents,
            avgVerificationTime: 0,
            avgResponseTime: averageResponseTimeHours,
            avgResolutionTime: 0,
            resolutionRate: totalIncidents > 0 ? Float(resolvedIncidents) / Float(totalIncidents) : 0
        )
    }
}

struct TimelineDataPointDTO: Codable {
    let date: String?
    let count: Int
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try? container.decode(String.self, forKey: .date)
        count = (try? container.decode(Int.self, forKey: .count)) ?? 0
    }
    
    func toDomain() -> TimelineDataPoint {
        TimelineDataPoint(date: date ?? "", count: count)
    }
}

struct IncidentsTimelineDTO: Codable {
    let timeline: [TimelineDataPointDTO]?
    let periodDays: Int
    let startDate: String?
    let endDate: String?
    
    enum CodingKeys: String, CodingKey {
        case timeline
        case periodDays = "period_days"
        case startDate = "start_date"
        case endDate = "end_date"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timeline = try? container.decode([TimelineDataPointDTO].self, forKey: .timeline)
        periodDays = (try? container.decode(Int.self, forKey: .periodDays)) ?? 30
        startDate = try? container.decode(String.self, forKey: .startDate)
        endDate = try? container.decode(String.self, forKey: .endDate)
    }
    
    func toDomain() -> IncidentsTimeline {
        let points = timeline?.map { $0.toDomain() } ?? []
        return IncidentsTimeline(
            dataPoints: points,
            totalCount: points.reduce(0) { $0 + $1.count },
            periodDays: periodDays
        )
    }
}

struct IncidentsDistributionDTO: Codable {
    let byType: [String: Int]?
    let byStatus: [String: Int]?
    let byUrgency: [String: Int]?
    
    enum CodingKeys: String, CodingKey {
        case byType = "by_type"
        case byStatus = "by_status"
        case byUrgency = "by_urgency"
    }
    
    func toDomain() -> IncidentsDistribution {
        IncidentsDistribution(
            byStatus: mapToDistributionItems(byStatus),
            byHazardType: mapToDistributionItems(byType),
            byUrgency: mapToDistributionItems(byUrgency)
        )
    }
    
    private func mapToDistributionItems(_ map: [String: Int]?) -> [DistributionItem] {
        guard let map = map else { return [] }
        let total = max(Float(map.values.reduce(0, +)), 1)
        return map.map { (label, value) in
            DistributionItem(
                label: label.replacingOccurrences(of: "_", with: " ").capitalized,
                value: value,
                percentage: Float(value) / total * 100
            )
        }
    }
}

struct GeographicIncidentDTO: Codable {
    let lat: Double
    let lng: Double
    let type: String?
    let status: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lat = (try? container.decode(Double.self, forKey: .lat)) ?? 0
        lng = (try? container.decode(Double.self, forKey: .lng)) ?? 0
        type = try? container.decode(String.self, forKey: .type)
        status = try? container.decode(String.self, forKey: .status)
    }
}

struct GeographicAnalyticsDTO: Codable {
    let incidents: [GeographicIncidentDTO]?
    let totalLocatedIncidents: Int
    
    enum CodingKeys: String, CodingKey {
        case incidents
        case totalLocatedIncidents = "total_located_incidents"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        incidents = try? container.decode([GeographicIncidentDTO].self, forKey: .incidents)
        totalLocatedIncidents = (try? container.decode(Int.self, forKey: .totalLocatedIncidents)) ?? 0
    }
    
    func toDomain() -> GeographicAnalytics {
        let geoPoints = incidents?.map { incident in
            GeographicData(
                regionName: incident.type?.replacingOccurrences(of: "_", with: " ").capitalized ?? "Unknown",
                incidentCount: 1,
                latitude: incident.lat,
                longitude: incident.lng
            )
        } ?? []
        return GeographicAnalytics(
            regions: geoPoints,
            topRegions: Array(geoPoints.prefix(5))
        )
    }
}

struct UploadResponseDTO: Codable {
    let url: String
    let filename: String
}
