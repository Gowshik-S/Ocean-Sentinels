package com.oceansentinels.app.presentation.ui.screens.mesh

import android.Manifest
import android.os.Build
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.rememberMultiplePermissionsState
import com.oceansentinels.app.domain.model.HazardType
import com.oceansentinels.app.domain.model.UrgencyLevel
import com.oceansentinels.app.mesh.model.MeshMessage
import com.oceansentinels.app.mesh.model.MeshMessageStatus
import com.oceansentinels.app.mesh.model.MeshTransport
import com.oceansentinels.app.presentation.ui.theme.OceanColors
import com.oceansentinels.app.presentation.viewmodel.MeshSendState
import com.oceansentinels.app.presentation.viewmodel.MeshTab
import com.oceansentinels.app.presentation.viewmodel.MeshViewModel
import java.text.SimpleDateFormat
import java.util.*

/**
 * Mesh Network Screen — dedicated UI for mesh-based hazard reporting and message tracking.
 *
 * Features:
 * - Mesh service toggle (start/stop BLE mesh)
 * - Quick hazard report form with mesh delivery
 * - Message queue with status tracking (pending/delivered/relayed)
 * - Peer list showing connected BLE devices
 * - Transport indicator (Internet / BLE Coded / BLE Standard / Local Queue)
 */
