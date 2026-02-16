package com.oceansentinels.app.di

import android.content.Context
import com.oceansentinels.app.data.local.database.dao.MeshMessageDao
import com.oceansentinels.app.data.remote.api.OceanSentinelsApi
import com.oceansentinels.app.mesh.ble.BleMeshManager
import com.oceansentinels.app.mesh.ble.DeviceIdentifier
import com.oceansentinels.app.mesh.network.NetworkConnectivityManager
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
 * - NetworkConnectivityManager: centralized internet state monitor with reactive StateFlow
 * - BleMeshManager: singleton BLE mesh controller (PHY Coded + standard)
 * - MeshMessageRepository: message lifecycle management with delivery fallback
 *
 * Architecture comparison (vs bitchat-android / bridgefy-alerts):
 * ─────────────────────────────────────────────────────────────
 * bitchat-android: Manual construction + singletons, no DI framework.
 *   Components wired in BluetoothMeshService constructor.
 * bridgefy-alerts: Hilt DI (same as us), but SDK abstracts all mesh internals.
 * Ocean Sentinels: Hilt DI with explicit internet↔mesh routing layer.
 */
@Module
@InstallIn(SingletonComponent::class)
object MeshModule {

    /**
     * Centralized connectivity monitor — single NetworkCallback registration point.
     *
     * Why a dedicated singleton (lesson from bitchat-android):
     * bitchat doesn't need this because it's 100% mesh. But our hybrid system
     * previously had BOTH MeshForegroundService AND MeshMessageRepository each
     * running their own ConnectivityManager queries, risking race conditions.
     * This singleton eliminates that by providing a single source of truth.
     */
    @Provides
    @Singleton
    fun provideNetworkConnectivityManager(
        @ApplicationContext context: Context
    ): NetworkConnectivityManager {
        return NetworkConnectivityManager(context)
    }

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
        networkConnectivityManager: NetworkConnectivityManager,
        @ApplicationContext context: Context
    ): MeshMessageRepository {
        return MeshMessageRepository(
            meshMessageDao, api, bleMeshManager, deviceIdentifier,
            networkConnectivityManager, context
        )
    }
}
