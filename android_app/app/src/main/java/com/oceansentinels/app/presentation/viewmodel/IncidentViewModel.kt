package com.oceansentinels.app.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.oceansentinels.app.domain.model.*
import com.oceansentinels.app.domain.repository.IncidentRepository
import com.oceansentinels.app.mesh.network.NetworkConnectivityManager
import com.oceansentinels.app.mesh.repository.MeshMessageRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

/**
 * ViewModel for incident-related operations.
 *
 * Hazard report delivery strategy (Internet-first with auto mesh fallback):
 * ─────────────────────────────────────────────────────────────────────────
 * 1. CHECK internet via NetworkConnectivityManager.isInternetAvailable()
 *    (instant cached check — no system call, no timeout)
 *
 * 2a. Internet AVAILABLE:
 *     → Try API via incidentRepository.createIncident()
 *     → On success: done (CreateIncidentState.Success)
 *     → On failure (server error, etc.): fall back to mesh
 *
 * 2b. Internet UNAVAILABLE:
 *     → Skip API entirely (avoids ~10s HTTP timeout)
 *     → Route directly to meshMessageRepository.forwardToMesh()
 *     → Message broadcast to BLE peers or queued in local DB
 *     → Auto-uploaded when internet returns (MeshForegroundService)
 *
 * Comparison with other mesh implementations:
 * ─────────────────────────────────────────────
 * • bitchat-android: ALWAYS uses mesh. No internet check, no API call.
 *   sendMessage() → signPacket() → broadcastPacket() → all peers.
 *   No fallback needed because mesh IS the primary (and only) transport.
 *
 * • bridgefy-alerts: ALWAYS uses mesh via SDK. No internet check.
 *   bridgefy.send(data, TransmissionMode.Broadcast) handles everything.
 *
 * • Ocean Sentinels (us): HYBRID. Internet when possible, mesh when not.
 *   This ViewModel is the decision point that routes between the two paths.
 *   The pre-check via NetworkConnectivityManager is what makes this instant
 *   instead of waiting for an HTTP timeout to detect offline state.
 */
