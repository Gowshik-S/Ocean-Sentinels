import Foundation
import SwiftData

/// SwiftData entity for offline incident caching.
/// Replaces Room IncidentEntity + IncidentDao.
@Model
final class IncidentEntity {
    @Attribute(.unique) var id: Int
    var referenceId: String
    var hazardType: String
    var location: String
    var latitude: Double?
    var longitude: Double?
    var descriptionText: String // 'description' is a reserved keyword in SwiftData context
    var urgency: String
    var status: String
    var reporterId: Int
    var verifiedById: Int?
    var photoUrl: String?
    var contactInfo: String?
    var createdAt: Date
    var updatedAt: Date?
    var verifiedAt: Date?
    var resolvedAt: Date?
    var assignedToId: Int?
    var assignedAt: Date?
    var cachedAt: Date
    var isPendingSync: Bool
    
    init(
        id: Int,
        referenceId: String,
        hazardType: String,
        location: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        descriptionText: String,
        urgency: String,
        status: String,
        reporterId: Int,
        verifiedById: Int? = nil,
        photoUrl: String? = nil,
        contactInfo: String? = nil,
        createdAt: Date,
        updatedAt: Date? = nil,
        verifiedAt: Date? = nil,
        resolvedAt: Date? = nil,
        assignedToId: Int? = nil,
        assignedAt: Date? = nil,
        cachedAt: Date = Date(),
        isPendingSync: Bool = false
    ) {
        self.id = id
        self.referenceId = referenceId
        self.hazardType = hazardType
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.descriptionText = descriptionText
        self.urgency = urgency
        self.status = status
        self.reporterId = reporterId
        self.verifiedById = verifiedById
        self.photoUrl = photoUrl
        self.contactInfo = contactInfo
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.verifiedAt = verifiedAt
        self.resolvedAt = resolvedAt
        self.assignedToId = assignedToId
        self.assignedAt = assignedAt
        self.cachedAt = cachedAt
        self.isPendingSync = isPendingSync
    }
    
    func toDomain() -> Incident {
        Incident(
            id: id,
            referenceId: referenceId,
            hazardType: HazardType.fromValue(hazardType),
            location: location,
            latitude: latitude,
            longitude: longitude,
            description: descriptionText,
            urgency: UrgencyLevel.fromValue(urgency),
            status: IncidentStatus.fromValue(status),
            reporterId: reporterId,
            verifiedById: verifiedById,
            photoUrl: photoUrl,
            contactInfo: contactInfo,
            createdAt: createdAt,
            updatedAt: updatedAt,
            verifiedAt: verifiedAt,
            resolvedAt: resolvedAt,
            assignedToId: assignedToId,
            assignedAt: assignedAt
        )
    }
    
    static func fromDomain(_ incident: Incident, isPendingSync: Bool = false) -> IncidentEntity {
        IncidentEntity(
            id: incident.id,
            referenceId: incident.referenceId,
            hazardType: incident.hazardType.value,
            location: incident.location,
            latitude: incident.latitude,
            longitude: incident.longitude,
            descriptionText: incident.description,
            urgency: incident.urgency.value,
            status: incident.status.value,
            reporterId: incident.reporterId,
            verifiedById: incident.verifiedById,
            photoUrl: incident.photoUrl,
            contactInfo: incident.contactInfo,
            createdAt: incident.createdAt,
            updatedAt: incident.updatedAt,
            verifiedAt: incident.verifiedAt,
            resolvedAt: incident.resolvedAt,
            assignedToId: incident.assignedToId,
            assignedAt: incident.assignedAt,
            isPendingSync: isPendingSync
        )
    }
}
