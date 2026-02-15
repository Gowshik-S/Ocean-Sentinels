package com.oceansentinels.app.domain.repository

import com.oceansentinels.app.domain.model.*
import kotlinx.coroutines.flow.Flow

/**
 * Repository interface for incident operations
 */
interface IncidentRepository {
    
    /**
     * Get all incidents with optional filters
     */
    suspend fun getIncidents(filters: IncidentFilters): Result<IncidentListResult>
    
    /**
     * Get incidents as a flow for real-time updates
     */
    fun getIncidentsFlow(filters: IncidentFilters): Flow<Result<IncidentListResult>>
    
    /**
     * Get a single incident by ID
     */
    suspend fun getIncident(id: Int): Result<Incident>
    
    /**
     * Get a single incident by reference ID
     */
    suspend fun getIncidentByReference(referenceId: String): Result<Incident>
    
    /**
     * Get user's own reports
     */
    suspend fun getMyReports(filters: IncidentFilters): Result<IncidentListResult>
    
    /**
     * Create a new incident report
     */
    suspend fun createIncident(request: CreateIncidentRequest): Result<Incident>
    
    /**
     * Verify an incident (Admin/Authority only)
     */
    suspend fun verifyIncident(id: Int): Result<Incident>
    
    /**
     * Deploy response to an incident (Admin/Rescue Team only)
     */
    suspend fun deployResponse(id: Int): Result<Incident>
    
    /**
     * Resolve an incident (Admin/Authority/Rescue Team only)
     */
    suspend fun resolveIncident(id: Int): Result<Incident>
    
    /**
     * Get cached incidents from local database
     */
    suspend fun getCachedIncidents(): List<Incident>
    
    /**
     * Sync local incidents with server
     */
    suspend fun syncIncidents(): Result<Unit>
    
    /**
     * Assign an incident to a rescue team member (Admin/Authority only)
     */
    suspend fun assignIncident(incidentId: Int, rescueTeamUserId: Int): Result<Unit>
    
    /**
     * Get incidents assigned to the current rescue team member
     */
    suspend fun getAssignedIncidents(page: Int = 1, size: Int = 20): Result<IncidentListResult>
}