@HiltViewModel
class IncidentViewModel @Inject constructor(
    private val incidentRepository: IncidentRepository,
    private val meshMessageRepository: MeshMessageRepository,
    private val networkConnectivityManager: NetworkConnectivityManager
) : ViewModel() {

    // Incidents list
    private val _incidents = MutableStateFlow<List<Incident>>(emptyList())
    val incidents: StateFlow<List<Incident>> = _incidents.asStateFlow()

    // Loading state
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    // Error state
    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    // Selected incident
    private val _selectedIncident = MutableStateFlow<Incident?>(null)
    val selectedIncident: StateFlow<Incident?> = _selectedIncident.asStateFlow()

    // Create incident state
    private val _createIncidentState = MutableStateFlow<CreateIncidentState>(CreateIncidentState.Idle)
    val createIncidentState: StateFlow<CreateIncidentState> = _createIncidentState.asStateFlow()

    // Filters
    private val _filters = MutableStateFlow(IncidentFilters())
    val filters: StateFlow<IncidentFilters> = _filters.asStateFlow()

    // Pagination
    private val _hasMorePages = MutableStateFlow(true)
    val hasMorePages: StateFlow<Boolean> = _hasMorePages.asStateFlow()

    private val _totalCount = MutableStateFlow(0)
    val totalCount: StateFlow<Int> = _totalCount.asStateFlow()

    /**
     * Load incidents with optional filters
     */
    fun loadIncidents(filters: IncidentFilters = _filters.value) {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null
            _filters.value = filters

            val result = incidentRepository.getIncidents(filters)

            result.fold(
                onSuccess = { listResult ->
                    _incidents.value = listResult.incidents
                    _hasMorePages.value = listResult.hasNext
                    _totalCount.value = listResult.total
                    Timber.d("Loaded ${listResult.incidents.size} incidents")
                },
                onFailure = { error ->
                    _error.value = error.message
                    Timber.e(error, "Failed to load incidents")
                }
            )

            _isLoading.value = false
        }
    }

    /**
     * Load more incidents (pagination)
     */
    fun loadMoreIncidents() {
        if (_isLoading.value || !_hasMorePages.value) return

        viewModelScope.launch {
            val currentFilters = _filters.value
            val nextPage = currentFilters.page + 1
            
            _isLoading.value = true

            val result = incidentRepository.getIncidents(
                currentFilters.copy(page = nextPage)
            )

            result.fold(
                onSuccess = { listResult ->
                    _incidents.value = _incidents.value + listResult.incidents
                    _hasMorePages.value = listResult.hasNext
                    _filters.value = currentFilters.copy(page = nextPage)
                },
                onFailure = { error ->
                    _error.value = error.message
                }
            )

            _isLoading.value = false
        }
    }

    /**
     * Load user's own reports
     */
    fun loadMyReports() {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null

            val result = incidentRepository.getMyReports(IncidentFilters())

            result.fold(
                onSuccess = { listResult ->
                    _incidents.value = listResult.incidents
                    _totalCount.value = listResult.total
                },
                onFailure = { error ->
                    _error.value = error.message
                }
            )

            _isLoading.value = false
        }
    }

    /**
     * Get a single incident by ID
     */
    fun getIncident(id: Int) {
        viewModelScope.launch {
            _isLoading.value = true

            val result = incidentRepository.getIncident(id)

            result.fold(
                onSuccess = { incident ->
                    _selectedIncident.value = incident
                },
                onFailure = { error ->
                    _error.value = error.message
                }
            )

            _isLoading.value = false
        }
    }

    /**
     * Create a new incident report.
     *
     * PRE-CHECKS internet availability BEFORE attempting the API call.
     * If offline, routes DIRECTLY to BLE mesh — no HTTP timeout wait.
     *
     * Previous behavior (before this fix):
     * ────────────────────────────────────
     *   createIncident(request)
     *     → incidentRepository.createIncident(request)  // HTTP API call
     *     → TIMEOUT (~10 seconds on dead connection)
     *     → catch error
     *     → meshMessageRepository.createAndSend()  // mesh fallback
     *   Total time when offline: ~10+ seconds of waiting
     *
     * New behavior (this fix):
     * ────────────────────────────────────
     *   createIncident(request)
     *     → networkConnectivityManager.isInternetAvailable()  // instant cached check
     *     → if TRUE:
     *         → incidentRepository.createIncident(request)  // HTTP API call
     *         → on failure: meshMessageRepository.forwardToMesh()  // fallback
     *     → if FALSE:
     *         → meshMessageRepository.forwardToMesh()  // direct, no timeout
     *   Total time when offline: <100ms (instant mesh routing)
     *
     * Comparison with bitchat-android:
     * ────────────────────────────────
     * bitchat doesn't need this decision at all because it's 100% mesh.
     * Every message goes through BluetoothMeshService.sendMessage() →
     * signPacketBeforeBroadcast() → connectionManager.broadcastPacket()
     * with no internet check, no API call, no timeout concern.
     *
     * Our hybrid model is more complex but provides server-side
     * aggregation, map visualization, and cross-region visibility
     * that pure mesh cannot offer.
     */
    fun createIncident(request: CreateIncidentRequest) {
        viewModelScope.launch {
            _createIncidentState.value = CreateIncidentState.Loading

            // ── Step 1: Pre-check internet (instant, cached) ──
            // Uses NetworkConnectivityManager's AtomicBoolean — no system call,
            // no suspend, O(1) read. Updated in real-time by NetworkCallback.
            val hasInternet = networkConnectivityManager.isInternetAvailable()
            Timber.d("Internet pre-check: available=$hasInternet")

            if (hasInternet) {
                // ── Step 2a: Internet available → try API first ──
                val result = incidentRepository.createIncident(request)

                result.fold(
                    onSuccess = { incident ->
                        _createIncidentState.value = CreateIncidentState.Success(incident)
                        Timber.d("Incident created via internet: ${incident.referenceId}")
                    },
                    onFailure = { error ->
                        // API call failed despite having internet (server error,
                        // captive portal, etc.) — fall back to mesh
                        Timber.w(error, "Internet available but API failed, auto-forwarding to mesh")
                        autoForwardToMesh(request, error)
                    }
                )
            } else {
                // ── Step 2b: No internet → skip API, go straight to mesh ──
                // This is the KEY improvement: instead of waiting ~10s for
                // an HTTP timeout, we route immediately to the mesh network.
                //
                // Similar to how bitchat-android ALWAYS goes to mesh:
                //   BluetoothMeshService.sendMessage() → broadcastPacket()
                // But we only take this path when internet is confirmed down.
                Timber.i("No internet detected — auto-forwarding hazard report to mesh network")
                autoForwardToMesh(request, null)
            }
        }
    }

    /**
     * Auto-forward a hazard report to the BLE mesh network.
     *
     * Called in two scenarios:
     * 1. Internet is unavailable (pre-check failed) → originalError = null
     * 2. Internet available but API call failed → originalError = the exception
     *
     * Uses meshMessageRepository.forwardToMesh() which:
     * - Persists to Room DB (crash-safe, unlike bitchat's in-memory StoreForwardManager)
     * - Broadcasts to all connected BLE peers via BleMeshManager
     * - Queues PENDING if no peers are connected
     * - MeshForegroundService auto-retries every 15s and auto-uploads when internet returns
     *
     * The message follows the same relay chain as bitchat's PacketRelayManager:
     * each receiving peer adds itself to relayPath and re-broadcasts to its own
     * peers (flood routing). Unlike bitchat's hop-based TTL=7, Ocean Sentinels
     * uses time-based expiry (72 hours) so hazard reports survive across any
     * number of hops until reaching a server. Bitchat adds adaptive relay
     * probability (40-100% based on network size); we always flood because
     * hazard reports are high-priority safety data where delivery matters more
     * than bandwidth.
     */
    private suspend fun autoForwardToMesh(
        request: CreateIncidentRequest,
        originalError: Throwable?
    ) {
        try {
            val meshResult = meshMessageRepository.forwardToMesh(
                hazardType = request.hazardType,
                location = request.location,
                latitude = request.latitude,
                longitude = request.longitude,
                description = request.description,
                urgency = request.urgency,
                contactInfo = request.contactInfo,
                photoUrl = request.photoUrl,
                reporterUserId = null
            )
            meshResult.fold(
                onSuccess = { meshMessage ->
                    val statusDesc = when (meshMessage.status) {
                        com.oceansentinels.app.mesh.model.MeshMessageStatus.RELAYED ->
                            "relayed to ${meshMessage.hopCount} peer(s)"
                        com.oceansentinels.app.mesh.model.MeshMessageStatus.PENDING ->
                            "queued locally, waiting for mesh peers"
                        else -> meshMessage.status.value
                    }
                    _createIncidentState.value = CreateIncidentState.MeshFallbackSuccess(
                        "Report auto-forwarded via mesh network ($statusDesc). " +
                        "It will be delivered to the server when internet is available."
                    )
                    Timber.i("Hazard report auto-forwarded to mesh: ${meshMessage.messageId} [$statusDesc]")
                },
                onFailure = { meshError ->
                    _createIncidentState.value = CreateIncidentState.Error(
                        originalError?.message ?: meshError.message ?: "Failed to create incident"
                    )
                    Timber.e(meshError, "Mesh auto-forward also failed")
                }
            )
        } catch (e: Exception) {
            _createIncidentState.value = CreateIncidentState.Error(
                originalError?.message ?: e.message ?: "Failed to create incident"
            )
            Timber.e(e, "Mesh auto-forward exception")
        }
    }

    /**
     * Verify an incident
     */
    fun verifyIncident(id: Int) {
        viewModelScope.launch {
            _isLoading.value = true

            val result = incidentRepository.verifyIncident(id)

            result.fold(
                onSuccess = { incident ->
                    updateIncidentInList(incident)
                    _selectedIncident.value = incident
                },
                onFailure = { error ->
                    _error.value = error.message
                }
            )

            _isLoading.value = false
        }
    }

    /**
     * Deploy response to an incident
     */
    fun deployResponse(id: Int) {
        viewModelScope.launch {
            _isLoading.value = true

            val result = incidentRepository.deployResponse(id)

            result.fold(
                onSuccess = { incident ->
                    updateIncidentInList(incident)
                    _selectedIncident.value = incident
                },
                onFailure = { error ->
                    _error.value = error.message
                }
            )

            _isLoading.value = false
        }
    }

    /**
     * Resolve an incident
     */
    fun resolveIncident(id: Int) {
        viewModelScope.launch {
            _isLoading.value = true

            val result = incidentRepository.resolveIncident(id)

            result.fold(
                onSuccess = { incident ->
                    updateIncidentInList(incident)
                    _selectedIncident.value = incident
                },
                onFailure = { error ->
                    _error.value = error.message
                }
            )

            _isLoading.value = false
        }
    }

    /**
     * Update filters
     */
    fun updateFilters(
        status: IncidentStatus? = _filters.value.status,
        hazardType: HazardType? = _filters.value.hazardType,
        urgency: UrgencyLevel? = _filters.value.urgency,
        searchQuery: String? = _filters.value.searchQuery
    ) {
        val newFilters = _filters.value.copy(
            status = status,
            hazardType = hazardType,
            urgency = urgency,
            searchQuery = searchQuery,
            page = 1
        )
        loadIncidents(newFilters)
    }

    /**
     * Clear filters
     */
    fun clearFilters() {
        loadIncidents(IncidentFilters())
    }

    /**
     * Clear error
     */
    fun clearError() {
        _error.value = null
    }

    /**
     * Reset create incident state
     */
    fun resetCreateState() {
        _createIncidentState.value = CreateIncidentState.Idle
    }

    /**
     * Clear selected incident
     */
    fun clearSelectedIncident() {
        _selectedIncident.value = null
    }

    private fun updateIncidentInList(updatedIncident: Incident) {
        _incidents.value = _incidents.value.map { 
            if (it.id == updatedIncident.id) updatedIncident else it 
        }
    }
    
    // ============= Assignment Operations =============
    
    private val _assignState = MutableStateFlow<AssignState>(AssignState.Idle)
    val assignState: StateFlow<AssignState> = _assignState.asStateFlow()
    
    private val _assignedIncidents = MutableStateFlow<List<Incident>>(emptyList())
    val assignedIncidents: StateFlow<List<Incident>> = _assignedIncidents.asStateFlow()
    
    /**
     * Assign an incident to a rescue team member
     */
    fun assignIncident(incidentId: Int, rescueTeamUserId: Int) {
        viewModelScope.launch {
            _assignState.value = AssignState.Loading
            
            incidentRepository.assignIncident(incidentId, rescueTeamUserId).fold(
                onSuccess = {
                    _assignState.value = AssignState.Success
                    // Reload incidents to reflect the change
                    loadIncidents()
                },
                onFailure = { error ->
                    _assignState.value = AssignState.Error(error.message ?: "Assignment failed")
                }
            )
        }
    }
    
    /**
     * Load incidents assigned to the current rescue team member
     */
    fun loadAssignedIncidents() {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null
            
            incidentRepository.getAssignedIncidents().fold(
                onSuccess = { result ->
                    _assignedIncidents.value = result.incidents
                    Timber.d("Loaded ${result.incidents.size} assigned incidents")
                },
                onFailure = { error ->
                    _error.value = error.message
                    Timber.e(error, "Failed to load assigned incidents")
                }
            )
            
            _isLoading.value = false
        }
    }
    
    fun resetAssignState() {
        _assignState.value = AssignState.Idle
    }
}

/**
 * Create incident state
 */
sealed class CreateIncidentState {
    data object Idle : CreateIncidentState()
    data object Loading : CreateIncidentState()
    data class Success(val incident: Incident) : CreateIncidentState()
    /** Report sent via BLE mesh because internet was unavailable */
    data class MeshFallbackSuccess(val message: String) : CreateIncidentState()
    data class Error(val message: String) : CreateIncidentState()
}

/**
 * Assign incident state
 */
sealed class AssignState {
    data object Idle : AssignState()
    data object Loading : AssignState()
    data object Success : AssignState()
    data class Error(val message: String) : AssignState()
}
