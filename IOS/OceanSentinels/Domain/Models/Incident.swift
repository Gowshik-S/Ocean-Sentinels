import Foundation

// MARK: - HazardType

enum HazardType: String, Codable, CaseIterable, Identifiable {
    case highWaves = "HIGH_WAVES"
    case strongCurrents = "STRONG_CURRENTS"
    case flooding = "FLOODING"
    case tsunami = "TSUNAMI"
    case debris = "DEBRIS"
    case erosion = "EROSION"
    case storm = "STORM"
    case other = "OTHER"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .highWaves: return "High Waves"
        case .strongCurrents: return "Strong Currents"
        case .flooding: return "Flooding"
        case .tsunami: return "Tsunami"
        case .debris: return "Debris"
        case .erosion: return "Erosion"
        case .storm: return "Storm"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .highWaves: return "water.waves"
        case .strongCurrents: return "wind"
        case .flooding: return "cloud.heavyrain.fill"
        case .tsunami: return "tropicalstorm"
        case .debris: return "leaf.fill"
        case .erosion: return "mountain.2.fill"
        case .storm: return "cloud.bolt.rain.fill"
        case .other: return "exclamationmark.triangle.fill"
        }
    }

    var value: String { rawValue }

    static func fromValue(_ value: String) -> HazardType {
        return HazardType(rawValue: value) ?? .other
    }
}

// MARK: - UrgencyLevel

enum UrgencyLevel: String, Codable, CaseIterable, Identifiable, Comparable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case critical = "CRITICAL"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }

    var priority: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        case .critical: return 3
        }
    }

    static func < (lhs: UrgencyLevel, rhs: UrgencyLevel) -> Bool {
        return lhs.priority < rhs.priority
    }

    var value: String { rawValue }

    static func fromValue(_ value: String) -> UrgencyLevel {
        return UrgencyLevel(rawValue: value) ?? .low
    }
}

// MARK: - IncidentStatus

enum IncidentStatus: String, Codable, CaseIterable, Identifiable {
    case pending = "PENDING"
    case verified = "VERIFIED"
    case inProgress = "IN_PROGRESS"
    case resolved = "RESOLVED"
    case closed = "CLOSED"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .verified: return "Verified"
        case .inProgress: return "In Progress"
        case .resolved: return "Resolved"
        case .closed: return "Closed"
        }
    }

    var value: String { rawValue }

    static func fromValue(_ value: String) -> IncidentStatus {
        return IncidentStatus(rawValue: value) ?? .pending
    }
}

// MARK: - Incident

struct Incident: Codable, Identifiable, Equatable {
    let id: Int
    let referenceId: String
    let hazardType: HazardType
    let location: String
    let latitude: Double?
    let longitude: Double?
    let description: String
    let urgency: UrgencyLevel
    let status: IncidentStatus
    let reporterId: Int
    let verifiedById: Int?
    let photoUrl: String?
    let contactInfo: String?
    let createdAt: Date
    let updatedAt: Date?
    let verifiedAt: Date?
    let resolvedAt: Date?
    let assignedToId: Int?
    let assignedAt: Date?

    // MARK: - Computed Properties

    var hasLocation: Bool {
        latitude != nil && longitude != nil
    }

    var isPending: Bool {
        status == .pending
    }

    var isActive: Bool {
        status == .pending || status == .verified || status == .inProgress
    }

    var isResolved: Bool {
        status == .resolved || status == .closed
    }

    var canBeVerified: Bool {
        status == .pending
    }

    var canBeDeployed: Bool {
        status == .verified
    }

    var canBeResolved: Bool {
        status == .inProgress
    }
}

// MARK: - CreateIncidentRequest

struct CreateIncidentRequest: Codable, Equatable {
    let hazardType: HazardType
    let location: String
    let latitude: Double?
    let longitude: Double?
    let description: String
    let urgency: UrgencyLevel
    let contactInfo: String?
    let photoUrl: String?

    enum CodingKeys: String, CodingKey {
        case hazardType
        case location
        case latitude = "lat"
        case longitude = "lng"
        case description
        case urgency
        case contactInfo
        case photoUrl
    }
}

// MARK: - IncidentListResult

struct IncidentListResult: Codable, Equatable {
    let incidents: [Incident]
    let total: Int
    let page: Int
    let size: Int
    let hasNext: Bool
    let hasPrev: Bool
}

// MARK: - IncidentFilters

struct IncidentFilters: Equatable {
    var status: IncidentStatus?
    var hazardType: HazardType?
    var urgency: UrgencyLevel?
    var searchQuery: String?
    var page: Int
    var size: Int

    init(
        status: IncidentStatus? = nil,
        hazardType: HazardType? = nil,
        urgency: UrgencyLevel? = nil,
        searchQuery: String? = nil,
        page: Int = 1,
        size: Int = 20
    ) {
        self.status = status
        self.hazardType = hazardType
        self.urgency = urgency
        self.searchQuery = searchQuery
        self.page = page
        self.size = size
    }
}
