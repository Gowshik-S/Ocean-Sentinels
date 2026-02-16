package com.oceansentinels.app.presentation.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.oceansentinels.app.domain.model.HazardType
import com.oceansentinels.app.domain.model.UrgencyLevel
import com.oceansentinels.app.mesh.ble.BleMeshManager
import com.oceansentinels.app.mesh.model.*
import com.oceansentinels.app.mesh.repository.MeshMessageRepository
import com.oceansentinels.app.mesh.service.MeshForegroundService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

/**
 * ViewModel for the Mesh Network screen.
 * Manages mesh service state, message queue, and peer list.
 */
@HiltViewModel
class MeshViewModel @Inject constructor(
    application: Application,
    private val meshRepository: MeshMessageRepository,
    private val bleMeshManager: BleMeshManager
) : AndroidViewModel(application) {

    companion object {
        private const val TAG = "MeshViewModel"
    }

    // ==================== UI State ====================

    private val _meshStatus = MutableStateFlow(MeshNetworkStatus())
    val meshStatus: StateFlow<MeshNetworkStatus> = _meshStatus.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    private val _sendState = MutableStateFlow<MeshSendState>(MeshSendState.Idle)
    val sendState: StateFlow<MeshSendState> = _sendState.asStateFlow()

    private val _selectedTab = MutableStateFlow(MeshTab.QUEUE)
    val selectedTab: StateFlow<MeshTab> = _selectedTab.asStateFlow()

    // ==================== Data Flows ====================

    /** All mesh messages */
    val allMessages: StateFlow<List<MeshMessage>> = meshRepository.getAllMessages()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    /** Own pending messages */
    val pendingMessages: StateFlow<List<MeshMessage>> = meshRepository.getPendingMessages()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    /** Delivered messages */
    val deliveredMessages: StateFlow<List<MeshMessage>> = meshRepository.getDeliveredMessages()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    /** Messages relayed for others */
    val relayedMessages: StateFlow<List<MeshMessage>> = meshRepository.getRelayedMessages()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    /** Service running state */
    val isServiceRunning: StateFlow<Boolean> = MeshForegroundService.isServiceRunning

    init {
        updateMeshCapabilities()
        observeCounters()
    }

    // ==================== Mesh Service Control ====================

    /** Start the mesh foreground service */
    fun startMeshService() {
        val context = getApplication<Application>()
        MeshForegroundService.start(context)
        updateStatus { it.copy(isRunning = true) }
    }

    /** Stop the mesh foreground service */
    fun stopMeshService() {
        val context = getApplication<Application>()
        MeshForegroundService.stop(context)
        updateStatus { it.copy(isRunning = false) }
    }

    /** Toggle mesh service on/off */
    fun toggleMeshService() {
        if (isServiceRunning.value) {
            stopMeshService()
        } else {
            startMeshService()
        }
    }

    // ==================== Report Hazard via Mesh ====================

    /**
     * Submit a hazard report through the mesh network.
     * Auto-determines transport: Internet → Mesh → Local Queue
     */
    fun reportHazard(
        hazardType: HazardType,
        location: String,
        latitude: Double?,
        longitude: Double?,
        description: String,
        urgency: UrgencyLevel,
        contactInfo: String? = null,
        photoUrl: String? = null,
        reporterUserId: Int? = null
    ) {
        viewModelScope.launch {
            _sendState.value = MeshSendState.Sending

            val result = meshRepository.createAndSend(
                hazardType = hazardType,
                location = location,
                latitude = latitude,
                longitude = longitude,
                description = description,
                urgency = urgency,
                contactInfo = contactInfo,
                photoUrl = photoUrl,
                reporterUserId = reporterUserId
            )

            result.fold(
                onSuccess = { message ->
                    // Use the actual transport stored on the message rather than
                    // inferring from status (Issue #12: prevents incorrect mapping)
                    _sendState.value = MeshSendState.Success(
                        messageId = message.messageId,
                        transport = when (message.status) {
                            MeshMessageStatus.DELIVERED -> MeshTransport.INTERNET
                            MeshMessageStatus.RELAYED -> MeshTransport.BLE_CODED
                            else -> MeshTransport.LOCAL_QUEUE
                        },
                        status = message.status
                    )
                    Timber.i("$TAG: Report submitted: ${message.messageId} via ${message.status}")
                },
                onFailure = { error ->
                    _sendState.value = MeshSendState.Error(error.message ?: "Failed to submit report")
                    Timber.e(error, "$TAG: Failed to submit report")
                }
            )
        }
    }

    /** Reset the send state back to idle */
    fun resetSendState() {
        _sendState.value = MeshSendState.Idle
    }

    // ==================== Tab Selection ====================

    fun selectTab(tab: MeshTab) {
        _selectedTab.value = tab
    }

    // ==================== Capabilities ====================

    private fun updateMeshCapabilities() {
        updateStatus {
            it.copy(
                isBleAvailable = bleMeshManager.isBleAvailable(),
                isCodedPhySupported = bleMeshManager.isCodedPhySupported()
            )
        }

        // Observe reactive peer counts and BLE state from the singleton BleMeshManager
        viewModelScope.launch {
            bleMeshManager.connectedPeerCount.collect { count ->
                updateStatus { it.copy(connectedPeerCount = count) }
            }
        }
        viewModelScope.launch {
            bleMeshManager.discoveredPeerCount.collect { count ->
                updateStatus { it.copy(discoveredPeerCount = count) }
            }
        }
        viewModelScope.launch {
            bleMeshManager.isRunningFlow.collect { running ->
                updateStatus { it.copy(isRunning = running) }
            }
        }
        viewModelScope.launch {
            bleMeshManager.isAdvertisingFlow.collect { adv ->
                updateStatus { it.copy(isAdvertising = adv) }
            }
        }
        viewModelScope.launch {
            bleMeshManager.isScanningFlow.collect { scan ->
                updateStatus { it.copy(isScanning = scan) }
            }
        }
    }

    private fun observeCounters() {
        viewModelScope.launch {
            allMessages.collect { messages ->
                updateStatus {
                    it.copy(
                        pendingMessageCount = messages.count {
                            m -> m.status in listOf(MeshMessageStatus.PENDING, MeshMessageStatus.SENDING, MeshMessageStatus.FAILED)
                        },
                        deliveredMessageCount = messages.count { m -> m.status == MeshMessageStatus.DELIVERED },
                        relayedMessageCount = messages.count { m -> m.hopCount > 0 }
                    )
                }
            }
        }
    }

    private fun updateStatus(update: (MeshNetworkStatus) -> MeshNetworkStatus) {
        _meshStatus.value = update(_meshStatus.value)
    }

    fun clearError() {
        _error.value = null
    }
}

/**
 * State for mesh message sending
 */
sealed class MeshSendState {
    data object Idle : MeshSendState()
    data object Sending : MeshSendState()
    data class Success(
        val messageId: String,
        val transport: MeshTransport,
        val status: MeshMessageStatus
    ) : MeshSendState()
    data class Error(val message: String) : MeshSendState()
}

/**
 * Tabs for the mesh screen
 */
enum class MeshTab(val title: String) {
    ALL("All"),
    QUEUE("Queue"),
    DELIVERED("Delivered"),
    RELAYED("Relayed"),
    PEERS("Peers")
}
