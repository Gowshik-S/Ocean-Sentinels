package com.oceansentinels.app.presentation.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.oceansentinels.app.domain.model.UserRole
import com.oceansentinels.app.presentation.ui.theme.OceanColors

/**
 * Active tab naming: "home", "alerts", "weather", "report", "mesh", "profile", "admin"
 */
@Composable
fun OceanBottomNavBar(
    activeTab: String,
    onNavigateToHome: () -> Unit,
    onNavigateToAlerts: () -> Unit,
    onNavigateToWeather: () -> Unit,
    onNavigateToReport: () -> Unit,
    onNavigateToProfile: () -> Unit,
    userRole: UserRole = UserRole.PUBLIC,
    onNavigateToAdmin: (() -> Unit)? = null,
    onNavigateToMesh: (() -> Unit)? = null
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = OceanColors.Primary,
        shape = RoundedCornerShape(topStart = 8.dp, topEnd = 8.dp),
        shadowElevation = 8.dp
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .height(71.dp)
                .padding(horizontal = 12.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            OceanNavItem(Icons.Default.Home, "Home", activeTab == "home", onNavigateToHome)
            OceanNavItem(Icons.Default.Warning, "Alerts", activeTab == "alerts", onNavigateToAlerts)
            OceanNavItem(Icons.Default.Cloud, "Weather", activeTab == "weather", onNavigateToWeather)
            OceanNavItem(Icons.Default.CameraAlt, "Report", activeTab == "report", onNavigateToReport)
            if (onNavigateToMesh != null) {
                OceanNavItem(Icons.Default.Hub, "Mesh", activeTab == "mesh", onNavigateToMesh)
            }
            if (userRole == UserRole.ADMIN && onNavigateToAdmin != null) {
                OceanNavItem(Icons.Default.AdminPanelSettings, "Admin", activeTab == "admin", onNavigateToAdmin)
            }
            if (userRole == UserRole.RESCUE_TEAM && onNavigateToAdmin != null) {
                OceanNavItem(Icons.Default.LocalFireDepartment, "Rescue", activeTab == "rescue", onNavigateToAdmin)
            }
            if (userRole == UserRole.AUTHORITY && onNavigateToAdmin != null) {
                OceanNavItem(Icons.Default.Shield, "Authority", activeTab == "authority", onNavigateToAdmin)
            }
            OceanNavItem(Icons.Default.Person, "Profile", activeTab == "profile", onNavigateToProfile)
        }
    }
}

@Composable
private fun OceanNavItem(
    icon: ImageVector,
    label: String,
    selected: Boolean,
    onClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .clickable(onClick = onClick)
            .padding(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = icon,
            contentDescription = label,
            modifier = Modifier.size(28.dp),
            tint = if (selected) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.5f)
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = if (selected) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.5f),
            fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal
        )
    }
}
