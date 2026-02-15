package com.oceansentinels.app.presentation.ui.screens.rescue

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
import com.oceansentinels.app.presentation.viewmodel.AuthViewModel
import com.oceansentinels.app.presentation.viewmodel.IncidentViewModel

/**
 * Rescue Console — dedicated screen for rescue team members to manage their assigned jobs.
 * Shows assigned incidents with ability to update status (deploy/resolve).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RescueConsoleScreen(
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
    authViewModel: AuthViewModel = hiltViewModel()
) {
    val assignedIncidents by incidentViewModel.assignedIncidents.collectAsState()
    val isLoading by incidentViewModel.isLoading.collectAsState()
    val error by incidentViewModel.error.collectAsState()
    val userSession by authViewModel.userSession.collectAsState()
    val currentUser = (userSession as? UserSession.Authenticated)?.user

    var selectedFilter by remember { mutableStateOf("all") }

    LaunchedEffect(Unit) {
        incidentViewModel.loadAssignedIncidents()
    }

    val filteredIncidents = remember(assignedIncidents, selectedFilter) {
        when (selectedFilter) {
            "active" -> assignedIncidents.filter { it.status == IncidentStatus.IN_PROGRESS }
            "pending" -> assignedIncidents.filter { it.status == IncidentStatus.VERIFIED }
            "completed" -> assignedIncidents.filter { it.status == IncidentStatus.RESOLVED }
            else -> assignedIncidents
        }
    }

    val activeCount = assignedIncidents.count { it.status == IncidentStatus.IN_PROGRESS }
    val pendingCount = assignedIncidents.count { it.status == IncidentStatus.VERIFIED }
    val completedCount = assignedIncidents.count { it.status == IncidentStatus.RESOLVED }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text("Rescue Console")
                        Text(
                            text = "${currentUser?.fullName ?: "Rescue Team"} - ${assignedIncidents.size} assignments",
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
                    IconButton(onClick = { incidentViewModel.loadAssignedIncidents() }) {
                        Icon(Icons.Default.Refresh, contentDescription = "Refresh")
                    }
                }
            )
        },
        bottomBar = {
            OceanBottomNavBar(
                activeTab = "rescue",
                onNavigateToHome = onNavigateToHome,
                onNavigateToAlerts = onNavigateToAlerts,
                onNavigateToWeather = onNavigateToWeather,
                onNavigateToReport = onNavigateToReport,
                onNavigateToProfile = onNavigateToProfile,
                userRole = UserRole.RESCUE_TEAM,
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
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                RescueStatChip("Active", activeCount, OceanColors.Error, Modifier.weight(1f))
                RescueStatChip("Pending", pendingCount, OceanColors.Warning, Modifier.weight(1f))
                RescueStatChip("Done", completedCount, OceanColors.Success, Modifier.weight(1f))
            }

            // Filter row
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                listOf(
                    "all" to "All (${assignedIncidents.size})",
                    "active" to "Active ($activeCount)",
                    "pending" to "Pending ($pendingCount)",
                    "completed" to "Done ($completedCount)"
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

            if (isLoading && assignedIncidents.isEmpty()) {
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
                            Icons.Default.AssignmentTurnedIn,
                            contentDescription = null,
                            modifier = Modifier.size(56.dp),
                            tint = OceanColors.Success
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = if (selectedFilter == "all") "No assigned jobs" else "No jobs in this category",
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Check back later for new assignments",
                            style = MaterialTheme.typography.bodySmall,
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
                        RescueJobCard(
                            incident = incident,
                            onViewDetail = { onNavigateToDetail(incident.id) },
                            onDeploy = {
                                incidentViewModel.deployResponse(incident.id)
                                incidentViewModel.loadAssignedIncidents()
                            },
                            onResolve = {
                                incidentViewModel.resolveIncident(incident.id)
                                incidentViewModel.loadAssignedIncidents()
                            }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun RescueStatChip(
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
                .padding(vertical = 10.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = count.toString(),
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = color
            )
            Text(text = label, style = MaterialTheme.typography.labelSmall, color = color)
        }
    }
}

@Composable
private fun RescueJobCard(
    incident: Incident,
    onViewDetail: () -> Unit,
    onDeploy: () -> Unit,
    onResolve: () -> Unit
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

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        shape = RoundedCornerShape(10.dp)
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            // Header row: reference ID + status + urgency
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

            Spacer(modifier = Modifier.height(8.dp))

            // Hazard type
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
                    text = incident.description.take(120) + if (incident.description.length > 120) "..." else "",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 2
                )
            }

            // Coordinates
            if (incident.hasLocation) {
                Spacer(modifier = Modifier.height(4.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Default.GpsFixed,
                        contentDescription = null,
                        modifier = Modifier.size(14.dp),
                        tint = OceanColors.DashboardBlue
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "%.4f, %.4f".format(incident.latitude, incident.longitude),
                        style = MaterialTheme.typography.labelSmall,
                        color = OceanColors.DashboardBlue
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

                Spacer(modifier = Modifier.weight(1f))

                // Deploy button — for VERIFIED incidents
                if (incident.canBeDeployed) {
                    Button(
                        onClick = onDeploy,
                        modifier = Modifier.height(32.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = OceanColors.Warning),
                        contentPadding = PaddingValues(horizontal = 10.dp, vertical = 0.dp)
                    ) {
                        Icon(Icons.Default.RocketLaunch, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Deploy", style = MaterialTheme.typography.labelSmall)
                    }
                }

                // Resolve button — for IN_PROGRESS incidents
                if (incident.canBeResolved) {
                    Button(
                        onClick = onResolve,
                        modifier = Modifier.height(32.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = OceanColors.Success),
                        contentPadding = PaddingValues(horizontal = 10.dp, vertical = 0.dp)
                    ) {
                        Icon(Icons.Default.CheckCircle, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Resolve", style = MaterialTheme.typography.labelSmall)
                    }
                }

                // Already resolved badge
                if (incident.status == IncidentStatus.RESOLVED) {
                    Surface(
                        color = OceanColors.Success.copy(alpha = 0.15f),
                        shape = RoundedCornerShape(16.dp)
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Default.CheckCircle,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp),
                                tint = OceanColors.Success
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = "Completed",
                                style = MaterialTheme.typography.labelSmall,
                                color = OceanColors.Success,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                }
            }
        }
    }
}
