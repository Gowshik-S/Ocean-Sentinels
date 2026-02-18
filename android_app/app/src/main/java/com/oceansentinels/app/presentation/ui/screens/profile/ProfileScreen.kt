package com.oceansentinels.app.presentation.ui.screens.profile

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.oceansentinels.app.domain.model.UserSession
import com.oceansentinels.app.presentation.ui.components.*
import com.oceansentinels.app.presentation.ui.theme.OceanColors
import com.oceansentinels.app.presentation.viewmodel.AuthViewModel

/**
 * Profile screen showing user information
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(
    onNavigateBack: () -> Unit,
    onNavigateToSettings: () -> Unit,
    onLogout: () -> Unit,
    onNavigateToHome: () -> Unit = {},
    onNavigateToAlerts: () -> Unit = {},
    onNavigateToWeather: () -> Unit = {},
    onNavigateToReport: () -> Unit = {},
    onNavigateToAdmin: (() -> Unit)? = null,
    onNavigateToMesh: (() -> Unit)? = null,
    viewModel: AuthViewModel = hiltViewModel()
) {
    val userSession by viewModel.userSession.collectAsState()
    val currentUser = (userSession as? UserSession.Authenticated)?.user
    
    val scrollState = rememberScrollState()
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Profile") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = onNavigateToSettings) {
                        Icon(Icons.Default.Settings, contentDescription = "Settings")
                    }
                }
            )
        },
        bottomBar = {
            OceanBottomNavBar(
                activeTab = "profile",
                onNavigateToHome = onNavigateToHome,
                onNavigateToAlerts = onNavigateToAlerts,
                onNavigateToWeather = onNavigateToWeather,
                onNavigateToReport = onNavigateToReport,
                onNavigateToProfile = { },
                userRole = currentUser?.role ?: com.oceansentinels.app.domain.model.UserRole.PUBLIC,
                onNavigateToAdmin = onNavigateToAdmin,
                onNavigateToMesh = onNavigateToMesh
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(scrollState)
        ) {
            if (currentUser != null) {
                // Profile Header
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(24.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        // Avatar
                        Surface(
                            shape = MaterialTheme.shapes.extraLarge,
                            color = OceanColors.Primary.copy(alpha = 0.1f),
                            modifier = Modifier.size(100.dp)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Text(
                                    text = "${currentUser.firstName.firstOrNull() ?: ""}${currentUser.lastName.firstOrNull() ?: ""}",
                                    style = MaterialTheme.typography.displaySmall,
                                    fontWeight = FontWeight.Bold,
                                    color = OceanColors.Primary
                                )
                            }
                        }
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        Text(
                            text = "${currentUser.firstName} ${currentUser.lastName}",
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Bold
                        )
                        
                        Text(
                            text = "@${currentUser.username}",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        RoleBadge(role = currentUser.role)
                    }
                }
                
                HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))
                
                // Profile Details
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    ProfileDetailItem(
                        icon = Icons.Default.Email,
                        label = "Email",
                        value = currentUser.email
                    )
                    
                    currentUser.phone?.let { phone ->
                        ProfileDetailItem(
                            icon = Icons.Default.Phone,
                            label = "Phone",
                            value = phone
                        )
                    }
                    
                    currentUser.location?.let { location ->
                        ProfileDetailItem(
                            icon = Icons.Default.LocationOn,
                            label = "Location",
                            value = location
                        )
                    }
                    
                    ProfileDetailItem(
                        icon = Icons.Default.Badge,
                        label = "User ID",
                        value = "#${currentUser.id}"
                    )
                }
                
                HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))
                
                // Account Actions
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    Text(
                        text = "Account",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                    
                    Spacer(modifier = Modifier.height(12.dp))
                    
                    ProfileActionItem(
                        icon = Icons.Default.Settings,
                        title = "Settings",
                        subtitle = "App preferences and notifications",
                        onClick = onNavigateToSettings
                    )
                    
                    ProfileActionItem(
                        icon = Icons.Default.Help,
                        title = "Help & Support",
                        subtitle = "FAQs and contact support",
                        onClick = { }
                    )
                    
                    ProfileActionItem(
                        icon = Icons.Default.Info,
                        title = "About",
                        subtitle = "App version and legal info",
                        onClick = { }
                    )
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Logout button
                OceanDangerButton(
                    text = "Sign Out",
                    onClick = {
                        viewModel.logout()
                        onLogout()
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    icon = Icons.Default.Logout
                )
                
                Spacer(modifier = Modifier.height(32.dp))
            } else {
                // Loading or not authenticated
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            }
        }
    }
}

@Composable
private fun ProfileDetailItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    value: String
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = OceanColors.Primary,
            modifier = Modifier.size(24.dp)
        )
        
        Spacer(modifier = Modifier.width(16.dp))
        
        Column {
            Text(
                text = label,
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = value,
                style = MaterialTheme.typography.bodyLarge
            )
        }
    }
}

@Composable
private fun ProfileActionItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    subtitle: String,
    onClick: () -> Unit
) {
    Surface(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        color = MaterialTheme.colorScheme.surface
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(24.dp)
            )
            
            Spacer(modifier = Modifier.width(16.dp))
            
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.bodyLarge
                )
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            Icon(
                imageVector = Icons.Default.ChevronRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

/**
 * Settings screen
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onNavigateBack: () -> Unit,
    onNavigateToTerms: () -> Unit = {}
) {
    val themeViewModel: com.oceansentinels.app.presentation.viewmodel.ThemeViewModel = hiltViewModel()
    
    val isDarkMode by themeViewModel.isDarkMode.collectAsState()
    val offlineMode by themeViewModel.isOfflineMode.collectAsState()
    
    var notificationsEnabled by remember { mutableStateOf(true) }
    var locationEnabled by remember { mutableStateOf(true) }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Settings") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
        ) {
            // Notifications Section
            SettingsSection(title = "Notifications") {
                SettingsToggleItem(
                    icon = Icons.Default.Notifications,
                    title = "Push Notifications",
                    subtitle = "Receive alerts for incidents and updates",
                    checked = notificationsEnabled,
                    onCheckedChange = { notificationsEnabled = it }
                )
            }
            
            HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))
            
            // Location Section
            SettingsSection(title = "Location") {
                SettingsToggleItem(
                    icon = Icons.Default.LocationOn,
                    title = "Location Services",
                    subtitle = "Allow app to access your location",
                    checked = locationEnabled,
                    onCheckedChange = { locationEnabled = it }
                )
            }
            
            HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))
            
            // Appearance Section
            SettingsSection(title = "Appearance") {
                SettingsToggleItem(
                    icon = Icons.Default.DarkMode,
                    title = "Dark Mode",
                    subtitle = "Use dark theme",
                    checked = isDarkMode,
                    onCheckedChange = { themeViewModel.toggleDarkMode(it) }
                )
            }
            
            HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))
            
            // Data Section
            SettingsSection(title = "Data") {
                SettingsToggleItem(
                    icon = Icons.Default.CloudOff,
                    title = "Offline Mode",
                    subtitle = "Cache data for offline access",
                    checked = offlineMode,
                    onCheckedChange = { themeViewModel.toggleOfflineMode(it) }
                )
                
                SettingsClickItem(
                    icon = Icons.Default.DeleteSweep,
                    title = "Clear Cache",
                    subtitle = "Free up storage space",
                    onClick = { }
                )
            }
            
            HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))
            
            // Legal Section
            SettingsSection(title = "Legal") {
                SettingsClickItem(
                    icon = Icons.Default.Description,
                    title = "Terms & Conditions",
                    subtitle = "Read our terms of service",
                    onClick = onNavigateToTerms
                )
                
                SettingsClickItem(
                    icon = Icons.Default.PrivacyTip,
                    title = "Privacy Policy",
                    subtitle = "How we handle your data",
                    onClick = onNavigateToTerms
                )
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // App version
            Text(
                text = "Version 1.0.0",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier
                    .align(Alignment.CenterHorizontally)
                    .padding(16.dp)
            )
        }
    }
}

@Composable
private fun SettingsSection(
    title: String,
    content: @Composable ColumnScope.() -> Unit
) {
    Column(
        modifier = Modifier.padding(16.dp)
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            color = OceanColors.Primary
        )
        
        Spacer(modifier = Modifier.height(12.dp))
        
        content()
    }
}

@Composable
private fun SettingsToggleItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    subtitle: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(24.dp)
        )
        
        Spacer(modifier = Modifier.width(16.dp))
        
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge
            )
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            colors = SwitchDefaults.colors(
                checkedThumbColor = OceanColors.Primary,
                checkedTrackColor = OceanColors.Primary.copy(alpha = 0.5f)
            )
        )
    }
}

@Composable
private fun SettingsClickItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    subtitle: String,
    onClick: () -> Unit
) {
    Surface(
        onClick = onClick,
        color = MaterialTheme.colorScheme.surface
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(24.dp)
            )
            
            Spacer(modifier = Modifier.width(16.dp))
            
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.bodyLarge
                )
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            Icon(
                imageVector = Icons.Default.ChevronRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
