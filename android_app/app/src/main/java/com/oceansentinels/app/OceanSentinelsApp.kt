package com.oceansentinels.app

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import com.mapbox.common.MapboxOptions
import dagger.hilt.android.HiltAndroidApp
import timber.log.Timber

@HiltAndroidApp
class OceanSentinelsApp : Application() {

    override fun onCreate() {
        super.onCreate()
        
        // Initialize Timber for logging
        if (BuildConfig.DEBUG) {
            Timber.plant(Timber.DebugTree())
        }
        
        // Initialize Mapbox with access token
        MapboxOptions.accessToken = BuildConfig.MAPBOX_ACCESS_TOKEN
        
        // Create notification channels
        createNotificationChannels()
    }
    
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)
            
            // Incident Alerts Channel
            val alertsChannel = NotificationChannel(
                CHANNEL_INCIDENT_ALERTS,
                "Incident Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Real-time alerts for coastal incidents and hazards"
                enableVibration(true)
            }
            
            // Response Updates Channel
            val updatesChannel = NotificationChannel(
                CHANNEL_RESPONSE_UPDATES,
                "Response Updates",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Updates on incident status and rescue team deployments"
            }
            
            // General Notifications Channel
            val generalChannel = NotificationChannel(
                CHANNEL_GENERAL,
                "General",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "General notifications and announcements"
            }
            
            // Mesh Network Service Channel
            val meshChannel = NotificationChannel(
                CHANNEL_MESH_SERVICE,
                "Mesh Network",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "BLE mesh networking service for offline hazard report relay"
                setShowBadge(false)
            }
            
            notificationManager.createNotificationChannels(
                listOf(alertsChannel, updatesChannel, generalChannel, meshChannel)
            )
        }
    }
    
    companion object {
        const val CHANNEL_INCIDENT_ALERTS = "ocean_sentinels_alerts"
        const val CHANNEL_RESPONSE_UPDATES = "ocean_sentinels_updates"
        const val CHANNEL_GENERAL = "ocean_sentinels_general"
        const val CHANNEL_MESH_SERVICE = "ocean_mesh_service"
    }
}