@OptIn(ExperimentalMaterial3Api::class, ExperimentalPermissionsApi::class)
@Composable
fun MeshNetworkScreen(
    onNavigateBack: () -> Unit,
    onNavigateToHome: () -> Unit = {},
    onNavigateToAlerts: () -> Unit = {},
    onNavigateToWeather: () -> Unit = {},
    onNavigateToReport: () -> Unit = {},
    onNavigateToProfile: () -> Unit = {},
    viewModel: MeshViewModel = hiltViewModel()
) {
    val meshStatus by viewModel.meshStatus.collectAsState()
    val isServiceRunning by viewModel.isServiceRunning.collectAsState()
    val sendState by viewModel.sendState.collectAsState()
    val selectedTab by viewModel.selectedTab.collectAsState()
    val pendingMessages by viewModel.pendingMessages.collectAsState()
    val deliveredMessages by viewModel.deliveredMessages.collectAsState()
    val relayedMessages by viewModel.relayedMessages.collectAsState()
    val allMessages by viewModel.allMessages.collectAsState()

    // BLE permissions
    val blePermissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        listOf(
            Manifest.permission.BLUETOOTH_SCAN,
            Manifest.permission.BLUETOOTH_ADVERTISE,
            Manifest.permission.BLUETOOTH_CONNECT,
            Manifest.permission.ACCESS_FINE_LOCATION
        )
    } else {
        listOf(Manifest.permission.ACCESS_FINE_LOCATION)
    }

    val permissionsState = rememberMultiplePermissionsState(blePermissions)

    // Quick report form state
    var showReportForm by remember { mutableStateOf(false) }
    var description by remember { mutableStateOf("") }
    var selectedHazardType by remember { mutableStateOf<HazardType?>(null) }
    var selectedUrgency by remember { mutableStateOf(UrgencyLevel.MEDIUM) }
    var latitude by remember { mutableStateOf("") }
    var longitude by remember { mutableStateOf("") }

    // Handle send success
    LaunchedEffect(sendState) {
        if (sendState is MeshSendState.Success) {
            showReportForm = false
            description = ""
            selectedHazardType = null
            latitude = ""
            longitude = ""
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            Icons.Default.Hub,
                            contentDescription = null,
                            modifier = Modifier.size(24.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Mesh Network")
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    // Mesh toggle
                    Switch(
                        checked = isServiceRunning,
                        onCheckedChange = {
                            if (!permissionsState.allPermissionsGranted) {
                                permissionsState.launchMultiplePermissionRequest()
                            } else {
                                viewModel.toggleMeshService()
                            }
                        },
                        colors = SwitchDefaults.colors(
                            checkedTrackColor = OceanColors.Success,
                            checkedThumbColor = Color.White
                        )
                    )
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { showReportForm = !showReportForm },
                containerColor = OceanColors.Primary
            ) {
                Icon(
                    if (showReportForm) Icons.Default.Close else Icons.Default.Add,
                    contentDescription = "Report Hazard"
                )
            }
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // ==================== Status Banner ====================
            item {
                Spacer(modifier = Modifier.height(8.dp))
                MeshStatusBanner(
                    isRunning = isServiceRunning,
                    isBleAvailable = meshStatus.isBleAvailable,
                    isCodedPhySupported = meshStatus.isCodedPhySupported,
                    connectedPeers = meshStatus.connectedPeerCount,
                    nearbyDevices = meshStatus.discoveredPeerCount,
                    pendingCount = pendingMessages.size,
                    deliveredCount = deliveredMessages.size,
                    relayedCount = relayedMessages.size
                )
            }

            // ==================== Permissions Warning ====================
            if (!permissionsState.allPermissionsGranted) {
                item {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(
                            containerColor = OceanColors.Warning.copy(alpha = 0.1f)
                        )
                    ) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    Icons.Default.Warning,
                                    contentDescription = null,
                                    tint = OceanColors.Warning
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    "BLE permissions required for mesh networking",
                                    fontWeight = FontWeight.SemiBold
                                )
                            }
                            Spacer(modifier = Modifier.height(8.dp))
                            Button(
                                onClick = { permissionsState.launchMultiplePermissionRequest() },
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = OceanColors.Warning
                                )
                            ) {
                                Text("Grant Permissions")
                            }
                        }
                    }
                }
            }

            // ==================== Send State Feedback ====================
            if (sendState != MeshSendState.Idle) {
                item {
                    SendStateBanner(
                        sendState = sendState,
                        onDismiss = { viewModel.resetSendState() }
                    )
                }
            }

            // ==================== Quick Report Form ====================
            if (showReportForm) {
                item {
                    QuickReportForm(
                        description = description,
                        onDescriptionChange = { description = it },
                        selectedHazardType = selectedHazardType,
                        onHazardTypeChange = { selectedHazardType = it },
                        selectedUrgency = selectedUrgency,
                        onUrgencyChange = { selectedUrgency = it },
                        latitude = latitude,
                        onLatitudeChange = { latitude = it },
                        longitude = longitude,
                        onLongitudeChange = { longitude = it },
                        isSending = sendState is MeshSendState.Sending,
                        onSubmit = {
                            val hazard = selectedHazardType ?: return@QuickReportForm
                            viewModel.reportHazard(
                                hazardType = hazard,
                                location = "$latitude, $longitude",
                                latitude = latitude.toDoubleOrNull(),
                                longitude = longitude.toDoubleOrNull(),
                                description = description,
                                urgency = selectedUrgency
                            )
                        }
                    )
                }
            }

            // ==================== Tab Selector ====================
            item {
                MeshTabRow(
                    selectedTab = selectedTab,
                    pendingCount = pendingMessages.size,
                    deliveredCount = deliveredMessages.size,
                    relayedCount = relayedMessages.size,
                    onTabSelected = { viewModel.selectTab(it) }
                )
            }

            // ==================== Message List ====================
            val currentMessages = when (selectedTab) {
                MeshTab.QUEUE -> pendingMessages
                MeshTab.DELIVERED -> deliveredMessages
                MeshTab.RELAYED -> relayedMessages
                MeshTab.PEERS -> emptyList() // Peers are shown separately
            }

            if (selectedTab == MeshTab.PEERS) {
                item {
                    PeersSection(
                        isRunning = isServiceRunning,
                        connectedCount = meshStatus.connectedPeerCount,
                        discoveredCount = meshStatus.discoveredPeerCount
                    )
                }
            } else if (currentMessages.isEmpty()) {
                item {
                    EmptyStateCard(selectedTab)
                }
            } else {
                items(currentMessages, key = { it.messageId }) { message ->
                    MeshMessageCard(message = message)
                }
            }

            item { Spacer(modifier = Modifier.height(80.dp)) }
        }
    }
}

// ==================== Components ====================

