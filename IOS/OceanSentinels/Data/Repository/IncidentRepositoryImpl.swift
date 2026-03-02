import Foundation
import os

/// Implementation of IncidentRepository.
/// Replaces Kotlin IncidentRepositoryImpl with URLSession + SwiftData caching.
final class IncidentRepositoryImpl: IncidentRepository {
    
    private let api: OceanSentinelsAPI
    private let database: DatabaseManager
    private let logger = Logger(subsystem: "com.oceansentinels.app", category: "IncidentRepo")
    
    init(api: OceanSentinelsAPI, database: DatabaseManager) {
        self.api = api
        self.database = database
    }
    
    func getIncidents(filters: IncidentFilters) async throws -> IncidentListResult {
        logger.debug("Fetching incidents with filters")
        
        do {
            let response = try await api.getIncidents(
                page: filters.page,
                size: filters.size,
                status: filters.status?.value,
                hazardType: filters.hazardType?.value,
                urgency: filters.urgency?.value,
                search: filters.searchQuery
            )
            
            let result = response.toDomain()
            
            // Cache incidents
            let entities = result.incidents.map { IncidentEntity.fromDomain($0) }
            try await database.insertIncidents(entities)
            
            logger.debug("Fetched \(result.incidents.count) incidents")
            return result
        } catch {
            logger.error("Error fetching incidents: \(error)")
            // Try to return cached data
            let cached = try await getCachedIncidents()
            if !cached.isEmpty {
                return IncidentListResult(
                    incidents: cached,
                    total: cached.count,
                    page: 1,
                    size: cached.count,
                    hasNext: false,
                    hasPrev: false
                )
            }
            throw error
        }
    }
    
    func getIncident(id: Int) async throws -> Incident {
        do {
            let dto = try await api.getIncident(id: id)
            let incident = dto.toDomain()
            try await database.insertIncident(IncidentEntity.fromDomain(incident))
            return incident
        } catch {
            // Try cache
            if let cached = try await database.fetchIncident(byId: id) {
                return cached.toDomain()
            }
            throw error
        }
    }
    
    func getIncidentByReference(referenceId: String) async throws -> Incident {
        if let cached = try await database.fetchIncident(byReferenceId: referenceId) {
            return cached.toDomain()
        }
        throw NSError(domain: "IncidentRepo", code: 404, userInfo: [NSLocalizedDescriptionKey: "Incident not found"])
    }
    
    func getMyReports(filters: IncidentFilters) async throws -> IncidentListResult {
        // API filters by user automatically based on auth token
        try await getIncidents(filters: filters)
    }
    
    func createIncident(request: CreateIncidentRequest) async throws -> Incident {
        logger.debug("Creating new incident: \(request.hazardType.rawValue)")
        
        let dto = CreateIncidentRequestDTO.fromDomain(request)
        let responseDTO = try await api.createIncident(request: dto)
        let incident = responseDTO.toDomain()
        
        try await database.insertIncident(IncidentEntity.fromDomain(incident))
        
        logger.debug("Incident created successfully: \(incident.referenceId)")
        return incident
    }
    
    func verifyIncident(id: Int) async throws -> Incident {
        logger.debug("Verifying incident: \(id)")
        _ = try await api.verifyIncident(id: id)
        return try await getIncident(id: id)
    }
    
    func deployResponse(id: Int) async throws -> Incident {
        logger.debug("Deploying response to incident: \(id)")
        _ = try await api.deployResponse(id: id)
        return try await getIncident(id: id)
    }
    
    func resolveIncident(id: Int) async throws -> Incident {
        logger.debug("Resolving incident: \(id)")
        _ = try await api.resolveIncident(id: id)
        return try await getIncident(id: id)
    }
    
    func assignIncident(incidentId: Int, rescueTeamUserId: Int) async throws {
        logger.debug("Assigning incident \(incidentId) to user \(rescueTeamUserId)")
        _ = try await api.assignIncident(id: incidentId, userId: rescueTeamUserId)
    }
    
    func getAssignedIncidents(page: Int, size: Int) async throws -> IncidentListResult {
        logger.debug("Fetching assigned incidents page=\(page)")
        let response = try await api.getMyAssignedIncidents(page: page, size: size)
        return response.toDomain()
    }
    
    func getCachedIncidents() async throws -> [Incident] {
        try await database.fetchAllIncidents().map { $0.toDomain() }
    }
    
    func syncIncidents() async throws {
        let pendingIncidents = try await database.fetchPendingSyncIncidents()
        for entity in pendingIncidents {
            logger.debug("Syncing incident: \(entity.referenceId)")
        }
        // Refresh from server
        _ = try await getIncidents(filters: IncidentFilters())
    }
    
    func uploadPhoto(imageData: Data, fileName: String) async throws -> String {
        let response = try await api.uploadIncidentPhoto(imageData: imageData, fileName: fileName)
        return response.url
    }
}
