package com.oceansentinels.app.presentation.ui.screens.authority

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.oceansentinels.app.domain.model.*
import com.oceansentinels.app.presentation.ui.components.OceanBottomNavBar
import com.oceansentinels.app.presentation.ui.theme.OceanColors
import com.oceansentinels.app.presentation.viewmodel.AdminViewModel
import com.oceansentinels.app.presentation.viewmodel.AssignState
import com.oceansentinels.app.presentation.viewmodel.AuthViewModel
import com.oceansentinels.app.presentation.viewmodel.IncidentViewModel

/**
 * Authority Console — dedicated screen for authority users.
 * Authority can verify incidents, oversee deployments, assign rescue teams,
 * and monitor all incident activity in their jurisdiction.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AuthorityConsoleScreen(
    onNavigateBack: () -> Unit,
    onNavigateToHome: () -> Unit,
    onNavigateToAlerts: () -> Unit,
    onNavigateToWeather: () -> Unit,
    onNavigateToReport: () -> Unit,
    onNavigateToProfile: () -> Unit,
    onNavigateToDetail: (Int) -> Unit,
    onNavigateToAdmin: (() -> Unit)? = null,
    onNavigateToMesh: (() -> Unit)? = null,
    incidentViewModel: IncidentViewModel = hiltViewModel(),
    adminViewModel: AdminViewModel = hiltViewModel(),
    authViewModel: AuthViewModel = hiltViewModel()
) {
    val incidents by incidentViewModel.incidents.collectAsState()
    val isLoading by incidentViewModel.isLoading.collectAsState()
    val error by incidentViewModel.error.collectAsState()
    val assignState by incidentViewModel.assignState.collectAsState()
    val rescueTeams by adminViewModel.rescueTeams.collectAsState()
    val userSession by authViewModel.userSession.collectAsState()
    val currentUser = (userSession as? UserSession.Authenticated)?.user

    var selectedFilter by remember { mutableStateOf("all") }
    var showAssignDialog by remember { mutableStateOf(false) }
    var selectedIncidentId by remember { mutableIntStateOf(0) }

    LaunchedEffect(Unit) {
        incidentViewModel.loadIncidents()
        adminViewModel.loadAllUsers()
    }

    LaunchedEffect(assignState) {
        if (assignState is AssignState.Success) {
            showAssignDialog = false
            incidentViewModel.resetAssignState()
            incidentViewModel.loadIncidents()
        }
    }

    val filteredIncidents = remember(incidents, selectedFilter) {
        when (selectedFilter) {
            "pending" -> incidents.filter { it.status == IncidentStatus.PENDING }
            "verified" -> incidents.filter { it.status == IncidentStatus.VERIFIED }
            "in_progress" -> incidents.filter { it.status == IncidentStatus.IN_PROGRESS }
            "resolved" -> incidents.filter { it.status == IncidentStatus.RESOLVED }
            "critical" -> incidents.filter { it.urgency == UrgencyLevel.CRITICAL || it.urgency == UrgencyLevel.HIGH }
            else -> incidents
        }
    }

    val pendingVerification = incidents.count { it.status == IncidentStatus.PENDING }
    val activeOperations = incidents.count { it.isActive }
    val criticalCount = incidents.count { it.urgency == UrgencyLevel.CRITICAL }
    val resolvedToday = incidents.count { it.status == IncidentStatus.RESOLVED }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text("Authority Console")
                        Text(
                            text = "${currentUser?.fullName ?: "Authority"} - Oversight Dashboard",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = { incidentViewModel.loadIncidents() }) {
                        Icon(Icons.Default.Refresh, contentDescription = "Refresh")
                    }
                }
            )
        },
        bottomBar = {
            OceanBottomNavBar(
                activeTab = "authority",
                onNavigateToHome = onNavigateToHome,
                onNavigateToAlerts = onNavigateToAlerts,
                onNavigateToWeather = onNavigateToWeather,
                onNavigateToReport = onNavigateToReport,
                onNavigateToProfile = onNavigateToProfile,
                userRole = UserRole.AUTHORITY,
                onNavigateToAdmin = onNavigateToAdmin,
                onNavigateToMesh = onNavigateToMesh
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Stats row
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                AuthorityStatChip("Verify", pendingVerification, OceanColors.Warning, Modifier.weight(1f))
                AuthorityStatChip("Active", activeOperations, OceanColors.Error, Modifier.weight(1f))
                AuthorityStatChip("Critical", criticalCount, OceanColors.Error, Modifier.weight(1f))
                AuthorityStatChip("Resolved", resolvedToday, OceanColors.Success, Modifier.weight(1f))
            }

            // Filter chips
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                listOf(
                    "all" to "All",
                    "pending" to "Pending",
                    "verified" to "Verified",
                    "in_progress" to "In Progress",
                    "critical" to "Critical",
                    "resolved" to "Resolved"
                ).forEach { (key, label) ->
                    FilterChip(
                        selected = selectedFilter == key,
                        onClick = { selectedFilter = key },
                        label = { Text(label, style = MaterialTheme.typography.labelSmall) }
                    )
                }
            }

            // Error
            if (error != null) {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 4.dp),
                    colors = CardDefaults.cardColors(containerColor = OceanColors.Error.copy(alpha = 0.1f))
                ) {
                    Text(
                        text = error ?: "",
                        modifier = Modifier.padding(12.dp),
                        color = OceanColors.Error,
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }

            if (assignState is AssignState.Error) {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 4.dp),
                    colors = CardDefaults.cardColors(containerColor = OceanColors.Error.copy(alpha = 0.1f))
                ) {
                    Text(
                        text = (assignState as AssignState.Error).message,
                        modifier = Modifier.padding(12.dp),
                        color = OceanColors.Error,
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }

            if (isLoading && incidents.isEmpty()) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(color = OceanColors.DashboardBlue)
                }
            } else if (filteredIncidents.isEmpty()) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            Icons.Default.VerifiedUser,
                            contentDescription = null,
                            modifier = Modifier.size(48.dp),
                            tint = OceanColors.Success
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "No incidents found",
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    items(filteredIncidents, key = { it.id }) { incident ->
                        AuthorityIncidentCard(
                            incident = incident,
                            rescueTeams = rescueTeams,
                            onViewDetail = { onNavigateToDetail(incident.id) },
                            onVerify = { incidentViewModel.verifyIncident(incident.id) },
                            onDeploy = { incidentViewModel.deployResponse(incident.id) },
                            onResolve = { incidentViewModel.resolveIncident(incident.id) },
                            onAssign = {
                                selectedIncidentId = incident.id
                                showAssignDialog = true
                            }
                        )
                    }
                }
            }
        }
    }

    // Assign dialog
    if (showAssignDialog) {
        AuthorityAssignDialog(
            rescueTeams = rescueTeams,
            isLoading = assignState is AssignState.Loading,
            onAssign = { userId ->
                incidentViewModel.assignIncident(selectedIncidentId, userId)
            },
            onDismiss = {
                showAssignDialog = false
                incidentViewModel.resetAssignState()
            }
        )
    }
}

@Composable
private fun AuthorityStatChip(
    label: String,
    count: Int,
    color: androidx.compose.ui.graphics.Color,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(containerColor = color.copy(alpha = 0.12f)),
        shape = RoundedCornerShape(8.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 8.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = count.toString(),
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = color
            )
            Text(text = label, style = MaterialTheme.typography.labelSmall, color = color)
        }
    }
}

@Composable
private fun AuthorityIncidentCard(
    incident: Incident,
    rescueTeams: List<User>,
    onViewDetail: () -> Unit,
    onVerify: () -> Unit,
    onDeploy: () -> Unit,
    onResolve: () -> Unit,
    onAssign: () -> Unit
) {
    val statusColor = when (incident.status) {
        IncidentStatus.PENDING -> OceanColors.Warning
        IncidentStatus.VERIFIED -> OceanColors.Info
        IncidentStatus.IN_PROGRESS -> OceanColors.DashboardBlue
        IncidentStatus.RESOLVED -> OceanColors.Success
        IncidentStatus.CLOSED -> OceanColors.Gray
    }

    val urgencyColor = when (incident.urgency) {
        UrgencyLevel.CRITICAL -> OceanColors.Error
        UrgencyLevel.HIGH -> OceanColors.Warning
        UrgencyLevel.MEDIUM -> OceanColors.Info
        UrgencyLevel.LOW -> OceanColors.Success
    }

    val assignedTeamName = if (incident.assignedToId != null) {
        rescueTeams.find { it.id == incident.assignedToId }?.fullName ?: "Team #${incident.assignedToId}"
    } else null

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        shape = RoundedCornerShape(10.dp)
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = incident.referenceId,
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    // Urgency badge
                    Surface(
                        color = urgencyColor.copy(alpha = 0.15f),
                        shape = RoundedCornerShape(4.dp)
                    ) {
                        Text(
                            text = incident.urgency.displayName,
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                            style = MaterialTheme.typography.labelSmall,
                            color = urgencyColor,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                    // Status badge
                    Surface(
                        color = statusColor.copy(alpha = 0.15f),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Text(
                            text = incident.status.displayName,
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
                            style = MaterialTheme.typography.labelSmall,
                            color = statusColor,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(6.dp))

            // Hazard info
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    Icons.Default.Warning,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp),
                    tint = statusColor
                )
                Spacer(modifier = Modifier.width(6.dp))
                Text(
                    text = incident.hazardType.displayName,
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold
                )
            }

            Spacer(modifier = Modifier.height(4.dp))

            // Location
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    Icons.Default.LocationOn,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = incident.location,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            // Description
            if (incident.description.isNotBlank()) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = incident.description.take(100) + if (incident.description.length > 100) "..." else "",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 2
                )
            }

            // Assigned team
            if (assignedTeamName != null) {
                Spacer(modifier = Modifier.height(6.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Default.PersonPin,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = OceanColors.DashboardBlue
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "Assigned to: $assignedTeamName",
                        style = MaterialTheme.typography.labelSmall,
                        color = OceanColors.DashboardBlue,
                        fontWeight = FontWeight.Medium
                    )
                }
            }

            Spacer(modifier = Modifier.height(10.dp))
            HorizontalDivider()
            Spacer(modifier = Modifier.height(8.dp))

            // Action buttons
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                OutlinedButton(
                    onClick = onViewDetail,
                    modifier = Modifier.height(32.dp),
                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 0.dp)
                ) {
                    Icon(Icons.Default.Visibility, contentDescription = null, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("View", style = MaterialTheme.typography.labelSmall)
                }

                // Assign/Reassign for non-resolved
                if (incident.status != IncidentStatus.RESOLVED && incident.status != IncidentStatus.CLOSED) {
                    Button(
                        onClick = onAssign,
                        modifier = Modifier.height(32.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = OceanColors.DashboardBlue),
                        contentPadding = PaddingValues(horizontal = 10.dp, vertical = 0.dp)
                    ) {
                        Icon(Icons.Default.AssignmentInd, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            if (incident.assignedToId == null) "Assign" else "Reassign",
                            style = MaterialTheme.typography.labelSmall
                        )
                    }
                }

                Spacer(modifier = Modifier.weight(1f))

                // Status actions
                when {
                    incident.canBeVerified -> {
                        Button(
                            onClick = onVerify,
                            modifier = Modifier.height(32.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = OceanColors.Info),
                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 0.dp)
                        ) {
                            Icon(Icons.Default.VerifiedUser, contentDescription = null, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Verify", style = MaterialTheme.typography.labelSmall)
                        }
                    }
                    incident.canBeDeployed -> {
                        Button(
                            onClick = onDeploy,
                            modifier = Modifier.height(32.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = OceanColors.Warning),
                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 0.dp)
                        ) {
                            Text("Deploy", style = MaterialTheme.typography.labelSmall)
                        }
                    }
                    incident.canBeResolved -> {
                        Button(
                            onClick = onResolve,
                            modifier = Modifier.height(32.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = OceanColors.Success),
                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 0.dp)
                        ) {
                            Text("Resolve", style = MaterialTheme.typography.labelSmall)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun AuthorityAssignDialog(
    rescueTeams: List<User>,
    isLoading: Boolean,
    onAssign: (Int) -> Unit,
    onDismiss: () -> Unit
) {
    var selectedUserId by remember { mutableIntStateOf(0) }

    AlertDialog(
        onDismissRequest = onDismiss,
        icon = {
            Icon(
                Icons.Default.AssignmentInd,
                contentDescription = null,
                tint = OceanColors.DashboardBlue
            )
        },
        title = { Text("Assign to Rescue Team") },
        text = {
            Column {
                if (rescueTeams.isEmpty()) {
                    Text(
                        text = "No rescue teams available. Contact admin to create one.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                } else {
                    Text(
                        text = "Select a rescue team member:",
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = Modifier.padding(bottom = 8.dp)
                    )
                    rescueTeams.forEach { user ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            RadioButton(
                                selected = selectedUserId == user.id,
                                onClick = { selectedUserId = user.id }
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Column {
                                Text(
                                    text = user.fullName,
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.Medium
                                )
                                Text(
                                    text = user.email,
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    }
                }
                if (isLoading) {
                    Spacer(modifier = Modifier.height(8.dp))
                    LinearProgressIndicator(
                        modifier = Modifier.fillMaxWidth(),
                        color = OceanColors.DashboardBlue
                    )
                }
            }
        },
        confirmButton = {
            Button(
                onClick = { onAssign(selectedUserId) },
                enabled = selectedUserId > 0 && !isLoading && rescueTeams.isNotEmpty(),
                colors = ButtonDefaults.buttonColors(containerColor = OceanColors.DashboardBlue)
            ) {
                Text("Assign")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}
