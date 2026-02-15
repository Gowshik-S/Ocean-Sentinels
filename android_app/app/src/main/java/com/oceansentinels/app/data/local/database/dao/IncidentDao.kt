package com.oceansentinels.app.data.local.database.dao

import androidx.room.*
import com.oceansentinels.app.data.local.database.entity.IncidentEntity
import kotlinx.coroutines.flow.Flow

/**
 * DAO for Incident entity
 */
@Dao
interface IncidentDao {
    
    @Query("SELECT * FROM incidents ORDER BY created_at DESC")
    fun getAllIncidents(): Flow<List<IncidentEntity>>
    
    @Query("SELECT * FROM incidents ORDER BY created_at DESC")
    suspend fun getAllIncidentsList(): List<IncidentEntity>
    
    @Query("SELECT * FROM incidents WHERE id = :id")
    suspend fun getIncidentById(id: Int): IncidentEntity?
    
    @Query("SELECT * FROM incidents WHERE reference_id = :referenceId")
    suspend fun getIncidentByReferenceId(referenceId: String): IncidentEntity?
    
    @Query("SELECT * FROM incidents WHERE reporter_id = :reporterId ORDER BY created_at DESC")
    fun getIncidentsByReporter(reporterId: Int): Flow<List<IncidentEntity>>
    
    @Query("SELECT * FROM incidents WHERE reporter_id = :reporterId ORDER BY created_at DESC")
    suspend fun getIncidentsByReporterList(reporterId: Int): List<IncidentEntity>
    
    @Query("SELECT * FROM incidents WHERE status = :status ORDER BY created_at DESC")
    fun getIncidentsByStatus(status: String): Flow<List<IncidentEntity>>
    
    @Query("SELECT * FROM incidents WHERE hazard_type = :hazardType ORDER BY created_at DESC")
    fun getIncidentsByHazardType(hazardType: String): Flow<List<IncidentEntity>>
    
    @Query("SELECT * FROM incidents WHERE urgency = :urgency ORDER BY created_at DESC")
    fun getIncidentsByUrgency(urgency: String): Flow<List<IncidentEntity>>
    
    @Query("""
        SELECT * FROM incidents 
        WHERE (:status IS NULL OR status = :status)
        AND (:hazardType IS NULL OR hazard_type = :hazardType)
        AND (:urgency IS NULL OR urgency = :urgency)
        ORDER BY created_at DESC
        LIMIT :limit OFFSET :offset
    """)
    suspend fun getFilteredIncidents(
        status: String?,
        hazardType: String?,
        urgency: String?,
        limit: Int,
        offset: Int
    ): List<IncidentEntity>
    
    @Query("SELECT * FROM incidents WHERE is_pending_sync = 1")
    suspend fun getPendingSyncIncidents(): List<IncidentEntity>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(incident: IncidentEntity)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(incidents: List<IncidentEntity>)
    
    @Update
    suspend fun update(incident: IncidentEntity)
    
    @Delete
    suspend fun delete(incident: IncidentEntity)
    
    @Query("DELETE FROM incidents WHERE id = :id")
    suspend fun deleteById(id: Int)
    
    @Query("DELETE FROM incidents")
    suspend fun deleteAll()
    
    @Query("SELECT COUNT(*) FROM incidents")
    suspend fun count(): Int
    
    @Query("SELECT COUNT(*) FROM incidents WHERE status IN ('pending', 'verified', 'in_progress')")
    suspend fun countActive(): Int
    
    @Query("SELECT COUNT(*) FROM incidents WHERE status = 'resolved'")
    suspend fun countResolved(): Int
}