@Composable
private fun MeshStatusBanner(
    isRunning: Boolean,
    isBleAvailable: Boolean,
    isCodedPhySupported: Boolean,
    connectedPeers: Int,
    nearbyDevices: Int,
    pendingCount: Int,
    deliveredCount: Int,
    relayedCount: Int
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = if (isRunning) OceanColors.Primary.copy(alpha = 0.1f)
            else MaterialTheme.colorScheme.surfaceVariant
        ),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .size(12.dp)
                        .clip(CircleShape)
                        .background(
                            if (isRunning) OceanColors.Success else Color.Gray
                        )
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = if (isRunning) "Mesh Active" else "Mesh Inactive",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.weight(1f))
                if (isCodedPhySupported) {
                    Surface(
                        shape = RoundedCornerShape(4.dp),
                        color = OceanColors.Info.copy(alpha = 0.2f)
                    ) {
                        Text(
                            "PHY Coded",
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp),
                            style = MaterialTheme.typography.labelSmall,
                            color = OceanColors.Info,
                            fontWeight = FontWeight.Bold
                        )
                    }
                } else {
                    Surface(
                        shape = RoundedCornerShape(4.dp),
                        color = OceanColors.Warning.copy(alpha = 0.2f)
                    ) {
                        Text(
                            "Standard BLE",
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp),
                            style = MaterialTheme.typography.labelSmall,
                            color = OceanColors.Warning,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }

            if (!isBleAvailable) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    "Bluetooth is disabled or unavailable",
                    style = MaterialTheme.typography.bodySmall,
                    color = OceanColors.Danger
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                StatItem(
                    icon = Icons.Default.Sensors,
                    value = "$nearbyDevices",
                    label = "Nearby",
                    color = OceanColors.Primary
                )
                StatItem(
                    icon = Icons.Default.People,
                    value = "$connectedPeers",
                    label = "Connected",
                    color = OceanColors.Info
                )
                StatItem(
                    icon = Icons.Default.Schedule,
                    value = "$pendingCount",
                    label = "Pending",
                    color = OceanColors.Warning
                )
                StatItem(
                    icon = Icons.Default.CheckCircle,
                    value = "$deliveredCount",
                    label = "Delivered",
                    color = OceanColors.Success
                )
                StatItem(
                    icon = Icons.Default.Share,
                    value = "$relayedCount",
                    label = "Relayed",
                    color = OceanColors.Primary
                )
            }
        }
    }
}

