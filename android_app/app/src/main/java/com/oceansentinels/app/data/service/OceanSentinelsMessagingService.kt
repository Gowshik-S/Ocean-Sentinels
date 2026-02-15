package com.oceansentinels.app.data.service

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.oceansentinels.app.R
import com.oceansentinels.app.data.local.preferences.PreferencesManager
import com.oceansentinels.app.presentation.MainActivity
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

/**
 * Firebase Cloud Messaging service for handling push notifications
 */
@AndroidEntryPoint
class OceanSentinelsMessagingService : FirebaseMessagingService() {

    @Inject
    lateinit var preferencesManager: PreferencesManager

    private val serviceJob = SupervisorJob()
    private val serviceScope = CoroutineScope(Dispatchers.IO + serviceJob)

    companion object {
        private const val CHANNEL_ID_ALERTS = "ocean_sentinels_alerts"
        private const val CHANNEL_NAME_ALERTS = "Ocean Hazard Alerts"
        private const val CHANNEL_ID_UPDATES = "ocean_sentinels_updates"
        private const val CHANNEL_NAME_UPDATES = "Status Updates"
        
        private const val NOTIFICATION_ID_ALERT = 1001
        private const val NOTIFICATION_ID_UPDATE = 1002
        
        // Notification data keys
        private const val KEY_TYPE = "type"
        private const val KEY_INCIDENT_ID = "incident_id"
        private const val KEY_TITLE = "title"
        private const val KEY_BODY = "body"
        private const val KEY_HAZARD_TYPE = "hazard_type"
        private const val KEY_URGENCY = "urgency"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceJob.cancel()
    }

    /**
     * Called when a new token is generated
     */
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Timber.d("FCM token refreshed: $token")
        
        // Save token locally and optionally send to server
        serviceScope.launch {
            preferencesManager.saveFcmToken(token)
            sendTokenToServer(token)
        }
    }

    /**
     * Called when a message is received
     */
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        
        Timber.d("FCM message from: ${remoteMessage.from}")
        
        // Check if notifications are enabled
        serviceScope.launch {
            // First check user preferences
            // For now, we'll show all notifications
            
            // Handle data payload
            if (remoteMessage.data.isNotEmpty()) {
                Timber.d("Message data: ${remoteMessage.data}")
                handleDataPayload(remoteMessage.data)
            }
            
            // Handle notification payload
            remoteMessage.notification?.let { notification ->
                Timber.d("Message notification: ${notification.title}")
                showNotification(
                    title = notification.title ?: "Ocean Sentinels",
                    body = notification.body ?: "",
                    data = remoteMessage.data
                )
            }
        }
    }

    /**
     * Handle data payload from FCM message
     */
    private fun handleDataPayload(data: Map<String, String>) {
        val type = data[KEY_TYPE] ?: return
        
        when (type) {
            "new_incident" -> handleNewIncidentNotification(data)
            "incident_update" -> handleIncidentUpdateNotification(data)
            "incident_verified" -> handleIncidentVerifiedNotification(data)
            "rescue_deployed" -> handleRescueDeployedNotification(data)
            "incident_resolved" -> handleIncidentResolvedNotification(data)
            else -> {
                // Generic notification
                showNotification(
                    title = data[KEY_TITLE] ?: "Ocean Sentinels",
                    body = data[KEY_BODY] ?: "",
                    data = data
                )
            }
        }
    }

    private fun handleNewIncidentNotification(data: Map<String, String>) {
        val hazardType = data[KEY_HAZARD_TYPE] ?: "Unknown"
        val urgency = data[KEY_URGENCY] ?: "medium"
        
        showNotification(
            title = "New $hazardType Report",
            body = data[KEY_BODY] ?: "A new incident has been reported in your area",
            data = data,
            channelId = CHANNEL_ID_ALERTS,
            notificationId = NOTIFICATION_ID_ALERT,
            highPriority = urgency == "high" || urgency == "critical"
        )
    }

    private fun handleIncidentUpdateNotification(data: Map<String, String>) {
        showNotification(
            title = "Incident Update",
            body = data[KEY_BODY] ?: "An incident you reported has been updated",
            data = data,
            channelId = CHANNEL_ID_UPDATES,
            notificationId = NOTIFICATION_ID_UPDATE
        )
    }

    private fun handleIncidentVerifiedNotification(data: Map<String, String>) {
        showNotification(
            title = "Incident Verified",
            body = data[KEY_BODY] ?: "Your report has been verified by authorities",
            data = data,
            channelId = CHANNEL_ID_UPDATES,
            notificationId = NOTIFICATION_ID_UPDATE
        )
    }

    private fun handleRescueDeployedNotification(data: Map<String, String>) {
        showNotification(
            title = "Rescue Team Deployed",
            body = data[KEY_BODY] ?: "A rescue team has been dispatched to handle the incident",
            data = data,
            channelId = CHANNEL_ID_ALERTS,
            notificationId = NOTIFICATION_ID_ALERT,
            highPriority = true
        )
    }

    private fun handleIncidentResolvedNotification(data: Map<String, String>) {
        showNotification(
            title = "Incident Resolved",
            body = data[KEY_BODY] ?: "The incident has been successfully resolved",
            data = data,
            channelId = CHANNEL_ID_UPDATES,
            notificationId = NOTIFICATION_ID_UPDATE
        )
    }

    /**
     * Display notification to user
     */
    private fun showNotification(
        title: String,
        body: String,
        data: Map<String, String>,
        channelId: String = CHANNEL_ID_ALERTS,
        notificationId: Int = NOTIFICATION_ID_ALERT,
        highPriority: Boolean = false
    ) {
        // Create intent for notification tap
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            data[KEY_INCIDENT_ID]?.let {
                putExtra("incident_id", it.toIntOrNull())
            }
            putExtra("notification_type", data[KEY_TYPE])
        }
        
        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this,
            notificationId,
            intent,
            pendingIntentFlags
        )

        // Build notification
        val defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        
        val notificationBuilder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setSound(defaultSoundUri)
            .setContentIntent(pendingIntent)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
        
        if (highPriority) {
            notificationBuilder
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setVibrate(longArrayOf(0, 500, 200, 500))
        } else {
            notificationBuilder.setPriority(NotificationCompat.PRIORITY_DEFAULT)
        }

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(notificationId, notificationBuilder.build())
    }

    /**
     * Create notification channels for Android O and above
     */
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // Alerts channel (high importance)
            val alertsChannel = NotificationChannel(
                CHANNEL_ID_ALERTS,
                CHANNEL_NAME_ALERTS,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Urgent alerts about ocean hazards and emergencies"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 200, 500)
                enableLights(true)
                lightColor = android.graphics.Color.RED
            }
            
            // Updates channel (default importance)
            val updatesChannel = NotificationChannel(
                CHANNEL_ID_UPDATES,
                CHANNEL_NAME_UPDATES,
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Updates about your reported incidents"
                enableVibration(true)
            }
            
            notificationManager.createNotificationChannels(listOf(alertsChannel, updatesChannel))
        }
    }

    /**
     * Send FCM token to server for backend push notification delivery
     */
    private suspend fun sendTokenToServer(token: String) {
        try {
            // TODO: Implement API call to send token to server
            // userRepository.updateFcmToken(token)
            Timber.d("FCM token sent to server: $token")
        } catch (e: Exception) {
            Timber.e(e, "Failed to send FCM token to server")
        }
    }
}
