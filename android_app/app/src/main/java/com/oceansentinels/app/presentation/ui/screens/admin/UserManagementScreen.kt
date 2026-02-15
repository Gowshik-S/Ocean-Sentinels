package com.oceansentinels.app.presentation.ui.screens.admin

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.oceansentinels.app.domain.model.User
import com.oceansentinels.app.domain.model.UserRole
import com.oceansentinels.app.presentation.ui.components.*
import com.oceansentinels.app.presentation.ui.theme.OceanColors
import com.oceansentinels.app.presentation.viewmodel.AdminViewModel
import com.oceansentinels.app.presentation.viewmodel.DeleteUserState

/**
 * User management screen showing all users with filtering and actions
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun UserManagementScreen(
    onNavigateBack: () -> Unit,
    viewModel: AdminViewModel = hiltViewModel()
) {
    val users by viewModel.users.collectAsState()
    val rescueTeams by viewModel.rescueTeams.collectAsState()
    val authorities by viewModel.authorities.collectAsState()
    val citizens by viewModel.citizens.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val error by viewModel.error.collectAsState()
    val deleteUserState by viewModel.deleteUserState.collectAsState()
    
    var selectedTab by remember { mutableStateOf(0) }
    var searchQuery by remember { mutableStateOf("") }
    var showDeleteDialog by remember { mutableStateOf(false) }
    var userToDelete by remember { mutableStateOf<User?>(null) }
    
    // Load users on first composition
    LaunchedEffect(Unit) {
        viewModel.loadAllUsers()
    }
    
    // Handle delete success
    LaunchedEffect(deleteUserState) {
        if (deleteUserState is DeleteUserState.Success) {
            showDeleteDialog = false
            userToDelete = null
            viewModel.resetDeleteUserState()
        }
    }
    
    val tabs = listOf("All", "Rescue Teams", "Authorities", "Citizens")
    
    val filteredUsers = when (selectedTab) {
        0 -> users
        1 -> rescueTeams
        2 -> authorities
        3 -> citizens
        else -> users
    }.filter { user ->
        if (searchQuery.isBlank()) true
        else {
            user.username.contains(searchQuery, ignoreCase = true) ||
            user.email.contains(searchQuery, ignoreCase = true) ||
            "${user.firstName} ${user.lastName}".contains(searchQuery, ignoreCase = true)
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("User Management") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = { viewModel.loadAllUsers() }) {
                        Icon(Icons.Default.Refresh, contentDescription = "Refresh")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Search bar
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                placeholder = { Text("Search users...") },
                leadingIcon = {
                    Icon(Icons.Default.Search, contentDescription = null)
                },
                trailingIcon = {
                    if (searchQuery.isNotBlank()) {
                        IconButton(onClick = { searchQuery = "" }) {
                            Icon(Icons.Default.Clear, contentDescription = "Clear")
                        }
                    }
                },
                singleLine = true
            )
            
            // Tabs
            TabRow(selectedTabIndex = selectedTab) {
                tabs.forEachIndexed { index, title ->
                    Tab(
                        selected = selectedTab == index,
                        onClick = { selectedTab = index },
                        text = {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(4.dp)
                            ) {
                                Text(title)
                                val count = when (index) {
                                    0 -> users.size
                                    1 -> rescueTeams.size
                                    2 -> authorities.size
                                    3 -> citizens.size
                                    else -> 0
                                }
                                if (count > 0) {
                                    CountBadge(count = count)
                                }
                            }
                        }
                    )
                }
            }
            
            // Content
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .weight(1f)
            ) {
                when {
                    isLoading -> {
                        CircularProgressIndicator(
                            modifier = Modifier.align(Alignment.Center)
                        )
                    }
                    error != null -> {
                        Column(
                            modifier = Modifier.align(Alignment.Center),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Icon(
                                imageVector = Icons.Default.Error,
                                contentDescription = null,
                                tint = OceanColors.Danger,
                                modifier = Modifier.size(48.dp)
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = error ?: "Unknown error",
                                color = OceanColors.Danger
                            )
                            Spacer(modifier = Modifier.height(16.dp))
                            OceanPrimaryButton(
                                text = "Retry",
                                onClick = { viewModel.loadAllUsers() }
                            )
                        }
                    }
                    filteredUsers.isEmpty() -> {
                        EmptyStateCard(
                            icon = Icons.Default.PersonOff,
                            title = "No Users Found",
                            description = if (searchQuery.isBlank()) 
                                "There are no users in this category" 
                            else 
                                "No users match your search",
                            modifier = Modifier
                                .padding(16.dp)
                                .align(Alignment.Center)
                        )
                    }
                    else -> {
                        LazyColumn(
                            modifier = Modifier.fillMaxSize(),
                            contentPadding = PaddingValues(16.dp),
                            verticalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            items(
                                items = filteredUsers,
                                key = { it.id }
                            ) { user ->
                                UserManagementCard(
                                    user = user,
                                    onDelete = {
                                        userToDelete = user
                                        showDeleteDialog = true
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Delete confirmation dialog
    if (showDeleteDialog && userToDelete != null) {
        AlertDialog(
            onDismissRequest = { 
                showDeleteDialog = false
                userToDelete = null
            },
            icon = {
                Icon(
                    imageVector = Icons.Default.Delete,
                    contentDescription = null,
                    tint = OceanColors.Danger
                )
            },
            title = { Text("Delete User") },
            text = {
                Column {
                    Text("Are you sure you want to delete this user?")
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "${userToDelete?.firstName} ${userToDelete?.lastName}",
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = userToDelete?.email ?: "",
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "This action cannot be undone.",
                        color = OceanColors.Danger,
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        userToDelete?.let { viewModel.deleteUser(it.id) }
                    },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = OceanColors.Danger
                    ),
                    enabled = deleteUserState !is DeleteUserState.Loading
                ) {
                    if (deleteUserState is DeleteUserState.Loading) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(16.dp),
                            color = MaterialTheme.colorScheme.onPrimary,
                            strokeWidth = 2.dp
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                    }
                    Text("Delete")
                }
            },
            dismissButton = {
                TextButton(
                    onClick = { 
                        showDeleteDialog = false
                        userToDelete = null
                    }
                ) {
                    Text("Cancel")
                }
            }
        )
    }
}

/**
 * Card for displaying user in management list
 */
