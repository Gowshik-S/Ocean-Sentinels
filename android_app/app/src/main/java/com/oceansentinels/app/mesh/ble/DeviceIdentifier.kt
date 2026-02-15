package com.oceansentinels.app.mesh.ble

import android.content.Context
import android.provider.Settings
import dagger.hilt.android.qualifiers.ApplicationContext
import timber.log.Timber
import java.security.MessageDigest
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Generates and persists a unique device identifier for mesh networking.
 *
 * Since Android 6.0 (API 23), BluetoothAdapter.getAddress() returns
 * "02:00:00:00:00:00" for privacy — making MAC-based IDs useless.
 *
 * This class generates a persistent UUID-based ID stored in SharedPreferences,
 * combined with the Android ID for a stable, unique device identity.
 */
@Singleton
class DeviceIdentifier @Inject constructor(
    @ApplicationContext private val context: Context
) {
    companion object {
        private const val TAG = "DeviceIdentifier"
        private const val PREFS_NAME = "ocean_mesh_prefs"
        private const val KEY_DEVICE_ID = "device_mesh_id"
        private const val KEY_DEVICE_FINGERPRINT = "device_fingerprint"
        /** Length of the device ID (hex characters) */
        private const val DEVICE_ID_LENGTH = 12
        /** Length of the fingerprint (hex characters — 16 hex = 8 bytes = 64 bits) */
        private const val FINGERPRINT_LENGTH = 16
    }

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    /**
     * Get or generate a persistent unique device ID.
     * Format: 12 hex chars (e.g. "a3f7c1b9e2d4")
     * Used wherever MAC addresses were previously used for device identity.
     */
    fun getDeviceId(): String {
        var id = prefs.getString(KEY_DEVICE_ID, null)
        if (id == null) {
            id = UUID.randomUUID().toString().replace("-", "").take(DEVICE_ID_LENGTH)
            prefs.edit().putString(KEY_DEVICE_ID, id).apply()
            Timber.i("$TAG: Generated new device ID: $id")
        }
        return id
    }

    /**
     * Get or generate a persistent device fingerprint.
     * Combines the persistent device ID with Android ID for extra uniqueness.
     * Format: 16 hex chars (e.g. "a3f7c1b9e2d4f608")
     */
    fun getDeviceFingerprint(): String {
        var fp = prefs.getString(KEY_DEVICE_FINGERPRINT, null)
        if (fp == null) {
            val deviceId = getDeviceId()
            val androidId = try {
                Settings.Secure.getString(
                    context.contentResolver, Settings.Secure.ANDROID_ID
                )
            } catch (e: Exception) {
                Timber.w(e, "$TAG: Failed to read ANDROID_ID")
                null
            } ?: UUID.randomUUID().toString().replace("-", "").take(16)
            fp = generateFingerprint(deviceId, androidId)
            prefs.edit().putString(KEY_DEVICE_FINGERPRINT, fp).apply()
            Timber.i("$TAG: Generated device fingerprint: $fp")
        }
        return fp
    }

    /**
     * Get a mesh ID as a byte array for BLE advertising payloads.
     * Returns the full fingerprint as raw bytes (8 bytes from 16 hex chars).
     */
    fun getMeshIdBytes(): ByteArray {
        val fp = getDeviceFingerprint()
        return hexToByteArray(fp)
    }

    /**
     * Generate a SHA-256 fingerprint from device ID + Android ID.
     * Returns first 16 hex characters (8 bytes / 64 bits).
     */
    private fun generateFingerprint(deviceId: String, androidId: String): String {
        val payload = "$deviceId|$androidId"
        val digest = MessageDigest.getInstance("SHA-256")
        val hash = digest.digest(payload.toByteArray())
        return hash.take(FINGERPRINT_LENGTH / 2).joinToString("") { "%02x".format(it) }
    }

    /**
     * Convert a hex string to a byte array.
     */
    private fun hexToByteArray(hex: String): ByteArray {
        val len = hex.length
        val data = ByteArray(len / 2)
        var i = 0
        while (i < len) {
            data[i / 2] = ((Character.digit(hex[i], 16) shl 4) +
                    Character.digit(hex[i + 1], 16)).toByte()
            i += 2
        }
        return data
    }
}
