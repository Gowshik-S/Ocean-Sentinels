package com.oceansentinels.app.data.repository

import com.oceansentinels.app.data.local.database.dao.IncidentDao
import com.oceansentinels.app.data.local.database.entity.IncidentEntity
import com.oceansentinels.app.data.remote.api.OceanSentinelsApi
import com.oceansentinels.app.data.remote.dto.CreateIncidentRequestDto
import com.oceansentinels.app.domain.model.*
import com.oceansentinels.app.domain.repository.IncidentRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Implementation of IncidentRepository
 */
@Singleton
class IncidentRepositoryImpl @Inject constructor(
    private val api: OceanSentinelsApi,
    private val incidentDao: IncidentDao
) : IncidentRepository {

    override suspend fun getIncidents(filters: IncidentFilters): Result<IncidentListResult> {
        return try {
            Timber.d("Fetching incidents with filters: $filters")
            
            val response = api.getIncidents(
                page = filters.page,
                size = filters.size,
                status = filters.status?.value,
                hazardType = filters.hazardType?.value,
                urgency = filters.urgency?.value,
                search = filters.searchQuery
            )
            
            if (response.isSuccessful && response.body() != null) {
                val result = response.body()!!.toDomain()
                
                // Cache incidents
                val entities = result.incidents.map { IncidentEntity.fromDomain(it) }
                incidentDao.insertAll(entities)
                
                Timber.d("Fetched ${result.incidents.size} incidents")
                Result.success(result)
            } else {
                val errorBody = response.errorBody()?.string() ?: "Unknown error"
                Timber.e("Failed to fetch incidents: $errorBody")
                Result.failure(Exception("Failed to fetch incidents: $errorBody"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error fetching incidents")
            // Try to return cached data
            val cached = getCachedIncidents()
            if (cached.isNotEmpty()) {
                Result.success(
                    IncidentListResult(
                        incidents = cached,
                        total = cached.size,
                        page = 1,
                        size = cached.size,
                        hasNext = false,
                        hasPrev = false
                    )
                )
            } else {
                Result.failure(e)
            }
        }
    }

    override fun getIncidentsFlow(filters: IncidentFilters): Flow<Result<IncidentListResult>> = flow {
        emit(getIncidents(filters))
    }

    override suspend fun getIncident(id: Int): Result<Incident> {
        return try {
            val response = api.getIncident(id)
            
            if (response.isSuccessful && response.body() != null) {
                val incident = response.body()!!.toDomain()
                incidentDao.insert(IncidentEntity.fromDomain(incident))
                Result.success(incident)
            } else {
                // Try cache
                val cached = incidentDao.getIncidentById(id)
                if (cached != null) {
                    Result.success(cached.toDomain())
                } else {
                    Result.failure(Exception("Incident not found"))
                }
            }
        } catch (e: Exception) {
            val cached = incidentDao.getIncidentById(id)
            if (cached != null) {
                Result.success(cached.toDomain())
            } else {
                Result.failure(e)
            }
        }
    }

    override suspend fun getIncidentByReference(referenceId: String): Result<Incident> {
        return try {
            val cached = incidentDao.getIncidentByReferenceId(referenceId)
            if (cached != null) {
                Result.success(cached.toDomain())
            } else {
                Result.failure(Exception("Incident not found"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getMyReports(filters: IncidentFilters): Result<IncidentListResult> {
        // The API filters by user automatically based on auth token
        return getIncidents(filters)
    }

    override suspend fun createIncident(request: CreateIncidentRequest): Result<Incident> {
        return try {
            Timber.d("Creating new incident: ${request.hazardType}")
            
            val dto = CreateIncidentRequestDto.fromDomain(request)
            val response = api.createIncident(dto)
            
            if (response.isSuccessful && response.body() != null) {
                val incident = response.body()!!.toDomain()
                incidentDao.insert(IncidentEntity.fromDomain(incident))
                Timber.d("Incident created successfully: ${incident.referenceId}")
                Result.success(incident)
            } else {
                val errorBody = response.errorBody()?.string() ?: "Unknown error"
                Timber.e("Failed to create incident: $errorBody")
                Result.failure(Exception("Failed to create incident: $errorBody"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error creating incident")
            Result.failure(e)
        }
    }

    override suspend fun verifyIncident(id: Int): Result<Incident> {
        return try {
            Timber.d("Verifying incident: $id")
            
            val response = api.verifyIncident(id)
            
            if (response.isSuccessful) {
                Timber.d("Incident verified successfully: ${response.body()?.message}")
                // Re-fetch the updated incident from server
                return getIncident(id)
            } else {
                val errorBody = response.errorBody()?.string() ?: "Unknown error"
                Result.failure(Exception("Failed to verify incident: $errorBody"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error verifying incident")
            Result.failure(e)
        }
    }

    override suspend fun deployResponse(id: Int): Result<Incident> {
        return try {
            Timber.d("Deploying response to incident: $id")
            
            val response = api.deployResponse(id)
            
            if (response.isSuccessful) {
                Timber.d("Response deployed successfully: ${response.body()?.message}")
                // Re-fetch the updated incident from server
                return getIncident(id)
            } else {
                val errorBody = response.errorBody()?.string() ?: "Unknown error"
                Result.failure(Exception("Failed to deploy response: $errorBody"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error deploying response")
            Result.failure(e)
        }
    }

    override suspend fun resolveIncident(id: Int): Result<Incident> {
        return try {
            Timber.d("Resolving incident: $id")
            
            val response = api.resolveIncident(id)
            
            if (response.isSuccessful) {
                Timber.d("Incident resolved successfully: ${response.body()?.message}")
                // Re-fetch the updated incident from server
                return getIncident(id)
            } else {
                val errorBody = response.errorBody()?.string() ?: "Unknown error"
                Result.failure(Exception("Failed to resolve incident: $errorBody"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error resolving incident")
            Result.failure(e)
        }
    }

    override suspend fun getCachedIncidents(): List<Incident> {
        return incidentDao.getAllIncidentsList().map { it.toDomain() }
    }

    override suspend fun syncIncidents(): Result<Unit> {
        return try {
            val pendingIncidents = incidentDao.getPendingSyncIncidents()
            
            pendingIncidents.forEach { entity ->
                // In a real app, this would sync pending offline changes
                Timber.d("Syncing incident: ${entity.referenceId}")
            }
            
            // Refresh from server
            getIncidents(IncidentFilters())
            Result.success(Unit)
        } catch (e: Exception) {
            Timber.e(e, "Error syncing incidents")
            Result.failure(e)
        }
    }
    
    override suspend fun assignIncident(incidentId: Int, rescueTeamUserId: Int): Result<Unit> {
        return try {
            Timber.d("Assigning incident $incidentId to user $rescueTeamUserId")
            val response = api.assignIncident(incidentId, mapOf("assigned_to_id" to rescueTeamUserId))
            if (response.isSuccessful) {
                Timber.d("Incident assigned successfully")
                Result.success(Unit)
            } else {
                val errorBody = response.errorBody()?.string() ?: "Unknown error"
                Result.failure(Exception("Failed to assign incident: $errorBody"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error assigning incident")
            Result.failure(e)
        }
    }
    
    override suspend fun getAssignedIncidents(page: Int, size: Int): Result<IncidentListResult> {
        return try {
            Timber.d("Fetching assigned incidents page=$page")
            val response = api.getMyAssignedIncidents(page, size)
            if (response.isSuccessful && response.body() != null) {
                val result = response.body()!!.toDomain()
                Timber.d("Fetched ${result.incidents.size} assigned incidents")
                Result.success(result)
            } else {
                val errorBody = response.errorBody()?.string() ?: "Unknown error"
                Result.failure(Exception("Failed to fetch assigned incidents: $errorBody"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error fetching assigned incidents")
            Result.failure(e)
        }
    }
}
