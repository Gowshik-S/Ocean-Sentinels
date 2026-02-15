package com.oceansentinels.app.di

import android.content.Context
import com.oceansentinels.app.data.local.database.dao.MeshMessageDao
import com.oceansentinels.app.data.remote.api.OceanSentinelsApi
import com.oceansentinels.app.mesh.ble.BleMeshManager
import com.oceansentinels.app.mesh.ble.DeviceIdentifier
import com.oceansentinels.app.mesh.repository.MeshMessageRepository
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Hilt module providing mesh networking dependencies.
 *
 * Provides:
 * - BleMeshManager: singleton BLE mesh controller (PHY Coded + standard)
 * - MeshMessageRepository: message lifecycle management with delivery fallback
 */
@Module
@InstallIn(SingletonComponent::class)
object MeshModule {

    @Provides
    @Singleton
    fun provideBleMeshManager(
        @ApplicationContext context: Context
    ): BleMeshManager {
        return BleMeshManager(context)
    }

    @Provides
    @Singleton
    fun provideMeshMessageRepository(
        meshMessageDao: MeshMessageDao,
        api: OceanSentinelsApi,
        bleMeshManager: BleMeshManager,
        deviceIdentifier: DeviceIdentifier,
        @ApplicationContext context: Context
    ): MeshMessageRepository {
        return MeshMessageRepository(meshMessageDao, api, bleMeshManager, deviceIdentifier, context)
    }
}