@Composable
private fun UserManagementCard(
    user: User,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Avatar
            Surface(
                modifier = Modifier.size(48.dp),
                shape = MaterialTheme.shapes.medium,
                color = getRoleColor(user.role).copy(alpha = 0.2f)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = getRoleIcon(user.role),
                        contentDescription = null,
                        tint = getRoleColor(user.role),
                        modifier = Modifier.size(24.dp)
                    )
                }
            }
            
            Spacer(modifier = Modifier.width(12.dp))
            
            // User info
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "${user.firstName} ${user.lastName}",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                    RoleBadge(role = user.role)
                }
                
                Text(
                    text = "@${user.username}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                
                Text(
                    text = user.email,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                
                if (user.phone != null) {
                    Text(
                        text = user.phone,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            
            // Delete button (only for non-admin users)
            if (user.role != UserRole.ADMIN) {
                IconButton(
                    onClick = onDelete,
                    colors = IconButtonDefaults.iconButtonColors(
                        contentColor = OceanColors.Danger
                    )
                ) {
                    Icon(
                        imageVector = Icons.Default.Delete,
                        contentDescription = "Delete user"
                    )
                }
            }
        }
    }
}

/**
 * Get icon for user role
 */
private fun getRoleIcon(role: UserRole) = when (role) {
    UserRole.ADMIN -> Icons.Default.AdminPanelSettings
    UserRole.AUTHORITY -> Icons.Default.Shield
    UserRole.RESCUE_TEAM -> Icons.Default.LocalHospital
    UserRole.PUBLIC -> Icons.Default.Person
}

/**
 * Get color for user role
 */
private fun getRoleColor(role: UserRole) = when (role) {
    UserRole.ADMIN -> OceanColors.Danger
    UserRole.AUTHORITY -> OceanColors.Warning
    UserRole.RESCUE_TEAM -> OceanColors.Success
    UserRole.PUBLIC -> OceanColors.Primary
}
