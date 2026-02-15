package com.oceansentinels.app.data.local.preferences

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore
import com.google.gson.Gson
import com.oceansentinels.app.domain.model.User
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "ocean_sentinels_preferences")

/**
 * DataStore preferences manager for storing user session and app settings
 */
@Singleton
class PreferencesManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val gson: Gson
) {
    private val dataStore = context.dataStore
    
    companion object {
        private val KEY_AUTH_TOKEN = stringPreferencesKey("auth_token")
        private val KEY_USER_DATA = stringPreferencesKey("user_data")
        private val KEY_IS_LOGGED_IN = booleanPreferencesKey("is_logged_in")
        private val KEY_REMEMBER_ME = booleanPreferencesKey("remember_me")
        private val KEY_DARK_MODE = booleanPreferencesKey("dark_mode")
        private val KEY_NOTIFICATIONS_ENABLED = booleanPreferencesKey("notifications_enabled")
        private val KEY_FCM_TOKEN = stringPreferencesKey("fcm_token")
        private val KEY_FIRST_LAUNCH = booleanPreferencesKey("first_launch")
        private val KEY_DEMO_POPUP_SHOWN = booleanPreferencesKey("demo_popup_shown")
        private val KEY_OFFLINE_MODE = booleanPreferencesKey("offline_mode")
    }
    
    // ============= Auth Token =============
    
    val authToken: Flow<String?> = dataStore.data.map { preferences ->
        preferences[KEY_AUTH_TOKEN]
    }
    
    suspend fun saveAuthToken(token: String) {
        dataStore.edit { preferences ->
            preferences[KEY_AUTH_TOKEN] = token
        }
    }
    
    suspend fun clearAuthToken() {
        dataStore.edit { preferences ->
            preferences.remove(KEY_AUTH_TOKEN)
        }
    }
    
    // ============= User Data =============
    
    val userData: Flow<User?> = dataStore.data.map { preferences ->
        preferences[KEY_USER_DATA]?.let { json ->
            try {
                gson.fromJson(json, User::class.java)
            } catch (e: Exception) {
                null
            }
        }
    }
    
    suspend fun saveUserData(user: User) {
        dataStore.edit { preferences ->
            preferences[KEY_USER_DATA] = gson.toJson(user)
        }
    }
    
    suspend fun clearUserData() {
        dataStore.edit { preferences ->
            preferences.remove(KEY_USER_DATA)
        }
    }
    
    // ============= Login State =============
    
    val isLoggedIn: Flow<Boolean> = dataStore.data.map { preferences ->
        preferences[KEY_IS_LOGGED_IN] ?: false
    }
    
    suspend fun setLoggedIn(loggedIn: Boolean) {
        dataStore.edit { preferences ->
            preferences[KEY_IS_LOGGED_IN] = loggedIn
        }
    }
    
    // ============= Remember Me =============
    
    val rememberMe: Flow<Boolean> = dataStore.data.map { preferences ->
        preferences[KEY_REMEMBER_ME] ?: false
    }
    
    suspend fun setRememberMe(remember: Boolean) {
        dataStore.edit { preferences ->
            preferences[KEY_REMEMBER_ME] = remember
        }
    }
    
    // ============= Dark Mode =============
    
    val isDarkMode: Flow<Boolean> = dataStore.data.map { preferences ->
        preferences[KEY_DARK_MODE] ?: false
    }
    
    suspend fun setDarkMode(enabled: Boolean) {
        dataStore.edit { preferences ->
            preferences[KEY_DARK_MODE] = enabled
        }
    }
    
    // ============= Notifications =============
    
    val notificationsEnabled: Flow<Boolean> = dataStore.data.map { preferences ->
        preferences[KEY_NOTIFICATIONS_ENABLED] ?: true
    }
    
    suspend fun setNotificationsEnabled(enabled: Boolean) {
        dataStore.edit { preferences ->
            preferences[KEY_NOTIFICATIONS_ENABLED] = enabled
        }
    }
    
    // ============= FCM Token =============
    
    val fcmToken: Flow<String?> = dataStore.data.map { preferences ->
        preferences[KEY_FCM_TOKEN]
    }
    
    suspend fun saveFcmToken(token: String) {
        dataStore.edit { preferences ->
            preferences[KEY_FCM_TOKEN] = token
        }
    }
    
    // ============= First Launch =============
    
    val isFirstLaunch: Flow<Boolean> = dataStore.data.map { preferences ->
        preferences[KEY_FIRST_LAUNCH] ?: true
    }
    
    suspend fun setFirstLaunchComplete() {
        dataStore.edit { preferences ->
            preferences[KEY_FIRST_LAUNCH] = false
        }
    }
    
    // ============= Demo Popup =============
    
    val hasDemoPopupShown: Flow<Boolean> = dataStore.data.map { preferences ->
        preferences[KEY_DEMO_POPUP_SHOWN] ?: false
    }
    
    suspend fun setDemoPopupShown() {
        dataStore.edit { preferences ->
            preferences[KEY_DEMO_POPUP_SHOWN] = true
        }
    }
    
    // ============= Offline Mode =============
    
    val isOfflineMode: Flow<Boolean> = dataStore.data.map { preferences ->
        preferences[KEY_OFFLINE_MODE] ?: false
    }
    
    suspend fun setOfflineMode(enabled: Boolean) {
        dataStore.edit { preferences ->
            preferences[KEY_OFFLINE_MODE] = enabled
        }
    }
    
    // ============= Clear All =============
    
    suspend fun clearAll() {
        dataStore.edit { preferences ->
            preferences.clear()
        }
    }
    
    suspend fun clearSession() {
        dataStore.edit { preferences ->
            preferences.remove(KEY_AUTH_TOKEN)
            preferences.remove(KEY_USER_DATA)
            preferences[KEY_IS_LOGGED_IN] = false
        }
    }
}
