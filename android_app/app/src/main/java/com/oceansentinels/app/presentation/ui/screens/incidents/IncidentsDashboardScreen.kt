package com.oceansentinels.app.presentation.ui.screens.incidents

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
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.oceansentinels.app.domain.model.*
import com.oceansentinels.app.presentation.ui.components.*
import com.oceansentinels.app.presentation.ui.theme.OceanColors
import com.oceansentinels.app.presentation.viewmodel.AdminViewModel
import com.oceansentinels.app.presentation.viewmodel.AssignState
import com.oceansentinels.app.presentation.viewmodel.AuthViewModel
import com.oceansentinels.app.presentation.viewmodel.IncidentViewModel

/**
 * Incidents dashboard screen with filtering
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun IncidentsDashboardScreen(
    onNavigateBack: () -> Unit,
    onNavigateToDetail: (Int) -> Unit,
    onNavigateToHome: () -> Unit = {},
    onNavigateToAlerts: () -> Unit = {},
    onNavigateToWeather: () -> Unit = {},
    onNavigateToReport: () -> Unit = {},
    onNavigateToProfile: () -> Unit = {},
    onNavigateToAdmin: (() -> Unit)? = null,
    onNavigateToMesh: (() -> Unit)? = null,
    viewModel: IncidentViewModel = hiltViewModel(),
    authViewModel: AuthViewModel = hiltViewModel(),
    adminViewModel: AdminViewModel = hiltViewModel()
) {
    val incidents by viewModel.incidents.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val error by viewModel.error.collectAsState()
    val filters by viewModel.filters.collectAsState()
    val totalCount by viewModel.totalCount.collectAsState()
    val hasMorePages by viewModel.hasMorePages.collectAsState()
    val assignState by viewModel.assignState.collectAsState()
    val rescueTeams by adminViewModel.rescueTeams.collectAsState()
    
    val userSession by authViewModel.userSession.collectAsState()
    val currentUser = (userSession as? UserSession.Authenticated)?.user
    val userRole = currentUser?.role ?: UserRole.PUBLIC
    val isCitizen = userRole == UserRole.PUBLIC
    val canAssign = userRole == UserRole.ADMIN || userRole == UserRole.AUTHORITY
    
    var showFilterSheet by remember { mutableStateOf(false) }
    var showAssignDialog by remember { mutableStateOf(false) }
    var selectedIncidentId by remember { mutableIntStateOf(0) }
    
    // Load incidents on first composition
    LaunchedEffect(Unit) {
        viewModel.loadIncidents()
        if (canAssign) {
            adminViewModel.loadAllUsers()
        }
    }
    
    // Handle assign success
    LaunchedEffect(assignState) {
        if (assignState is AssignState.Success) {
            showAssignDialog = false
            viewModel.resetAssignState()
            viewModel.loadIncidents()
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(if (isCitizen) "My Incidents" else "Incidents Dashboard")
                        Text(
                            text = if (isCitizen) "${totalCount} of your reports" else "$totalCount total incidents",
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
                    // Filter badge
                    val hasFilters = filters.status != null || filters.hazardType != null || 
                                    filters.urgency != null || !filters.searchQuery.isNullOrBlank()
                    
                    BadgedBox(
                        badge = {
                            if (hasFilters) {
                                Badge(containerColor = OceanColors.Primary)
                            }
                        }
                    ) {
                        IconButton(onClick = { showFilterSheet = true }) {
                            Icon(Icons.Default.FilterList, contentDescription = "Filter")
                        }
                    }
                    
                    IconButton(onClick = { viewModel.loadIncidents() }) {
                        Icon(Icons.Default.Refresh, contentDescription = "Refresh")
                    }
                }
            )
        },
        bottomBar = {
            OceanBottomNavBar(
                activeTab = "alerts",
                onNavigateToHome = onNavigateToHome,
                onNavigateToAlerts = onNavigateToAlerts,
                onNavigateToWeather = onNavigateToWeather,
                onNavigateToReport = onNavigateToReport,
                onNavigateToProfile = onNavigateToProfile,
                userRole = userRole,
                onNavigateToAdmin = onNavigateToAdmin,
                onNavigateToMesh = onNavigateToMesh
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when {
                isLoading && incidents.isEmpty() -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                }
                
                error != null && incidents.isEmpty() -> {
                    EmptyStateCard(
                        title = "Error Loading Incidents",
                        description = error ?: "Something went wrong",
                        icon = Icons.Default.Error,
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp)
                    ) {
                        OceanPrimaryButton(
                            text = "Try Again",
                            onClick = { viewModel.loadIncidents() }
                        )
                    }
                }
                
                incidents.isEmpty() -> {
                    EmptyStateCard(
                        title = "No Incidents Found",
                        description = "No incidents match your current filters. Try adjusting the filters or check back later.",
                        icon = Icons.Default.SearchOff,
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp)
                    ) {
                        if (filters.status != null || filters.hazardType != null || filters.urgency != null) {
                            OceanSecondaryButton(
                                text = "Clear Filters",
                                onClick = { viewModel.clearFilters() }
                            )
                        }
                    }
                }
                
                else -> {
                    LazyColumn(
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(incidents) { incident ->
                            IncidentCard(
                                incident = incident,
                                onClick = { onNavigateToDetail(incident.id) },
                                showActions = true,
                                onVerify = if (incident.status == IncidentStatus.PENDING) {
                                    { viewModel.verifyIncident(incident.id) }
                                } else null,
                                onDeploy = if (incident.status == IncidentStatus.VERIFIED) {
                                    { viewModel.deployResponse(incident.id) }
                                } else null,
                                onResolve = if (incident.status == IncidentStatus.IN_PROGRESS) {
                                    { viewModel.resolveIncident(incident.id) }
                                } else null,
                                onAssign = if (canAssign && incident.assignedToId == null && incident.status != IncidentStatus.RESOLVED) {
                                    {
                                        selectedIncidentId = incident.id
                                        showAssignDialog = true
                                    }
                                } else null
                            )
                        }
                        
                        // Load more button
                        if (hasMorePages) {
                            item {
                                Box(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(16.dp),
                                    contentAlignment = Alignment.Center
                                ) {
                                    if (isLoading) {
                                        CircularProgressIndicator(modifier = Modifier.size(24.dp))
                                    } else {
                                        TextButton(onClick = { viewModel.loadMoreIncidents() }) {
                                            Text("Load More")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Filter bottom sheet
    if (showFilterSheet) {
        FilterBottomSheet(
            currentFilters = filters,
            onDismiss = { showFilterSheet = false },
            onApplyFilters = { newFilters ->
                viewModel.loadIncidents(newFilters)
                showFilterSheet = false
            },
            onClearFilters = {
                viewModel.clearFilters()
                showFilterSheet = false
            }
        )
    }
    
    // Assign to rescue team dialog
    if (showAssignDialog) {
        AssignToRescueDialog(
            rescueTeams = rescueTeams,
            isLoading = assignState is AssignState.Loading,
            onAssign = { userId ->
                viewModel.assignIncident(selectedIncidentId, userId)
            },
            onDismiss = {
                showAssignDialog = false
                viewModel.resetAssignState()
            }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun FilterBottomSheet(
    currentFilters: IncidentFilters,
    onDismiss: () -> Unit,
    onApplyFilters: (IncidentFilters) -> Unit,
    onClearFilters: () -> Unit
) {
    var selectedStatus by remember { mutableStateOf(currentFilters.status) }
    var selectedHazardType by remember { mutableStateOf(currentFilters.hazardType) }
    var selectedUrgency by remember { mutableStateOf(currentFilters.urgency) }
    var searchQuery by remember { mutableStateOf(currentFilters.searchQuery ?: "") }
    
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = MaterialTheme.colorScheme.surface
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp)
                .padding(bottom = 32.dp)
        ) {
            Text(
                text = "Filter Incidents",
                style = MaterialTheme.typography.headlineSmall
            )
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Search
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                label = { Text("Search") },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                modifier = Modifier.fillMaxWidth(),
                shape = MaterialTheme.shapes.medium
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Status filter
            Text(
                text = "Status",
                style = MaterialTheme.typography.titleSmall
            )
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                FilterChip(
                    selected = selectedStatus == null,
                    onClick = { selectedStatus = null },
                    label = { Text("All") }
                )
                IncidentStatus.entries.take(2).forEach { status ->
                    FilterChip(
                        selected = selectedStatus == status,
                        onClick = { selectedStatus = if (selectedStatus == status) null else status },
                        label = { Text(status.name.lowercase().replaceFirstChar { it.uppercase() }) }
                    )
                }
            }
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                IncidentStatus.entries.drop(2).forEach { status ->
                    FilterChip(
                        selected = selectedStatus == status,
                        onClick = { selectedStatus = if (selectedStatus == status) null else status },
                        label = { Text(status.name.lowercase().replaceFirstChar { it.uppercase() }) }
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Urgency filter
            Text(
                text = "Urgency Level",
                style = MaterialTheme.typography.titleSmall
            )
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                FilterChip(
                    selected = selectedUrgency == null,
                    onClick = { selectedUrgency = null },
                    label = { Text("All") }
                )
                UrgencyLevel.entries.forEach { urgency ->
                    FilterChip(
                        selected = selectedUrgency == urgency,
                        onClick = { selectedUrgency = if (selectedUrgency == urgency) null else urgency },
                        label = { Text(urgency.name.lowercase().replaceFirstChar { it.uppercase() }) }
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Action buttons
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedButton(
                    onClick = onClearFilters,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Clear All")
                }
                
                Button(
                    onClick = {
                        onApplyFilters(
                            IncidentFilters(
                                status = selectedStatus,
                                hazardType = selectedHazardType,
                                urgency = selectedUrgency,
                                searchQuery = searchQuery.takeIf { it.isNotBlank() }
                            )
                        )
                    },
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = OceanColors.Primary
                    )
                ) {
                    Text("Apply Filters")
                }
            }
        }
    }
}

/**
 * Dialog for assigning an incident to a rescue team
 */
