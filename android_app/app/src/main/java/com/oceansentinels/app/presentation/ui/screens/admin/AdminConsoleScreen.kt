package com.oceansentinels.app.presentation.ui.screens.admin

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
import com.oceansentinels.app.presentation.viewmodel.CreateUserState
import com.oceansentinels.app.presentation.viewmodel.IncidentViewModel

/**
 * Admin Console screen — incident management with assignment to rescue teams
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AdminConsoleScreen(
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
    val authorities by adminViewModel.authorities.collectAsState()
    val createUserState by adminViewModel.createUserState.collectAsState()
    
    val userSession by authViewModel.userSession.collectAsState()
    val userRole = (userSession as? UserSession.Authenticated)?.user?.role ?: UserRole.ADMIN
    
    var showAssignDialog by remember { mutableStateOf(false) }
    var selectedIncidentId by remember { mutableIntStateOf(0) }
    var selectedFilter by remember { mutableStateOf("all") }
    var selectedTab by remember { mutableIntStateOf(0) } // 0 = Incidents, 1 = User Management
    var showCreateUserDialog by remember { mutableStateOf(false) }
    var createUserRole by remember { mutableStateOf(UserRole.RESCUE_TEAM) }
    
    // Load data on first composition
    LaunchedEffect(Unit) {
        incidentViewModel.loadIncidents()
        adminViewModel.loadAllUsers()
    }
    
    // Handle assign success
    LaunchedEffect(assignState) {
        if (assignState is AssignState.Success) {
            showAssignDialog = false
            incidentViewModel.resetAssignState()
            incidentViewModel.loadIncidents()
        }
    }
    
    // Handle create user success
    LaunchedEffect(createUserState) {
        if (createUserState is CreateUserState.Success) {
            showCreateUserDialog = false
            adminViewModel.resetCreateUserState()
        }
    }
    
    val filteredIncidents = remember(incidents, selectedFilter) {
        when (selectedFilter) {
            "pending" -> incidents.filter { it.status == IncidentStatus.PENDING }
            "verified" -> incidents.filter { it.status == IncidentStatus.VERIFIED }
            "in_progress" -> incidents.filter { it.status == IncidentStatus.IN_PROGRESS }
            "resolved" -> incidents.filter { it.status == IncidentStatus.RESOLVED }
            "unassigned" -> incidents.filter { it.assignedToId == null && it.status != IncidentStatus.RESOLVED }
            else -> incidents
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Admin Console") },
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
                activeTab = "admin",
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
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Tabs: Incidents | User Management
            TabRow(selectedTabIndex = selectedTab) {
                Tab(
                    selected = selectedTab == 0,
                    onClick = { selectedTab = 0 },
                    text = { Text("Incidents") },
                    icon = { Icon(Icons.Default.Warning, contentDescription = null, modifier = Modifier.size(18.dp)) }
                )
                Tab(
                    selected = selectedTab == 1,
                    onClick = { selectedTab = 1 },
                    text = { Text("Users") },
                    icon = { Icon(Icons.Default.People, contentDescription = null, modifier = Modifier.size(18.dp)) }
                )
            }
            
            when (selectedTab) {
                0 -> AdminIncidentsTab(
                    incidents = incidents,
                    filteredIncidents = filteredIncidents,
                    isLoading = isLoading,
                    error = error,
                    assignState = assignState,
                    rescueTeams = rescueTeams,
                    selectedFilter = selectedFilter,
                    onFilterSelected = { selectedFilter = it },
                    onAssign = { incidentId ->
                        selectedIncidentId = incidentId
                        showAssignDialog = true
                    },
                    onViewDetail = { onNavigateToDetail(it) },
                    onVerify = { incidentViewModel.verifyIncident(it) },
                    onDeploy = { incidentViewModel.deployResponse(it) },
                    onResolve = { incidentViewModel.resolveIncident(it) },
                    onRefresh = { incidentViewModel.loadIncidents() }
                )
                1 -> AdminUsersTab(
                    rescueTeams = rescueTeams,
                    authorities = authorities,
                    isLoading = adminViewModel.isLoading.collectAsState().value,
                    createUserState = createUserState,
                    onCreateUser = { role ->
                        createUserRole = role
                        showCreateUserDialog = true
                    },
                    onDeleteUser = { userId -> adminViewModel.deleteUser(userId) },
                    onRefresh = { adminViewModel.loadAllUsers() }
                )
            }
        }
    }
    
    // Assign dialog
    if (showAssignDialog) {
        AssignIncidentDialog(
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
    
    // Create user dialog
    if (showCreateUserDialog) {
        CreateUserDialog(
            role = createUserRole,
            isLoading = createUserState is CreateUserState.Loading,
            errorMessage = (createUserState as? CreateUserState.Error)?.message,
            onCreateUser = { username, email, password, firstName, lastName, phone, location ->
                when (createUserRole) {
                    UserRole.RESCUE_TEAM -> adminViewModel.createRescueTeam(
                        username, email, password, firstName, lastName, phone, location
                    )
                    UserRole.AUTHORITY -> adminViewModel.createAuthority(
                        username, email, password, firstName, lastName, phone, location
                    )
                    else -> {}
                }
            },
            onDismiss = {
                showCreateUserDialog = false
                adminViewModel.resetCreateUserState()
            }
        )
    }
}

@Composable
private fun AdminIncidentsTab(
    incidents: List<Incident>,
    filteredIncidents: List<Incident>,
    isLoading: Boolean,
    error: String?,
    assignState: AssignState,
    rescueTeams: List<User>,
    selectedFilter: String,
    onFilterSelected: (String) -> Unit,
    onAssign: (Int) -> Unit,
    onViewDetail: (Int) -> Unit,
    onVerify: (Int) -> Unit,
    onDeploy: (Int) -> Unit,
    onResolve: (Int) -> Unit,
    onRefresh: () -> Unit
) {
    Column(modifier = Modifier.fillMaxSize()) {
        // Summary stats
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            val pendingCount = incidents.count { it.status == IncidentStatus.PENDING }
            val activeCount = incidents.count { it.isActive }
            val unassignedCount = incidents.count { it.assignedToId == null && it.status != IncidentStatus.RESOLVED }
            AdminStatChip("Pending", pendingCount, OceanColors.Warning, Modifier.weight(1f))
            AdminStatChip("Active", activeCount, OceanColors.Error, Modifier.weight(1f))
            AdminStatChip("Unassigned", unassignedCount, OceanColors.Info, Modifier.weight(1f))
        }

        ScrollableFilterRow(selectedFilter = selectedFilter, onFilterSelected = onFilterSelected)

        if (error != null) {
            Card(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp),
                colors = CardDefaults.cardColors(containerColor = OceanColors.Error.copy(alpha = 0.1f))
            ) {
                Text(text = error, modifier = Modifier.padding(12.dp), color = OceanColors.Error, style = MaterialTheme.typography.bodySmall)
            }
        }

        if (assignState is AssignState.Error) {
            Card(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp),
                colors = CardDefaults.cardColors(containerColor = OceanColors.Error.copy(alpha = 0.1f))
            ) {
                Text(text = (assignState as AssignState.Error).message, modifier = Modifier.padding(12.dp), color = OceanColors.Error, style = MaterialTheme.typography.bodySmall)
            }
        }

        if (isLoading && incidents.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = OceanColors.DashboardBlue)
            }
        } else if (filteredIncidents.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(Icons.Default.CheckCircle, contentDescription = null, modifier = Modifier.size(48.dp), tint = OceanColors.Success)
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(text = "No incidents found", style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                items(filteredIncidents, key = { it.id }) { incident ->
                    AdminIncidentCard(
                        incident = incident,
                        rescueTeams = rescueTeams,
                        onAssign = { onAssign(it) },
                        onViewDetail = { onViewDetail(it) },
                        onVerify = { onVerify(it) },
                        onDeploy = { onDeploy(it) },
                        onResolve = { onResolve(it) }
                    )
                }
            }
        }
    }
}

@Composable
private fun AdminUsersTab(
    rescueTeams: List<User>,
    authorities: List<User>,
    isLoading: Boolean,
    createUserState: CreateUserState,
    onCreateUser: (UserRole) -> Unit,
    onDeleteUser: (Int) -> Unit,
    onRefresh: () -> Unit
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Quick action buttons
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Button(
                    onClick = { onCreateUser(UserRole.RESCUE_TEAM) },
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(containerColor = OceanColors.DashboardBlue)
                ) {
                    Icon(Icons.Default.PersonAdd, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text("Add Rescue Team")
                }
                Button(
                    onClick = { onCreateUser(UserRole.AUTHORITY) },
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(containerColor = OceanColors.Purple)
                ) {
                    Icon(Icons.Default.PersonAdd, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text("Add Authority")
                }
            }
        }

        // Success feedback
        if (createUserState is CreateUserState.Success) {
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = OceanColors.Success.copy(alpha = 0.1f))
                ) {
                    Row(
                        modifier = Modifier.padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Default.CheckCircle, contentDescription = null, tint = OceanColors.Success, modifier = Modifier.size(20.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "User \"${(createUserState as CreateUserState.Success).user.username}\" created successfully",
                            style = MaterialTheme.typography.bodySmall,
                            color = OceanColors.Success
                        )
                    }
                }
            }
        }

        // Rescue Teams section
        item {
            Text(
                text = "Rescue Teams (${rescueTeams.size})",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                color = OceanColors.DashboardBlue
            )
        }

        if (rescueTeams.isEmpty()) {
            item {
                Text(
                    text = "No rescue teams created yet",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(vertical = 8.dp)
                )
            }
        } else {
            items(rescueTeams, key = { "rt_${it.id}" }) { user ->
                UserManagementCard(user = user, onDelete = { onDeleteUser(user.id) })
            }
        }

        // Authorities section
        item {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Authorities (${authorities.size})",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                color = OceanColors.Purple
            )
        }

        if (authorities.isEmpty()) {
            item {
                Text(
                    text = "No authorities created yet",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(vertical = 8.dp)
                )
            }
        } else {
            items(authorities, key = { "auth_${it.id}" }) { user ->
                UserManagementCard(user = user, onDelete = { onDeleteUser(user.id) })
            }
        }

        // Loading indicator
        if (isLoading) {
            item {
                Box(modifier = Modifier.fillMaxWidth().padding(16.dp), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(modifier = Modifier.size(24.dp), color = OceanColors.DashboardBlue)
                }
            }
        }
    }
}

@Composable
private fun UserManagementCard(
    user: User,
    onDelete: () -> Unit
) {
    var showDeleteConfirm by remember { mutableStateOf(false) }

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        shape = RoundedCornerShape(8.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Avatar
            Surface(
                shape = RoundedCornerShape(50),
                color = when (user.role) {
                    UserRole.RESCUE_TEAM -> OceanColors.DashboardBlue
                    UserRole.AUTHORITY -> OceanColors.Purple
                    else -> OceanColors.Gray
                }.copy(alpha = 0.15f),
                modifier = Modifier.size(40.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Text(
                        text = "${user.firstName.firstOrNull() ?: ""}${user.lastName.firstOrNull() ?: ""}",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold,
                        color = when (user.role) {
                            UserRole.RESCUE_TEAM -> OceanColors.DashboardBlue
                            UserRole.AUTHORITY -> OceanColors.Purple
                            else -> OceanColors.Gray
                        }
                    )
                }
            }

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
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
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Surface(
                        color = when (user.role) {
                            UserRole.RESCUE_TEAM -> OceanColors.DashboardBlue
                            UserRole.AUTHORITY -> OceanColors.Purple
                            else -> OceanColors.Gray
                        }.copy(alpha = 0.15f),
                        shape = RoundedCornerShape(4.dp)
                    ) {
                        Text(
                            text = user.role.displayName,
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                            style = MaterialTheme.typography.labelSmall,
                            color = when (user.role) {
                                UserRole.RESCUE_TEAM -> OceanColors.DashboardBlue
                                UserRole.AUTHORITY -> OceanColors.Purple
                                else -> OceanColors.Gray
                            }
                        )
                    }
                    if (user.location != null) {
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = user.location,
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }

            // Delete button
            IconButton(onClick = { showDeleteConfirm = true }) {
                Icon(
                    Icons.Default.Delete,
                    contentDescription = "Delete",
                    tint = OceanColors.Error,
                    modifier = Modifier.size(20.dp)
                )
            }
        }
    }

    if (showDeleteConfirm) {
        AlertDialog(
            onDismissRequest = { showDeleteConfirm = false },
            title = { Text("Delete User") },
            text = { Text("Are you sure you want to delete ${user.fullName}? This action cannot be undone.") },
            confirmButton = {
                Button(
                    onClick = {
                        onDelete()
                        showDeleteConfirm = false
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = OceanColors.Error)
                ) {
                    Text("Delete")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteConfirm = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
private fun CreateUserDialog(
    role: UserRole,
    isLoading: Boolean,
    errorMessage: String?,
    onCreateUser: (String, String, String, String, String, String?, String?) -> Unit,
    onDismiss: () -> Unit
) {
    var username by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var firstName by remember { mutableStateOf("") }
    var lastName by remember { mutableStateOf("") }
    var phone by remember { mutableStateOf("") }
    var location by remember { mutableStateOf("") }

    val roleName = if (role == UserRole.RESCUE_TEAM) "Rescue Team" else "Authority"

    AlertDialog(
        onDismissRequest = onDismiss,
        icon = {
            Icon(
                Icons.Default.PersonAdd,
                contentDescription = null,
                tint = if (role == UserRole.RESCUE_TEAM) OceanColors.DashboardBlue else OceanColors.Purple
            )
        },
        title = { Text("Create $roleName Member") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(
                    value = username,
                    onValueChange = { username = it },
                    label = { Text("Username") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                OutlinedTextField(
                    value = email,
                    onValueChange = { email = it },
                    label = { Text("Email") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                OutlinedTextField(
                    value = password,
                    onValueChange = { password = it },
                    label = { Text("Password") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedTextField(
                        value = firstName,
                        onValueChange = { firstName = it },
                        label = { Text("First Name") },
                        modifier = Modifier.weight(1f),
                        singleLine = true
                    )
                    OutlinedTextField(
                        value = lastName,
                        onValueChange = { lastName = it },
                        label = { Text("Last Name") },
                        modifier = Modifier.weight(1f),
                        singleLine = true
                    )
                }
                OutlinedTextField(
                    value = phone,
                    onValueChange = { phone = it },
                    label = { Text("Phone (optional)") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                OutlinedTextField(
                    value = location,
                    onValueChange = { location = it },
                    label = { Text("Location (optional)") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )

                if (errorMessage != null) {
                    Text(
                        text = errorMessage,
                        color = OceanColors.Error,
                        style = MaterialTheme.typography.bodySmall
                    )
                }

                if (isLoading) {
                    LinearProgressIndicator(
                        modifier = Modifier.fillMaxWidth(),
                        color = if (role == UserRole.RESCUE_TEAM) OceanColors.DashboardBlue else OceanColors.Purple
                    )
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    onCreateUser(
                        username, email, password, firstName, lastName,
                        phone.takeIf { it.isNotBlank() },
                        location.takeIf { it.isNotBlank() }
                    )
                },
                enabled = username.isNotBlank() && email.isNotBlank() && password.length >= 6 &&
                        firstName.isNotBlank() && lastName.isNotBlank() && !isLoading,
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (role == UserRole.RESCUE_TEAM) OceanColors.DashboardBlue else OceanColors.Purple
                )
            ) {
                Text("Create")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Composable
private fun AdminStatChip(
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
            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall,
                color = color
            )
        }
    }
}

@Composable
private fun ScrollableFilterRow(
    selectedFilter: String,
    onFilterSelected: (String) -> Unit
) {
    val filters = listOf(
        "all" to "All",
        "unassigned" to "Unassigned",
        "pending" to "Pending",
        "verified" to "Verified",
        "in_progress" to "In Progress",
        "resolved" to "Resolved"
    )
    
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        filters.forEach { (key, label) ->
            FilterChip(
                selected = selectedFilter == key,
                onClick = { onFilterSelected(key) },
                label = { Text(label, style = MaterialTheme.typography.labelSmall) }
            )
        }
    }
}

@Composable
private fun AdminIncidentCard(
    incident: Incident,
    rescueTeams: List<User>,
    onAssign: (Int) -> Unit,
    onViewDetail: (Int) -> Unit,
    onVerify: (Int) -> Unit,
    onDeploy: (Int) -> Unit,
    onResolve: (Int) -> Unit
) {
    val statusColor = when (incident.status) {
        IncidentStatus.PENDING -> OceanColors.Warning
        IncidentStatus.VERIFIED -> OceanColors.Info
        IncidentStatus.IN_PROGRESS -> OceanColors.DashboardBlue
        IncidentStatus.RESOLVED -> OceanColors.Success
        IncidentStatus.CLOSED -> OceanColors.Gray
    }
    
    val assignedTeamName = if (incident.assignedToId != null) {
        rescueTeams.find { it.id == incident.assignedToId }?.let {
            "${it.firstName} ${it.lastName}"
        } ?: "Team #${incident.assignedToId}"
    } else null
    
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        shape = RoundedCornerShape(10.dp)
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            // Header: Reference + Status badge
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = incident.referenceId,
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    fontWeight = FontWeight.Medium
                )
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
            
            Spacer(modifier = Modifier.height(6.dp))
            
            // Hazard type + urgency
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
                Spacer(modifier = Modifier.width(8.dp))
                Surface(
                    color = when (incident.urgency) {
                        UrgencyLevel.CRITICAL -> OceanColors.Error
                        UrgencyLevel.HIGH -> OceanColors.Warning
                        UrgencyLevel.MEDIUM -> OceanColors.Info
                        UrgencyLevel.LOW -> OceanColors.Success
                    }.copy(alpha = 0.15f),
                    shape = RoundedCornerShape(4.dp)
                ) {
                    Text(
                        text = incident.urgency.displayName,
                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                        style = MaterialTheme.typography.labelSmall,
                        color = when (incident.urgency) {
                            UrgencyLevel.CRITICAL -> OceanColors.Error
                            UrgencyLevel.HIGH -> OceanColors.Warning
                            UrgencyLevel.MEDIUM -> OceanColors.Info
                            UrgencyLevel.LOW -> OceanColors.Success
                        }
                    )
                }
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
            
            // Description preview
            if (incident.description.isNotBlank()) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = incident.description.take(100) + if (incident.description.length > 100) "..." else "",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 2
                )
            }
            
            // Assignment info
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
                // View detail
                OutlinedButton(
                    onClick = { onViewDetail(incident.id) },
                    modifier = Modifier.height(32.dp),
                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 0.dp)
                ) {
                    Icon(
                        Icons.Default.Visibility,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("View", style = MaterialTheme.typography.labelSmall)
                }
                
                // Assign button (for unassigned or re-assignable incidents)
                if (incident.status != IncidentStatus.RESOLVED && incident.status != IncidentStatus.CLOSED) {
                    Button(
                        onClick = { onAssign(incident.id) },
                        modifier = Modifier.height(32.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = OceanColors.DashboardBlue),
                        contentPadding = PaddingValues(horizontal = 10.dp, vertical = 0.dp)
                    ) {
                        Icon(
                            Icons.Default.AssignmentInd,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            if (incident.assignedToId == null) "Assign" else "Reassign",
                            style = MaterialTheme.typography.labelSmall
                        )
                    }
                }
                
                Spacer(modifier = Modifier.weight(1f))
                
                // Status action buttons
                when {
                    incident.canBeVerified -> {
                        Button(
                            onClick = { onVerify(incident.id) },
                            modifier = Modifier.height(32.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = OceanColors.Info),
                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 0.dp)
                        ) {
                            Text("Verify", style = MaterialTheme.typography.labelSmall)
                        }
                    }
                    incident.canBeDeployed -> {
                        Button(
                            onClick = { onDeploy(incident.id) },
                            modifier = Modifier.height(32.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = OceanColors.Warning),
                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 0.dp)
                        ) {
                            Text("Deploy", style = MaterialTheme.typography.labelSmall)
                        }
                    }
                    incident.canBeResolved -> {
                        Button(
                            onClick = { onResolve(incident.id) },
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
private fun AssignIncidentDialog(
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
                        text = "No rescue teams available. Create one first.",
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
                                    text = "${user.firstName} ${user.lastName}",
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
