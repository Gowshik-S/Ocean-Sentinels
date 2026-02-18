package com.oceansentinels.app.mesh.network

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import timber.log.Timber
import java.util.concurrent.atomic.AtomicBoolean
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Centralized network connectivity monitor for the entire app.
 *
 * Design rationale (compared with bitchat-android & bridgefy-alerts):
 * ────────────────────────────────────────────────────────────────────
 * • bitchat-android is 100% mesh-only — no internet fallback at all.
 *   It never checks connectivity; all messages flow through BLE mesh
 *   with store-and-forward (StoreForwardManager) for offline peers.
 *
 * • bridgefy-alerts relies entirely on the Bridgefy SDK which hides
 *   all networking internals — no connectivity check in user code.
 *
 * • Ocean Sentinels is a HYBRID system: Internet-first with automatic
 *   BLE mesh fallback. This class provides the "internet available?"
 *   signal that enables instant routing decisions:
 *
 *   ┌──────────────────────────────────────────────────────────────┐
 *   │  User submits hazard report                                 │
 *   │    ↓                                                        │
 *   │  NetworkConnectivityManager.isOnline  ──── true ──→ API     │
 *   │    │                                                        │
 *   │    └── false ──→ MeshMessageRepository.forwardToMesh()      │
 *   │                    ↓                                        │
 *   │                  BLE peers available? ── yes → broadcast     │
 *   │                    │                                        │
 *   │                    └── no → queue locally (Room DB)          │
 *   │                              ↓                              │
 *   │                           MeshForegroundService              │
 *   │                           • relayProcessor (15s)            │
 *   │                           • queueProcessor (30s)            │
 *   │                           • onAvailable → processQueue()    │
 *   └──────────────────────────────────────────────────────────────┘
 *
 * Key differences from scattered ConnectivityManager usage:
 * 1. Single registration point — avoids duplicate NetworkCallbacks
 *    (previously both MeshForegroundService AND MeshMessageRepository
 *    each had their own internet checks, risking race conditions)
 * 2. Reactive StateFlow — UI and ViewModels can observe connectivity
 *    changes without polling (bitchat achieves similar reactivity
 *    through its PeerManager's connection state flows)
 * 3. AtomicBoolean cache — thread-safe fast-path check for repository
 *    and service code running on different coroutine dispatchers
 * 4. Auto-forward trigger — emits onConnectivityChanged callbacks so
 *    MeshForegroundService can instantly switch between internet-upload
 *    mode and mesh-relay mode (similar to bitchat's always-on relay
 *    but with the internet-priority layer on top)
 */
@Singleton
class NetworkConnectivityManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    companion object {
        private const val TAG = "NetworkConnectivity"
    }

    private val connectivityManager =
        context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    /** Thread-safe cached flag for synchronous checks */
    private val _isOnlineAtomic = AtomicBoolean(false)

    /** Reactive stream of connectivity state for UI observation */
    private val _isOnline = MutableStateFlow(false)
    val isOnline: StateFlow<Boolean> = _isOnline.asStateFlow()

    /**
     * Thread-safe list of connectivity listeners.
     * Replaces the old single-callback pattern (var onConnectivityChanged)
     * which was last-write-wins — if two components registered, only the
     * second one received callbacks. Now all registered listeners are notified.
     */
    private val connectivityListeners = mutableListOf<(Boolean) -> Unit>()

    /**
     * @deprecated Use addConnectivityListener/removeConnectivityListener instead.
     * Kept for backward compatibility — setting this adds a legacy listener.
     */
    @Deprecated("Use addConnectivityListener() instead")
    var onConnectivityChanged: ((Boolean) -> Unit)?
        get() = null
        set(value) {
            // Remove any previously set legacy listener tag
            synchronized(connectivityListeners) {
                connectivityListeners.removeAll { it is LegacyListenerWrapper }
                if (value != null) {
                    connectivityListeners.add(LegacyListenerWrapper(value))
                }
            }
        }

    /** Wrapper to identify legacy listeners for removal */
    private class LegacyListenerWrapper(
        private val delegate: (Boolean) -> Unit
    ) : (Boolean) -> Unit {
        override fun invoke(online: Boolean) = delegate(online)
    }

    /** Add a connectivity change listener. Thread-safe. */
    fun addConnectivityListener(listener: (Boolean) -> Unit) {
        synchronized(connectivityListeners) {
            connectivityListeners.add(listener)
        }
    }

    /** Remove a previously added connectivity listener. Thread-safe. */
    fun removeConnectivityListener(listener: (Boolean) -> Unit) {
        synchronized(connectivityListeners) {
            connectivityListeners.remove(listener)
        }
    }

    private var networkCallback: ConnectivityManager.NetworkCallback? = null
    private var isRegistered = false

    init {
        // Set initial state from system before async callbacks arrive
        val initialState = checkInternetNow()
        _isOnlineAtomic.set(initialState)
        _isOnline.value = initialState
        Timber.i("$TAG: Initial connectivity state: $initialState")
    }

    /**
     * Register the NetworkCallback to start monitoring.
     * Safe to call multiple times — only registers once.
     *
     * Uses NET_CAPABILITY_INTERNET + NET_CAPABILITY_VALIDATED to ensure
     * the network can actually reach the internet (not just connected to WiFi
     * with no gateway). This matches the validation approach used in both
     * the original MeshForegroundService and MeshMessageRepository.
     */
    fun startMonitoring() {
        if (isRegistered) return

        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .addCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
            .build()

        networkCallback = object : ConnectivityManager.NetworkCallback() {
            /**
             * Called when a network satisfying our request becomes available.
             * This is the trigger to flush the entire mesh message queue to the
             * server — equivalent to bitchat's "peer reconnect → send cached
             * messages" flow, but uploading to the API instead of BLE peers.
             */
            override fun onAvailable(network: Network) {
                Timber.i("$TAG: Internet AVAILABLE — switching to internet-upload mode")
                updateState(true)
            }

            /**
             * Called when the network is lost. This triggers mesh-relay mode:
             * all new reports go directly through BLE mesh, and the relay
             * processor in MeshForegroundService kicks in (every 15s).
             *
             * Compare with bitchat-android: it's ALWAYS in this mode since
             * it has no server component. Our relay logic mirrors bitchat's
             * broadcastPacket() → all connected peers approach.
             */
            override fun onLost(network: Network) {
                Timber.i("$TAG: Internet LOST — switching to mesh-relay mode")
                updateState(false)
            }

            override fun onCapabilitiesChanged(
                network: Network,
                capabilities: NetworkCapabilities
            ) {
                val validated = capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
                if (validated != _isOnlineAtomic.get()) {
                    Timber.d("$TAG: Capabilities changed, validated=$validated")
                    updateState(validated)
                }
            }
        }

        try {
            connectivityManager.registerNetworkCallback(request, networkCallback!!)
            isRegistered = true
            Timber.i("$TAG: Network monitoring started")
        } catch (e: Exception) {
            Timber.e(e, "$TAG: Failed to register network callback")
        }
    }

    /**
     * Stop monitoring. Call from Service.onDestroy() or when mesh is stopped.
     * Uses finally block to ensure isRegistered is always reset, even if
     * unregisterNetworkCallback throws — preventing permanent re-registration block.
     */
    fun stopMonitoring() {
        networkCallback?.let {
            try {
                connectivityManager.unregisterNetworkCallback(it)
                Timber.i("$TAG: Network monitoring stopped")
            } catch (e: Exception) {
                Timber.e(e, "$TAG: Error unregistering network callback")
            } finally {
                isRegistered = false
                networkCallback = null
            }
        }
    }

    /**
     * Synchronous internet check — reads the cached AtomicBoolean.
     * Use this for fast-path decisions in repository/service code where
     * you need an immediate answer without suspending.
     *
     * This is analogous to how bitchat-android's components check
     * connection state via BluetoothConnectionTracker's synchronous
     * getConnectedDevices() — a cached snapshot, not a live check.
     */
    fun isInternetAvailable(): Boolean = _isOnlineAtomic.get()

    /**
     * Force a fresh check against the system ConnectivityManager.
     * Use sparingly — prefer the cached value for normal operations.
     *
     * Checks both NET_CAPABILITY_INTERNET (has an internet route) and
     * NET_CAPABILITY_VALIDATED (actually tested connectivity). This
     * prevents false positives from captive portals or dead WiFi.
     */
    fun checkInternetNow(): Boolean {
        val network = connectivityManager.activeNetwork ?: return false
        val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
    }

    private fun updateState(online: Boolean) {
        _isOnlineAtomic.set(online)
        _isOnline.value = online
        // Notify all registered listeners (snapshot to avoid ConcurrentModificationException)
        val listeners = synchronized(connectivityListeners) { connectivityListeners.toList() }
        listeners.forEach { it.invoke(online) }
    }
}