@Composable
private fun AssignToRescueDialog(
    rescueTeams: List<User>,
    isLoading: Boolean,
    onAssign: (Int) -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        icon = {
            Icon(
                Icons.Default.PersonAdd,
                contentDescription = null,
                tint = OceanColors.Primary
            )
        },
        title = { Text("Assign to Rescue Team") },
        text = {
            Column {
                if (rescueTeams.isEmpty()) {
                    Text(
                        text = "No rescue teams available",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                } else {
                    Text(
                        text = "Select a rescue team to assign this incident to:",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    
                    rescueTeams.forEach { team ->
                        Card(
                            onClick = { onAssign(team.id) },
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 4.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = OceanColors.DashboardBlue.copy(alpha = 0.05f)
                            ),
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(12.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Surface(
                                    shape = RoundedCornerShape(50),
                                    color = OceanColors.DashboardBlue.copy(alpha = 0.15f),
                                    modifier = Modifier.size(36.dp)
                                ) {
                                    Box(contentAlignment = Alignment.Center) {
                                        Icon(
                                            Icons.Default.LocalFireDepartment,
                                            contentDescription = null,
                                            tint = OceanColors.DashboardBlue,
                                            modifier = Modifier.size(20.dp)
                                        )
                                    }
                                }
                                Spacer(modifier = Modifier.width(12.dp))
                                Column {
                                    Text(
                                        text = team.fullName,
                                        style = MaterialTheme.typography.bodyMedium,
                                        fontWeight = androidx.compose.ui.text.font.FontWeight.Medium
                                    )
                                    if (team.location != null) {
                                        Text(
                                            text = team.location,
                                            style = MaterialTheme.typography.bodySmall,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                
                if (isLoading) {
                    Spacer(modifier = Modifier.height(8.dp))
                    LinearProgressIndicator(
                        modifier = Modifier.fillMaxWidth(),
                        color = OceanColors.Primary
                    )
                }
            }
        },
        confirmButton = {},
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}
