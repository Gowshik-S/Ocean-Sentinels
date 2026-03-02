import Foundation
import Observation

// MARK: - IncidentViewModel

/// ViewModel for incident-related operations.
///
/// Hazard report delivery strategy (Internet-first with auto mesh fallback):
/// ─────────────────────────────────────────────────────────────────────────
/// 1. CHECK internet via `NetworkConnectivityManager.isOnline`
///    (instant cached check — no system call, no timeout)
///
/// 2a. Internet AVAILABLE:
///     → Try API via `incidentRepository.createIncident()`
///     → On success: done (CreateIncidentState.success)
///     → On failure (server error, etc.): fall back to mesh
///
/// 2b. Internet UNAVAILABLE:
///     → Skip API entirely (avoids ~10s HTTP timeout)
///     → Route directly to `meshMessageRepository.forwardToMesh()`
///     → Message broadcast to BLE peers or queued in local DB
///     → Auto-uploaded when internet returns (MeshBackgroundService)
@Observable
@MainActor
final class IncidentViewModel {

    // MARK: - State

    var incidents: [Incident] = []
    var isLoading: Bool = false
    var error: String?
    var selectedIncident: Incident?
    var createIncidentState: CreateIncidentState = .idle
    var filters: IncidentFilters = IncidentFilters()
    var hasMorePages: Bool = true
    var totalCount: Int = 0

    // Assignment
    var assignState: AssignState = .idle
    var assignedIncidents: [Incident] = []

    // MARK: - Dependencies

    private let incidentRepository: IncidentRepository
    private let meshMessageRepository: MeshMessageRepository
    private let networkConnectivityManager: NetworkConnectivityManager

    // MARK: - Init

    init(
        incidentRepository: IncidentRepository,
        meshMessageRepository: MeshMessageRepository,
        networkConnectivityManager: NetworkConnectivityManager
    ) {
        self.incidentRepository = incidentRepository
        self.meshMessageRepository = meshMessageRepository
        self.networkConnectivityManager = networkConnectivityManager
    }

    // MARK: - Load Incidents

    /// Load incidents with optional filters.
    func loadIncidents(filters: IncidentFilters? = nil) {
        let activeFilters = filters ?? self.filters
        Task {
            isLoading = true
            error = nil
            self.filters = activeFilters

            do {
                let result = try await incidentRepository.getIncidents(filters: activeFilters)
                incidents = result.incidents
                hasMorePages = result.hasNext
                totalCount = result.total
                AppLogger.incidents.debug("Loaded \(result.incidents.count) incidents")
            } catch {
                self.error = error.localizedDescription
                AppLogger.incidents.error("Failed to load incidents: \(error.localizedDescription)")
            }

            isLoading = false
        }
    }

    /// Load more incidents (pagination).
    func loadMoreIncidents() {
        guard !isLoading, hasMorePages else { return }

        Task {
            let currentFilters = filters
            let nextPage = currentFilters.page + 1
            isLoading = true

            do {
                let result = try await incidentRepository.getIncidents(
                    filters: currentFilters.withPage(nextPage)
                )
                incidents += result.incidents
                hasMorePages = result.hasNext
                filters = currentFilters.withPage(nextPage)
            } catch {
                self.error = error.localizedDescription
            }

            isLoading = false
        }
    }

    /// Load user's own reports.
    func loadMyReports() {
        Task {
            isLoading = true
            error = nil

            do {
                let result = try await incidentRepository.getMyReports(filters: IncidentFilters())
                incidents = result.incidents
                totalCount = result.total
            } catch {
                self.error = error.localizedDescription
            }

            isLoading = false
        }
    }

    /// Get a single incident by ID.
    func getIncident(id: Int) {
        Task {
            isLoading = true

            do {
                let incident = try await incidentRepository.getIncident(id: id)
                selectedIncident = incident
            } catch {
                self.error = error.localizedDescription
            }

            isLoading = false
        }
    }

    // MARK: - Create Incident (Hybrid Internet/Mesh)

    /// Create a new incident report.
    ///
    /// PRE-CHECKS internet availability BEFORE attempting the API call.
    /// If offline, routes DIRECTLY to BLE mesh — no HTTP timeout wait.
    func createIncident(request: CreateIncidentRequest) {
        Task {
            createIncidentState = .loading

            // Step 1: Pre-check internet (instant, cached via NWPathMonitor)
            let hasInternet = networkConnectivityManager.isOnline
            AppLogger.incidents.debug("Internet pre-check: available=\(hasInternet)")

            if hasInternet {
                // Step 2a: Internet available → try API first
                do {
                    let incident = try await incidentRepository.createIncident(request: request)
                    createIncidentState = .success(incident)
                    AppLogger.incidents.debug("Incident created via internet: \(incident.referenceId)")
                } catch {
                    // API call failed despite having internet → fall back to mesh
                    AppLogger.incidents.warning("Internet available but API failed, auto-forwarding to mesh")
                    await autoForwardToMesh(request: request, originalError: error)
                }
            } else {
                // Step 2b: No internet → skip API, go straight to mesh
                AppLogger.incidents.info("No internet detected — auto-forwarding hazard report to mesh network")
                await autoForwardToMesh(request: request, originalError: nil)
            }
        }
    }

