import Foundation

// MARK: - Incident DTOs

struct IncidentDTO: Codable {
    let id: Int
    let referenceId: String
    let hazardType: String
    let location: String
    let latitude: Double?
    let longitude: Double?
    let description: String
    let urgency: String
    let status: String
    let reporterId: Int
    let verifiedById: Int?
    let photoUrl: String?
    let contactInfo: String?
    let createdAt: String
    let updatedAt: String?
    let verifiedAt: String?
    let resolvedAt: String?
    let assignedToId: Int?
    let assignedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case referenceId = "reference_id"
        case hazardType = "hazard_type"
        case location, latitude, longitude, description, urgency, status
        case reporterId = "reporter_id"
        case verifiedById = "verified_by_id"
        case photoUrl = "photo_url"
        case contactInfo = "contact_info"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case verifiedAt = "verified_at"
        case resolvedAt = "resolved_at"
        case assignedToId = "assigned_to_id"
        case assignedAt = "assigned_at"
    }
    
    func toDomain() -> Incident {
        Incident(
            id: id,
            referenceId: referenceId,
            hazardType: HazardType.fromValue(hazardType),
            location: location,
            latitude: latitude,
            longitude: longitude,
            description: description,
            urgency: UrgencyLevel.fromValue(urgency),
            status: IncidentStatus.fromValue(status),
            reporterId: reporterId,
            verifiedById: verifiedById,
            photoUrl: photoUrl,
            contactInfo: contactInfo,
            createdAt: createdAt.parseISO8601() ?? Date(),
            updatedAt: updatedAt?.parseISO8601(),
            verifiedAt: verifiedAt?.parseISO8601(),
            resolvedAt: resolvedAt?.parseISO8601(),
            assignedToId: assignedToId,
            assignedAt: assignedAt?.parseISO8601()
        )
    }
}

struct IncidentListResponseDTO: Codable {
    let incidents: [IncidentDTO]
    let total: Int
    let page: Int
    let size: Int
    let hasNext: Bool
    let hasPrev: Bool
    
    enum CodingKeys: String, CodingKey {
        case incidents, total, page, size
        case hasNext = "has_next"
        case hasPrev = "has_prev"
    }
    
    func toDomain() -> IncidentListResult {
        IncidentListResult(
            incidents: incidents.map { $0.toDomain() },
            total: total,
            page: page,
            size: size,
            hasNext: hasNext,
            hasPrev: hasPrev
        )
    }
}

struct CreateIncidentRequestDTO: Codable {
    let hazardType: String
    let location: String
    let latitude: Double?
    let longitude: Double?
    let description: String
    let urgency: String
    let contactInfo: String?
    let meshMessageId: String?
    
    enum CodingKeys: String, CodingKey {
        case hazardType = "hazard_type"
        case location, latitude, longitude, description, urgency
        case contactInfo = "contact_info"
        case meshMessageId = "mesh_message_id"
    }
    
    static func fromDomain(_ request: CreateIncidentRequest) -> CreateIncidentRequestDTO {
        CreateIncidentRequestDTO(
            hazardType: request.hazardType.rawValue,
            location: request.location,
            latitude: request.latitude,
            longitude: request.longitude,
            description: request.description,
            urgency: request.urgency.rawValue,
            contactInfo: request.contactInfo,
            meshMessageId: nil
        )
    }
}

struct MessageResponseDTO: Codable {
    let message: String
}

struct MeshCheckRequestDTO: Codable {
    let messageIds: [String]
    
    enum CodingKeys: String, CodingKey {
        case messageIds = "message_ids"
    }
}

struct MeshCheckResponseDTO: Codable {
    let delivered: [String]
    let unknown: [String]
}

// MARK: - Date Parsing Helper

extension String {
    func parseISO8601() -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: self) { return date }
        
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: self) { return date }
        
        // Fallback: remove trailing Z and parse as local
        let cleaned = self.replacingOccurrences(of: "Z", with: "")
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df.date(from: cleaned)
    }
}
