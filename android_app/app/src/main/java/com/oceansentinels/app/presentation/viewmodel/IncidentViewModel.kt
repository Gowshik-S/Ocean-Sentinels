package com.oceansentinels.app.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.oceansentinels.app.domain.model.*
import com.oceansentinels.app.domain.repository.IncidentRepository
import com.oceansentinels.app.mesh.repository.MeshMessageRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

/**
 * ViewModel for incident-related operations
 */
@HiltViewModel
class IncidentViewModel @Inject constructor(
    private val incidentRepository: IncidentRepository,
    private val meshMessageRepository: MeshMessageRepository
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
     * Tries internet first; on failure, auto-forwards to BLE mesh service.
     */
    fun createIncident(request: CreateIncidentRequest) {
        viewModelScope.launch {
            _createIncidentState.value = CreateIncidentState.Loading

            val result = incidentRepository.createIncident(request)

            result.fold(
                onSuccess = { incident ->
                    _createIncidentState.value = CreateIncidentState.Success(incident)
                    Timber.d("Incident created via internet: ${incident.referenceId}")
                },
                onFailure = { error ->
                    Timber.w(error, "Internet delivery failed, attempting mesh fallback")
                    
                    // Fallback: send via BLE mesh
                    try {
                        val meshResult = meshMessageRepository.createAndSend(
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
                                _createIncidentState.value = CreateIncidentState.MeshFallbackSuccess(
                                    "Report sent via mesh network (${meshMessage.status.value}). " +
                                    "It will be delivered to the server when internet is available."
                                )
                                Timber.i("Incident sent via mesh fallback: ${meshMessage.messageId}")
                            },
                            onFailure = { meshError ->
                                _createIncidentState.value = CreateIncidentState.Error(
                                    error.message ?: "Failed to create incident"
                                )
                                Timber.e(meshError, "Mesh fallback also failed")
                            }
                        )
                    } catch (e: Exception) {
                        _createIncidentState.value = CreateIncidentState.Error(
                            error.message ?: "Failed to create incident"
                        )
                        Timber.e(e, "Mesh fallback exception")
                    }
                }
            )
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
