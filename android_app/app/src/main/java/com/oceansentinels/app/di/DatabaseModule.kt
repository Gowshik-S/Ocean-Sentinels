package com.oceansentinels.app.di

import android.content.Context
import androidx.room.Room
import com.oceansentinels.app.data.local.database.OceanSentinelsDatabase
import com.oceansentinels.app.data.local.database.dao.IncidentDao
import com.oceansentinels.app.data.local.database.dao.MeshMessageDao
import com.oceansentinels.app.data.local.database.dao.UserDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Hilt module for database dependencies
 */
@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(
        @ApplicationContext context: Context
    ): OceanSentinelsDatabase {
        return Room.databaseBuilder(
            context,
            OceanSentinelsDatabase::class.java,
            OceanSentinelsDatabase.DATABASE_NAME
        )
            .fallbackToDestructiveMigration()
            .build()
    }

    @Provides
    @Singleton
    fun provideUserDao(database: OceanSentinelsDatabase): UserDao {
        return database.userDao()
    }

    @Provides
    @Singleton
    fun provideIncidentDao(database: OceanSentinelsDatabase): IncidentDao {
        return database.incidentDao()
    }

    @Provides
    @Singleton
    fun provideMeshMessageDao(database: OceanSentinelsDatabase): MeshMessageDao {
        return database.meshMessageDao()
    }
}
