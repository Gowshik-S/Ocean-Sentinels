import Foundation

/// Repository protocol for incident management operations.
protocol IncidentRepository {

    /// Fetches a paginated, filtered list of incidents.
    func getIncidents(filters: IncidentFilters) async throws -> IncidentListResult

    /// Fetches a single incident by its ID.
    func getIncident(id: Int) async throws -> Incident

    /// Fetches an incident by its reference ID from cache.
    func getIncidentByReference(referenceId: String) async throws -> Incident

    /// Fetches the current user's own reports.
    func getMyReports(filters: IncidentFilters) async throws -> IncidentListResult

    /// Creates a new incident report.
    func createIncident(request: CreateIncidentRequest) async throws -> Incident

    /// Marks an incident as verified. Returns the updated incident.
    func verifyIncident(id: Int) async throws -> Incident

    /// Deploys a response to a verified incident. Returns the updated incident.
    func deployResponse(id: Int) async throws -> Incident

    /// Marks an in-progress incident as resolved. Returns the updated incident.
    func resolveIncident(id: Int) async throws -> Incident

    /// Assigns an incident to a rescue team member.
    func assignIncident(incidentId: Int, rescueTeamUserId: Int) async throws

    /// Fetches incidents assigned to the current user.
    func getAssignedIncidents(page: Int, size: Int) async throws -> IncidentListResult

    /// Returns locally cached incidents.
    func getCachedIncidents() async throws -> [Incident]

    /// Syncs local incidents with the server.
    func syncIncidents() async throws

    /// Uploads a photo for an incident.
    func uploadPhoto(imageData: Data, fileName: String) async throws -> String
}
