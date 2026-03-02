import Foundation

// MARK: - Ocean Sentinels API Service

/// Replaces Retrofit OceanSentinelsApi interface with URLSession-based async service.
final class OceanSentinelsAPI {
    
    private let client: NetworkClient
    private let baseURL: URL
    
    init(client: NetworkClient = .shared) {
        self.client = client
        guard let url = URL(string: AppConfig.baseURL) else {
            fatalError("Invalid base URL: \(AppConfig.baseURL)")
        }
        self.baseURL = url
    }
    
    private func url(_ path: String, queryItems: [URLQueryItem]? = nil) -> URL {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if let items = queryItems?.filter({ $0.value != nil }) {
            components.queryItems = items.isEmpty ? nil : items
        }
        return components.url!
    }
    
    // MARK: - Authentication
    
    func login(username: String, password: String) async throws -> AuthResponseDTO {
        try await client.requestFormEncoded(
            url: url("auth/login"),
            formFields: ["username": username, "password": password],
            requiresAuth: false
        )
    }
    
    func register(request: RegisterRequestDTO) async throws -> AuthResponseDTO {
        try await client.request(
            url: url("auth/register"),
            method: "POST",
            body: request,
            requiresAuth: false
        )
    }
    
    // MARK: - Users
    
    func getCurrentUser() async throws -> UserDTO {
        try await client.request(url: url("users/me"))
    }
    
    func updateCurrentUser(request: UserUpdateRequestDTO) async throws -> UserDTO {
        try await client.request(url: url("users/me"), method: "PUT", body: request)
    }
    
    func getAllUsers() async throws -> [UserDTO] {
        try await client.request(url: url("users/"))
    }
    
    func getUser(id: Int) async throws -> UserDTO {
        try await client.request(url: url("users/\(id)"))
    }
    
    func deleteUser(id: Int) async throws {
        try await client.requestVoid(url: url("users/\(id)"), method: "DELETE")
    }
    
    func adminCreateUser(request: RegisterRequestDTO) async throws -> UserDTO {
        try await client.request(url: url("users/create"), method: "POST", body: request)
    }
    
    // MARK: - Incidents
    
    func getIncidents(
        page: Int = 1,
        size: Int = 20,
        status: String? = nil,
        hazardType: String? = nil,
        urgency: String? = nil,
        search: String? = nil
    ) async throws -> IncidentListResponseDTO {
        let queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "size", value: "\(size)"),
            URLQueryItem(name: "status", value: status),
            URLQueryItem(name: "hazard_type", value: hazardType),
            URLQueryItem(name: "urgency", value: urgency),
            URLQueryItem(name: "search", value: search)
        ]
        return try await client.request(url: url("incidents/", queryItems: queryItems))
    }
    
    func getIncident(id: Int) async throws -> IncidentDTO {
        try await client.request(url: url("incidents/\(id)"))
    }
    
    func createIncident(request: CreateIncidentRequestDTO) async throws -> IncidentDTO {
        try await client.request(url: url("incidents/"), method: "POST", body: request)
    }
    
    func checkMeshMessages(request: MeshCheckRequestDTO) async throws -> MeshCheckResponseDTO {
        try await client.request(url: url("incidents/mesh/check"), method: "POST", body: request)
    }
    
    func verifyIncident(id: Int) async throws -> MessageResponseDTO {
        try await client.request(url: url("incidents/\(id)/verify"), method: "PUT")
    }
    
    func deployResponse(id: Int) async throws -> MessageResponseDTO {
        try await client.request(url: url("incidents/\(id)/deploy"), method: "PUT")
    }
    
    func resolveIncident(id: Int) async throws -> MessageResponseDTO {
        try await client.request(url: url("incidents/\(id)/resolve"), method: "PUT")
    }
    
    func assignIncident(id: Int, userId: Int) async throws -> MessageResponseDTO {
        try await client.request(
            url: url("incidents/\(id)/assign"),
            method: "PUT",
            body: ["assigned_to_id": userId]
        )
    }
    
    func getMyAssignedIncidents(page: Int = 1, size: Int = 20) async throws -> IncidentListResponseDTO {
        let queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "size", value: "\(size)")
        ]
        return try await client.request(url: url("incidents/assigned/me", queryItems: queryItems))
    }
    
    // MARK: - Analytics
    
    func getDashboardAnalytics() async throws -> DashboardAnalyticsDTO {
        try await client.request(url: url("analytics/dashboard"))
    }
    
    func getIncidentsTimeline(days: Int = 30) async throws -> IncidentsTimelineDTO {
        let queryItems = [URLQueryItem(name: "days", value: "\(days)")]
        return try await client.request(url: url("analytics/incidents/timeline", queryItems: queryItems))
    }
    
    func getIncidentsDistribution() async throws -> IncidentsDistributionDTO {
        try await client.request(url: url("analytics/incidents/distribution"))
    }
    
    func getGeographicAnalytics() async throws -> GeographicAnalyticsDTO {
        try await client.request(url: url("analytics/geographic"))
    }
    
    // MARK: - File Upload
    
    func uploadIncidentPhoto(imageData: Data, fileName: String) async throws -> UploadResponseDTO {
        try await client.uploadMultipart(
            url: url("upload/incident-photo"),
            fileData: imageData,
            fileName: fileName,
            mimeType: "image/jpeg"
        )
    }
}
