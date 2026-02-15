package com.oceansentinels.app.presentation.ui.screens.admin

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
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
 * Admin dashboard for user management
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AdminDashboardScreen(
    onNavigateBack: () -> Unit,
    onNavigateToCreateRescueTeam: () -> Unit,
    onNavigateToCreateAuthority: () -> Unit,
    onNavigateToUserManagement: () -> Unit,
    viewModel: AdminViewModel = hiltViewModel()
) {
    val rescueTeams by viewModel.rescueTeams.collectAsState()
    val authorities by viewModel.authorities.collectAsState()
    val citizens by viewModel.citizens.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val error by viewModel.error.collectAsState()
    val rescueTeamsCount by viewModel.rescueTeamsCount.collectAsState()
    val authoritiesCount by viewModel.authoritiesCount.collectAsState()
    val citizensCount by viewModel.citizensCount.collectAsState()
    val deleteUserState by viewModel.deleteUserState.collectAsState()
    
    var showDeleteDialog by remember { mutableStateOf(false) }
    var userToDelete by remember { mutableStateOf<User?>(null) }
    
    // Load users on first composition
    LaunchedEffect(Unit) {
        viewModel.loadAllUsers()
    }
    
    // Handle delete success
    LaunchedEffect(deleteUserState) {
        if (deleteUserState is DeleteUserState.Success) {
            viewModel.resetDeleteUserState()
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Admin Dashboard") },
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
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Stats Overview
            item {
                Text(
                    text = "User Management",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
            }
            
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    StatsCard(
                        title = "Rescue Teams",
                        value = rescueTeamsCount.toString(),
                        icon = Icons.Default.LocalHospital,
                        iconColor = OceanColors.Primary,
                        modifier = Modifier.weight(1f)
                    )
                    
                    StatsCard(
                        title = "Authorities",
                        value = authoritiesCount.toString(),
                        icon = Icons.Default.Shield,
                        iconColor = OceanColors.Warning,
                        modifier = Modifier.weight(1f)
                    )
                    
                    StatsCard(
                        title = "Citizens",
                        value = citizensCount.toString(),
                        icon = Icons.Default.People,
                        iconColor = OceanColors.Success,
                        modifier = Modifier.weight(1f)
                    )
                }
            }
            
            // Quick Actions
            item {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Quick Actions",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
            }
            
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Card(
                        onClick = onNavigateToCreateRescueTeam,
                        modifier = Modifier.weight(1f),
                        colors = CardDefaults.cardColors(
                            containerColor = OceanColors.Primary.copy(alpha = 0.1f)
                        )
                    ) {
                        Column(
                            modifier = Modifier
                                .padding(16.dp)
                                .fillMaxWidth(),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Icon(
                                imageVector = Icons.Default.PersonAdd,
                                contentDescription = null,
                                tint = OceanColors.Primary,
                                modifier = Modifier.size(32.dp)
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = "Add Rescue Team",
                                style = MaterialTheme.typography.labelMedium,
                                color = OceanColors.Primary,
                                fontWeight = FontWeight.Medium
                            )
                        }
                    }
                    
                    Card(
                        onClick = onNavigateToCreateAuthority,
                        modifier = Modifier.weight(1f),
                        colors = CardDefaults.cardColors(
                            containerColor = OceanColors.Warning.copy(alpha = 0.1f)
                        )
                    ) {
                        Column(
                            modifier = Modifier
                                .padding(16.dp)
                                .fillMaxWidth(),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Icon(
                                imageVector = Icons.Default.PersonAdd,
                                contentDescription = null,
                                tint = OceanColors.Warning,
                                modifier = Modifier.size(32.dp)
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = "Add Authority",
                                style = MaterialTheme.typography.labelMedium,
                                color = OceanColors.Warning,
                                fontWeight = FontWeight.Medium
                            )
                        }
                    }
                }
            }
            
            // Rescue Teams Section
            item {
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Rescue Teams",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                    
                    TextButton(onClick = onNavigateToUserManagement) {
                        Text("View All")
                    }
                }
            }
            
            item {
                if (isLoading && rescueTeams.isEmpty()) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(100.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                } else if (rescueTeams.isEmpty()) {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                        )
                    ) {
                        Column(
                            modifier = Modifier
                                .padding(24.dp)
                                .fillMaxWidth(),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Icon(
                                imageVector = Icons.Default.Group,
                                contentDescription = null,
                                modifier = Modifier.size(48.dp),
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = "No rescue teams yet",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Spacer(modifier = Modifier.height(12.dp))
                            OceanSecondaryButton(
                                text = "Add First Team",
                                onClick = onNavigateToCreateRescueTeam,
                                icon = Icons.Default.Add
                            )
                        }
                    }
                } else {
                    LazyRow(
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(rescueTeams.take(5)) { user ->
                            UserCardCompact(
                                user = user,
                                onClick = {},
                                onDelete = {
                                    userToDelete = user
                                    showDeleteDialog = true
                                }
                            )
                        }
                    }
                }
            }
            
            // Authorities Section
            item {
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Authorities",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                    
                    TextButton(onClick = onNavigateToUserManagement) {
                        Text("View All")
                    }
                }
            }
            
            item {
                if (isLoading && authorities.isEmpty()) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(100.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                } else if (authorities.isEmpty()) {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                        )
                    ) {
                        Column(
                            modifier = Modifier
                                .padding(24.dp)
                                .fillMaxWidth(),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Icon(
                                imageVector = Icons.Default.Shield,
                                contentDescription = null,
                                modifier = Modifier.size(48.dp),
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = "No authorities yet",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Spacer(modifier = Modifier.height(12.dp))
                            OceanSecondaryButton(
                                text = "Add First Authority",
                                onClick = onNavigateToCreateAuthority,
                                icon = Icons.Default.Add
                            )
                        }
                    }
                } else {
                    LazyRow(
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(authorities.take(5)) { user ->
                            UserCardCompact(
                                user = user,
                                onClick = {},
                                onDelete = {
                                    userToDelete = user
                                    showDeleteDialog = true
                                }
                            )
                        }
                    }
                }
            }
            
            item {
                Spacer(modifier = Modifier.height(32.dp))
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
            title = {
                Text("Delete User")
            },
            text = {
                Text("Are you sure you want to delete ${userToDelete?.firstName} ${userToDelete?.lastName}? This action cannot be undone.")
            },
            confirmButton = {
                OceanDangerButton(
                    text = "Delete",
                    onClick = {
                        userToDelete?.let { viewModel.deleteUser(it.id) }
                        showDeleteDialog = false
                        userToDelete = null
                    },
                    isLoading = deleteUserState is DeleteUserState.Loading
                )
            },
            dismissButton = {
                TextButton(onClick = { 
                    showDeleteDialog = false
                    userToDelete = null
                }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
private fun UserCardCompact(
    user: User,
    onClick: () -> Unit,
    onDelete: () -> Unit
) {
    Card(
        onClick = onClick,
        modifier = Modifier.width(200.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Surface(
                    shape = MaterialTheme.shapes.medium,
                    color = when (user.role) {
                        UserRole.RESCUE_TEAM -> OceanColors.Primary
                        UserRole.AUTHORITY -> OceanColors.Warning
                        else -> OceanColors.Success
                    }.copy(alpha = 0.1f),
                    modifier = Modifier.size(40.dp)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Text(
                            text = "${user.firstName.firstOrNull() ?: ""}${user.lastName.firstOrNull() ?: ""}",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = when (user.role) {
                                UserRole.RESCUE_TEAM -> OceanColors.Primary
                                UserRole.AUTHORITY -> OceanColors.Warning
                                else -> OceanColors.Success
                            }
                        )
                    }
                }
                
                IconButton(
                    onClick = onDelete,
                    modifier = Modifier.size(32.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Delete,
                        contentDescription = "Delete",
                        tint = OceanColors.Danger,
                        modifier = Modifier.size(18.dp)
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Text(
                text = "${user.firstName} ${user.lastName}",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold
            )
            
            Text(
                text = user.email,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            RoleBadge(role = user.role)
        }
    }
}
