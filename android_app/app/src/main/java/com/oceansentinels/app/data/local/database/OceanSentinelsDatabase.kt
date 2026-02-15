package com.oceansentinels.app.data.local.database

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.oceansentinels.app.data.local.database.dao.IncidentDao
import com.oceansentinels.app.data.local.database.dao.MeshMessageDao
import com.oceansentinels.app.data.local.database.dao.UserDao
import com.oceansentinels.app.data.local.database.entity.IncidentEntity
import com.oceansentinels.app.data.local.database.entity.MeshMessageEntity
import com.oceansentinels.app.data.local.database.entity.UserEntity

/**
 * Room database for Ocean Sentinels app
 * 
 * Version history:
 * - v2: Initial schema (users, incidents)
 * - v3: Added mesh_messages table for BLE mesh networking queue
 */
@Database(
    entities = [
        UserEntity::class,
        IncidentEntity::class,
        MeshMessageEntity::class
    ],
    version = 3,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class OceanSentinelsDatabase : RoomDatabase() {
    
    abstract fun userDao(): UserDao
    abstract fun incidentDao(): IncidentDao
    abstract fun meshMessageDao(): MeshMessageDao
    
    companion object {
        const val DATABASE_NAME = "ocean_sentinels_db"
    }
}