@Composable
private fun StatItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    value: String,
    label: String,
    color: Color
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(20.dp))
        Text(
            text = value,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = color
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun SendStateBanner(
    sendState: MeshSendState,
    onDismiss: () -> Unit
) {
    val (color, icon, text) = when (sendState) {
        is MeshSendState.Sending -> Triple(
            OceanColors.Info,
            Icons.Default.CloudUpload,
            "Sending report..."
        )
        is MeshSendState.Success -> {
            val transportText = when (sendState.transport) {
                MeshTransport.INTERNET -> "Sent via Internet"
                MeshTransport.BLE_CODED -> "Sent via BLE Mesh (Long Range)"
                MeshTransport.BLE_STANDARD -> "Sent via BLE (Standard)"
                MeshTransport.LOCAL_QUEUE -> "Queued locally — will relay when peers available"
            }
            Triple(OceanColors.Success, Icons.Default.CheckCircle, transportText)
        }
        is MeshSendState.Error -> Triple(
            OceanColors.Danger,
            Icons.Default.Error,
            "Error: ${sendState.message}"
        )
        else -> return
    }

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = color.copy(alpha = 0.1f))
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (sendState is MeshSendState.Sending) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    strokeWidth = 2.dp,
                    color = color
                )
            } else {
                Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(20.dp))
            }
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = text,
                style = MaterialTheme.typography.bodySmall,
                color = color,
                modifier = Modifier.weight(1f)
            )
            if (sendState !is MeshSendState.Sending) {
                IconButton(onClick = onDismiss, modifier = Modifier.size(24.dp)) {
                    Icon(Icons.Default.Close, contentDescription = "Dismiss", modifier = Modifier.size(16.dp))
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun QuickReportForm(
    description: String,
    onDescriptionChange: (String) -> Unit,
    selectedHazardType: HazardType?,
    onHazardTypeChange: (HazardType) -> Unit,
    selectedUrgency: UrgencyLevel,
    onUrgencyChange: (UrgencyLevel) -> Unit,
    latitude: String,
    onLatitudeChange: (String) -> Unit,
    longitude: String,
    onLongitudeChange: (String) -> Unit,
    isSending: Boolean,
    onSubmit: () -> Unit
) {
    var hazardExpanded by remember { mutableStateOf(false) }
    var urgencyExpanded by remember { mutableStateOf(false) }

    val isValid = description.isNotBlank() && selectedHazardType != null

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = OceanColors.Primary.copy(alpha = 0.05f)
        )
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                "Quick Mesh Report",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Text(
                "Auto-routes via Internet → Mesh → Local Queue",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(12.dp))

            // Description
            OutlinedTextField(
                value = description,
                onValueChange = onDescriptionChange,
                label = { Text("Description *") },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                maxLines = 3
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Hazard Type
            ExposedDropdownMenuBox(
                expanded = hazardExpanded,
                onExpandedChange = { hazardExpanded = !hazardExpanded }
            ) {
                OutlinedTextField(
                    value = selectedHazardType?.displayName ?: "",
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("Hazard Type *") },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = hazardExpanded) },
                    modifier = Modifier.fillMaxWidth().menuAnchor(),
                    shape = RoundedCornerShape(12.dp)
                )
                ExposedDropdownMenu(
                    expanded = hazardExpanded,
                    onDismissRequest = { hazardExpanded = false }
                ) {
                    HazardType.entries.forEach { type ->
                        DropdownMenuItem(
                            text = { Text(type.displayName) },
                            onClick = {
                                onHazardTypeChange(type)
                                hazardExpanded = false
                            }
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Urgency
            ExposedDropdownMenuBox(
                expanded = urgencyExpanded,
                onExpandedChange = { urgencyExpanded = !urgencyExpanded }
            ) {
                OutlinedTextField(
                    value = selectedUrgency.displayName,
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("Urgency") },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = urgencyExpanded) },
                    modifier = Modifier.fillMaxWidth().menuAnchor(),
                    shape = RoundedCornerShape(12.dp)
                )
                ExposedDropdownMenu(
                    expanded = urgencyExpanded,
                    onDismissRequest = { urgencyExpanded = false }
                ) {
                    UrgencyLevel.entries.forEach { level ->
                        DropdownMenuItem(
                            text = { Text(level.displayName) },
                            onClick = {
                                onUrgencyChange(level)
                                urgencyExpanded = false
                            }
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Lat/Lng
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(
                    value = latitude,
                    onValueChange = onLatitudeChange,
                    label = { Text("Latitude") },
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(12.dp)
                )
                OutlinedTextField(
                    value = longitude,
                    onValueChange = onLongitudeChange,
                    label = { Text("Longitude") },
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(12.dp)
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Submit
            Button(
                onClick = onSubmit,
                enabled = isValid && !isSending,
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(containerColor = OceanColors.Primary)
            ) {
                if (isSending) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        strokeWidth = 2.dp,
                        color = Color.White
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                }
                Icon(Icons.Default.Send, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Send via Mesh")
            }
        }
    }
}

@Composable
private fun MeshTabRow(
    selectedTab: MeshTab,
    pendingCount: Int,
    deliveredCount: Int,
    relayedCount: Int,
    onTabSelected: (MeshTab) -> Unit
) {
    TabRow(
        selectedTabIndex = selectedTab.ordinal,
        containerColor = Color.Transparent,
        contentColor = OceanColors.Primary,
        modifier = Modifier.clip(RoundedCornerShape(12.dp))
    ) {
        MeshTab.entries.forEach { tab ->
            val count = when (tab) {
                MeshTab.QUEUE -> pendingCount
                MeshTab.DELIVERED -> deliveredCount
                MeshTab.RELAYED -> relayedCount
                MeshTab.PEERS -> 0
            }

            Tab(
                selected = selectedTab == tab,
                onClick = { onTabSelected(tab) },
                text = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(tab.title, maxLines = 1)
                        if (count > 0) {
                            Spacer(modifier = Modifier.width(4.dp))
                            Badge { Text("$count") }
                        }
                    }
                }
            )
        }
    }
}

@Composable
private fun MeshMessageCard(message: MeshMessage) {
    val dateFormat = remember { SimpleDateFormat("MMM dd, HH:mm", Locale.getDefault()) }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                // Status indicator
                val statusColor = when (message.status) {
                    MeshMessageStatus.PENDING -> OceanColors.Warning
                    MeshMessageStatus.SENDING -> OceanColors.Info
                    MeshMessageStatus.RELAYED -> OceanColors.Primary
                    MeshMessageStatus.DELIVERED -> OceanColors.Success
                    MeshMessageStatus.FAILED -> OceanColors.Danger
                }
                Box(
                    modifier = Modifier
                        .size(10.dp)
                        .clip(CircleShape)
                        .background(statusColor)
                )
                Spacer(modifier = Modifier.width(8.dp))

                // Hazard type
                val hazardType = try {
                    HazardType.fromValue(message.hazardType)
                } catch (e: Exception) {
                    HazardType.OTHER
                }
                Text(
                    text = hazardType.displayName,
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.weight(1f)
                )

                // Urgency badge
                val urgencyColor = when (message.urgency) {
                    "critical" -> OceanColors.Danger
                    "high" -> OceanColors.Orange
                    "medium" -> OceanColors.Warning
                    else -> OceanColors.Success
                }
                Surface(
                    shape = RoundedCornerShape(4.dp),
                    color = urgencyColor.copy(alpha = 0.2f)
                ) {
                    Text(
                        text = message.urgency.replaceFirstChar { it.uppercase() },
                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                        style = MaterialTheme.typography.labelSmall,
                        color = urgencyColor,
                        fontWeight = FontWeight.Bold
                    )
                }

                // Mesh Relayed badge — shown for delivered messages that were relayed via BLE mesh
                if (message.hopCount > 0 && message.status == MeshMessageStatus.DELIVERED) {
                    Spacer(modifier = Modifier.width(6.dp))
                    Surface(
                        shape = RoundedCornerShape(4.dp),
                        color = OceanColors.Primary.copy(alpha = 0.15f)
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Default.Bluetooth,
                                contentDescription = null,
                                modifier = Modifier.size(10.dp),
                                tint = OceanColors.Primary
                            )
                            Spacer(modifier = Modifier.width(3.dp))
                            Text(
                                text = "Relayed",
                                style = MaterialTheme.typography.labelSmall,
                                color = OceanColors.Primary,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(4.dp))

            // Description
            Text(
                text = message.description,
                style = MaterialTheme.typography.bodySmall,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Bottom row: time, hops, message ID
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Time
                Icon(
                    Icons.Default.AccessTime,
                    contentDescription = null,
                    modifier = Modifier.size(14.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.width(2.dp))
                Text(
                    text = dateFormat.format(Date(message.createdAtMillis)),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Spacer(modifier = Modifier.width(12.dp))

                // Hops
                if (message.hopCount > 0) {
                    Icon(
                        Icons.Default.Route,
                        contentDescription = null,
                        modifier = Modifier.size(14.dp),
                        tint = OceanColors.Primary
                    )
                    Spacer(modifier = Modifier.width(2.dp))
                    Text(
                        text = "${message.hopCount} hops",
                        style = MaterialTheme.typography.labelSmall,
                        color = OceanColors.Primary
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                }

                // TTL
                Text(
                    text = "TTL: ${message.ttl}",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Spacer(modifier = Modifier.weight(1f))

                // Status text
                Text(
                    text = message.status.value.replaceFirstChar { it.uppercase() },
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.SemiBold,
                    color = when (message.status) {
                        MeshMessageStatus.DELIVERED -> OceanColors.Success
                        MeshMessageStatus.FAILED -> OceanColors.Danger
                        MeshMessageStatus.RELAYED -> OceanColors.Primary
                        else -> OceanColors.Warning
                    }
                )
            }

            // Message ID (truncated)
            Text(
                text = "ID: ${message.messageId.take(12)}...",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
            )
        }
    }
}

@Composable
private fun PeersSection(
    isRunning: Boolean,
    connectedCount: Int,
    discoveredCount: Int
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                Icons.Default.BluetoothSearching,
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = if (isRunning) OceanColors.Primary else Color.Gray
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = if (isRunning) "$discoveredCount nearby mesh devices"
                else "Mesh service is not running",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold
            )
            if (isRunning) {
                Text(
                    text = "$connectedCount connected  •  $discoveredCount discovered",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Peers with Ocean Sentinels installed will auto-relay your hazard reports " +
                            "when you have no internet connection.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            } else {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Toggle the mesh switch to start scanning for nearby Ocean Sentinels devices.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun EmptyStateCard(tab: MeshTab) {
    val (icon, title, subtitle) = when (tab) {
        MeshTab.QUEUE -> Triple(
            Icons.Default.Inbox,
            "No pending messages",
            "Your reports will queue here when internet is unavailable"
        )
        MeshTab.DELIVERED -> Triple(
            Icons.Default.CloudDone,
            "No delivered messages",
            "Successfully sent reports will appear here"
        )
        MeshTab.RELAYED -> Triple(
            Icons.Default.Share,
            "No relayed messages",
            "Messages relayed from other users will appear here"
        )
        MeshTab.PEERS -> Triple(
            Icons.Default.BluetoothSearching,
            "No peers found",
            "Start the mesh service to discover nearby devices"
        )
    }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
        )
    ) {
        Column(
            modifier = Modifier
                .padding(32.dp)
                .fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                icon,
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = title,
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
            )
        }
    }
}