    /// Auto-forward a hazard report to the BLE mesh network.
    ///
    /// Called when:
    /// 1. Internet is unavailable (pre-check failed) → `originalError = nil`
    /// 2. Internet available but API call failed → `originalError = the exception`
    private func autoForwardToMesh(request: CreateIncidentRequest, originalError: Error?) async {
        let result = await meshMessageRepository.forwardToMesh(
            hazardType: request.hazardType,
            location: request.location,
            latitude: request.latitude,
            longitude: request.longitude,
            description: request.description,
            urgency: request.urgency,
            contactInfo: request.contactInfo,
            photoUrl: request.photoUrl,
            reporterUserId: nil
        )

        switch result {
        case .success(let meshMessage):
            let statusDesc: String = switch meshMessage.status {
            case .relayed:
                "relayed to \(meshMessage.hopCount) peer(s)"
            case .pending:
                "queued locally, waiting for mesh peers"
            default:
                meshMessage.status.rawValue
            }

            createIncidentState = .meshFallbackSuccess(
                "Report auto-forwarded via mesh network (\(statusDesc)). " +
                "It will be delivered to the server when internet is available."
            )
            AppLogger.incidents.info("Hazard report auto-forwarded to mesh: \(meshMessage.messageId) [\(statusDesc)]")

        case .failure(let error):
            createIncidentState = .error(
                originalError?.localizedDescription ?? error.localizedDescription
            )
            AppLogger.incidents.error("Mesh auto-forward failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Incident Status Actions

    /// Verify an incident.
    func verifyIncident(id: Int) {
        Task {
            isLoading = true

            do {
                let incident = try await incidentRepository.verifyIncident(id: id)
                updateIncidentInList(incident)
                selectedIncident = incident
            } catch {
                self.error = error.localizedDescription
            }

            isLoading = false
        }
    }

    /// Deploy response to an incident.
    func deployResponse(id: Int) {
        Task {
            isLoading = true

            do {
                let incident = try await incidentRepository.deployResponse(id: id)
                updateIncidentInList(incident)
                selectedIncident = incident
            } catch {
                self.error = error.localizedDescription
            }

            isLoading = false
        }
    }

    /// Resolve an incident.
    func resolveIncident(id: Int) {
        Task {
            isLoading = true

            do {
                let incident = try await incidentRepository.resolveIncident(id: id)
                updateIncidentInList(incident)
                selectedIncident = incident
            } catch {
                self.error = error.localizedDescription
            }

            isLoading = false
        }
    }

    // MARK: - Filters

    func updateFilters(
        status: IncidentStatus? = nil,
        hazardType: HazardType? = nil,
        urgency: UrgencyLevel? = nil,
        searchQuery: String? = nil
    ) {
        let newFilters = IncidentFilters(
            status: status ?? filters.status,
            hazardType: hazardType ?? filters.hazardType,
            urgency: urgency ?? filters.urgency,
            searchQuery: searchQuery ?? filters.searchQuery,
            page: 1,
            size: filters.size
        )
        loadIncidents(filters: newFilters)
    }

    func clearFilters() {
        loadIncidents(filters: IncidentFilters())
    }

    // MARK: - Assignment Operations

    /// Assign an incident to a rescue team member.
    func assignIncident(incidentId: Int, rescueTeamUserId: Int) {
        Task {
            assignState = .loading

            do {
                try await incidentRepository.assignIncident(incidentId: incidentId, rescueTeamUserId: rescueTeamUserId)
                assignState = .success
                loadIncidents()
            } catch {
                assignState = .error(error.localizedDescription)
            }
        }
    }

    /// Load incidents assigned to the current rescue team member.
    func loadAssignedIncidents() {
        Task {
            isLoading = true
            error = nil

            do {
                let result = try await incidentRepository.getAssignedIncidents(page: 1, size: 50)
                assignedIncidents = result.incidents
                AppLogger.incidents.debug("Loaded \(result.incidents.count) assigned incidents")
            } catch {
                self.error = error.localizedDescription
                AppLogger.incidents.error("Failed to load assigned incidents: \(error.localizedDescription)")
            }

            isLoading = false
        }
    }

    // MARK: - State Resets

    func clearError() { error = nil }
    func resetCreateState() { createIncidentState = .idle }
    func clearSelectedIncident() { selectedIncident = nil }
    func resetAssignState() { assignState = .idle }

    // MARK: - Helpers

    private func updateIncidentInList(_ updatedIncident: Incident) {
        incidents = incidents.map { $0.id == updatedIncident.id ? updatedIncident : $0 }
    }
}

// MARK: - Create Incident State

enum CreateIncidentState: Equatable {
    case idle
    case loading
    case success(Incident)
    /// Report sent via BLE mesh because internet was unavailable.
    case meshFallbackSuccess(String)
    case error(String)

    static func == (lhs: CreateIncidentState, rhs: CreateIncidentState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading): return true
        case (.success(let a), .success(let b)): return a.id == b.id
        case (.meshFallbackSuccess(let a), .meshFallbackSuccess(let b)): return a == b
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}

// MARK: - Assign State

enum AssignState: Equatable {
    case idle
    case loading
    case success
    case error(String)
}

// MARK: - IncidentFilters Extension

extension IncidentFilters {
    func withPage(_ page: Int) -> IncidentFilters {
        IncidentFilters(
            status: status,
            hazardType: hazardType,
            urgency: urgency,
            searchQuery: searchQuery,
            page: page,
            size: size
        )
    }
}
