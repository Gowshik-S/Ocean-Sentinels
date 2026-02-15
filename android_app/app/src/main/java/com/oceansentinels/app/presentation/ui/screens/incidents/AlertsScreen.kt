package com.oceansentinels.app.presentation.ui.screens.incidents

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.layout.statusBarsPadding
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
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.oceansentinels.app.domain.model.IncidentStatus
import com.oceansentinels.app.domain.model.UrgencyLevel
import com.oceansentinels.app.presentation.ui.theme.OceanColors
import com.oceansentinels.app.presentation.viewmodel.IncidentViewModel
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import java.util.Locale
import kotlinx.coroutines.delay

/**
 * Alerts Screen - matches app0 Figma design
 * Yellow header, 2x2 stat cards with progress bars,
 * filter section (light blue), refresh/live updated buttons,
 * live feed panel with map placeholder
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AlertsScreen(
    onNavigateBack: () -> Unit,
    onNavigateToIncidentDetail: (Int) -> Unit,
    viewModel: IncidentViewModel = hiltViewModel()
) {
    val incidents by viewModel.incidents.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    
    // Auto-load incidents when screen opens
    LaunchedEffect(Unit) {
        viewModel.loadIncidents()
    }
    
    // Calculate stats
    val totalReports = incidents.size
    val oneHourAgo = LocalDateTime.now().minus(1, ChronoUnit.HOURS)
    val lastHourReports = incidents.count { incident ->
        incident.createdAt.isAfter(oneHourAgo)
    }
    val resolvedCount = incidents.count { incident -> incident.status == IncidentStatus.RESOLVED }
    val pendingCount = incidents.count { incident -> incident.status == IncidentStatus.PENDING }
    val inProgressCount = incidents.count { incident -> incident.status == IncidentStatus.IN_PROGRESS }
    val criticalCount = incidents.count { incident -> incident.urgency == UrgencyLevel.CRITICAL }
    
    // Live updated time — refreshes every second
    var liveUpdatedTime by remember {
        mutableStateOf(
            LocalDateTime.now().format(DateTimeFormatter.ofPattern("HH:mm:ss", Locale.ENGLISH))
        )
    }
    LaunchedEffect(Unit) {
        while (true) {
            delay(1000L)
            liveUpdatedTime = LocalDateTime.now().format(
                DateTimeFormatter.ofPattern("HH:mm:ss", Locale.ENGLISH)
            )
        }
    }
    
    // Category filter state
    var selectedCategory by remember { mutableStateOf("All") }
    var categoryExpanded by remember { mutableStateOf(false) }
    
    Scaffold(
        topBar = {
            // Yellow top bar matching Figma (70dp)
            Surface(
                modifier = Modifier
                    .fillMaxWidth(),
                color = OceanColors.Primary
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .statusBarsPadding()
                        .height(70.dp)
                        .padding(horizontal = 9.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            Icons.Default.ArrowBack,
                            contentDescription = "Back",
                            modifier = Modifier.size(40.dp),
                            tint = MaterialTheme.colorScheme.onPrimary
                        )
                    }
                    
                    Spacer(modifier = Modifier.width(8.dp))
                    
                    Text(
                        text = "Alerts",
                        style = MaterialTheme.typography.headlineMedium,
                        color = MaterialTheme.colorScheme.onPrimary
                    )
                    
                    Spacer(modifier = Modifier.weight(1f))
                    
                    IconButton(onClick = { }) {
                        Icon(
                            Icons.Default.Search,
                            contentDescription = "Search",
                            modifier = Modifier.size(45.dp),
                            tint = MaterialTheme.colorScheme.onPrimary
                        )
                    }
                }
            }
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .background(MaterialTheme.colorScheme.background)
                .padding(horizontal = 20.dp, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // ===== 2x2 STAT CARDS GRID =====
            item {
                // Top row: Active Hazards + Critical Alerts
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    AlertStatCard(
                        label = "Active Hazards",
                        value = inProgressCount.toString(),
                        icon = Icons.Default.Warning,
                        cardColor = OceanColors.Error,
                        progressFraction = if (totalReports > 0) inProgressCount.toFloat() / totalReports else 0f,
                        modifier = Modifier.weight(1f)
                    )
                    AlertStatCard(
                        label = "Critical Alerts",
                        value = criticalCount.toString(),
                        icon = Icons.Default.NotificationsActive,
                        cardColor = OceanColors.Warning,
                        progressFraction = if (totalReports > 0) criticalCount.toFloat() / totalReports else 0f,
                        modifier = Modifier.weight(1f)
                    )
                }
            }
            
            item {
                // Bottom row: Total Reports + Last Hour
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    AlertStatCard(
                        label = "Total Reports",
                        value = totalReports.toString(),
                        icon = Icons.Default.Visibility,
                        cardColor = OceanColors.Info,
                        progressFraction = 1f,
                        modifier = Modifier.weight(1f)
                    )
                    AlertStatCard(
                        label = "Last Hour",
                        value = lastHourReports.toString(),
                        icon = Icons.Default.AccessAlarm,
                        cardColor = OceanColors.Success,
                        progressFraction = if (totalReports > 0) lastHourReports.toFloat() / totalReports else 0f,
                        modifier = Modifier.weight(1f)
                    )
                }
            }
            
            // ===== FILTERS SECTION =====
            item {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .alpha(0.5f)
                        .background(OceanColors.FilterBlue, RoundedCornerShape(8.dp))
                        .padding(16.dp)
                ) {
                    Column {
                        // Filter header
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                Icons.Default.FilterList,
                                contentDescription = null,
                                modifier = Modifier.size(24.dp),
                                tint = MaterialTheme.colorScheme.onBackground
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Filters",
                                style = MaterialTheme.typography.titleLarge,
                                color = MaterialTheme.colorScheme.onBackground
                            )
                        }
                        
                        Spacer(modifier = Modifier.height(12.dp))
                        
                        // Category dropdown
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "Category:",
                                style = MaterialTheme.typography.titleLarge,
                                color = MaterialTheme.colorScheme.onBackground
                            )
                            Spacer(modifier = Modifier.width(12.dp))
                            Box(modifier = Modifier.weight(1f)) {
                                Surface(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clickable { categoryExpanded = true },
                                    color = MaterialTheme.colorScheme.surface,
                                    shape = RoundedCornerShape(7.dp),
                                    border = ButtonDefaults.outlinedButtonBorder
                                ) {
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(horizontal = 16.dp, vertical = 10.dp),
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.SpaceBetween
                                    ) {
                                        Text(
                                            text = selectedCategory,
                                            style = MaterialTheme.typography.bodyMedium,
                                            color = MaterialTheme.colorScheme.onBackground
                                        )
                                        Icon(
                                            Icons.Default.KeyboardArrowDown,
                                            contentDescription = null,
                                            tint = MaterialTheme.colorScheme.onBackground
                                        )
                                    }
                                }
                                DropdownMenu(
                                    expanded = categoryExpanded,
                                    onDismissRequest = { categoryExpanded = false }
                                ) {
                                    listOf("All", "Pollution", "Marine Life", "Weather", "Navigation").forEach { category ->
                                        DropdownMenuItem(
                                            text = { Text(category) },
                                            onClick = {
                                                selectedCategory = category
                                                categoryExpanded = false
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // ===== REFRESH + LIVE UPDATED ROW =====
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Refresh button (purple)
                    Surface(
                        modifier = Modifier
                            .clickable { viewModel.loadIncidents() }
                            .alpha(0.5f),
                        color = OceanColors.FilterPurple,
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 20.dp, vertical = 10.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Default.Refresh,
                                contentDescription = null,
                                modifier = Modifier.size(20.dp),
                                tint = MaterialTheme.colorScheme.onSecondary
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Refresh",
                                style = MaterialTheme.typography.titleLarge,
                                color = MaterialTheme.colorScheme.onSecondary
                            )
                        }
                    }
                    
                    // Live Updated badge (purple, lighter)
                    Surface(
                        modifier = Modifier.alpha(0.3f),
                        color = OceanColors.FilterPurple,
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Text(
                            text = "Live Updated: $liveUpdatedTime",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSecondary,
                            modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp)
                        )
                    }
                }
            }
            
            // ===== LIVE FEED SECTION =====
            item {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(345.dp),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    // Left: Map placeholder
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxHeight()
                            .background(
                                OceanColors.DashboardBlue.copy(alpha = 0.2f),
                                RoundedCornerShape(8.dp)
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Icon(
                                Icons.Default.Map,
                                contentDescription = null,
                                modifier = Modifier.size(48.dp),
                                tint = OceanColors.DashboardBlue
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = "Map View",
                                style = MaterialTheme.typography.bodyMedium,
                                color = OceanColors.DashboardBlue
                            )
                        }
                    }
                    
                    // Right: Live Feed panel (white with black border)
                    Column(
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxHeight()
                            .border(3.dp, MaterialTheme.colorScheme.onBackground, RoundedCornerShape(8.dp))
                            .clip(RoundedCornerShape(8.dp))
                            .background(MaterialTheme.colorScheme.surface)
                    ) {
                        // Live Feed header with dots
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 12.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            // Blue dot
                            Box(
                                modifier = Modifier
                                    .size(12.dp)
                                    .background(OceanColors.LiveFeedBlue, CircleShape)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Live Feed",
                                style = MaterialTheme.typography.titleLarge,
                                color = MaterialTheme.colorScheme.onBackground
                            )
                            Spacer(modifier = Modifier.weight(1f))
                            // Red dot
                            Box(
                                modifier = Modifier
                                    .size(10.dp)
                                    .alpha(0.7f)
                                    .background(OceanColors.LiveFeedRed, CircleShape)
                            )
                        }
                        
                        // Separator line
                        Divider(
                            color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.3f),
                            thickness = 1.dp
                        )
                        
                        // Feed items (3 gray placeholders or real data)
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(12.dp),
                            verticalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            val feedIncidents = incidents.take(3)
                            if (feedIncidents.isNotEmpty()) {
                                feedIncidents.forEach { incident ->
                                    Surface(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .height(67.dp)
                                            .clickable { onNavigateToIncidentDetail(incident.id) },
                                        color = OceanColors.PlaceholderGray,
                                        shape = RoundedCornerShape(8.dp)
                                    ) {
                                        Column(
                                            modifier = Modifier.padding(8.dp),
                                            verticalArrangement = Arrangement.Center
                                        ) {
                                            Text(
                                                text = incident.hazardType.displayName,
                                                style = MaterialTheme.typography.bodySmall.copy(fontWeight = FontWeight.Medium),
                                                color = MaterialTheme.colorScheme.onBackground
                                            )
                                            Text(
                                                text = incident.location,
                                                style = MaterialTheme.typography.labelSmall,
                                                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
                                            )
                                        }
                                    }
                                }
                            } else {
                                // Empty placeholders
                                repeat(3) {
                                    Box(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .height(67.dp)
                                            .alpha(if (it == 2) 0.8f else 1f)
                                            .background(OceanColors.PlaceholderGray, RoundedCornerShape(8.dp))
                                    )
                                }
                            }
                        }
                    }
                }
            }
            
            // Recent Alerts List
            if (incidents.isNotEmpty()) {
                item {
                    Text(
                        text = "Recent Alerts",
                        style = MaterialTheme.typography.titleLarge,
                        modifier = Modifier.padding(top = 8.dp),
                        color = MaterialTheme.colorScheme.onBackground
                    )
                }
                
                items(incidents.take(5)) { incident ->
                    AlertListItem(
                        title = incident.hazardType.displayName,
                        location = incident.location,
                        status = incident.status.value,
                        urgency = incident.urgency.value,
                        onClick = { onNavigateToIncidentDetail(incident.id) }
                    )
                }
            }
            
            // Loading indicator
            if (isLoading) {
                item {
                    Box(
                        modifier = Modifier.fillMaxWidth(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(color = OceanColors.Primary)
                    }
                }
            }
            
            // Bottom spacing
            item { Spacer(modifier = Modifier.height(16.dp)) }
        }
    }
}

/**
 * Stat card matching Figma design - colored bg at 0.3 alpha,
 * icon in small colored square, label, value, progress bar
 */
@Composable
private fun AlertStatCard(
    label: String,
    value: String,
    icon: ImageVector,
    cardColor: Color,
    progressFraction: Float,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .height(126.dp)
            .background(cardColor.copy(alpha = 0.3f), RoundedCornerShape(12.dp))
            .padding(12.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            // Icon in colored square + label
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .size(28.dp)
                        .background(cardColor, RoundedCornerShape(7.dp)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = icon,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp),
                        tint = MaterialTheme.colorScheme.onSecondary
                    )
                }
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = label,
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onBackground
                )
            }
            
            // Value
            Text(
                text = value,
                style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.onBackground
            )
            
            // Progress bar (white track, colored fill)
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(6.dp)
                    .background(MaterialTheme.colorScheme.surface, RoundedCornerShape(3.dp))
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth(progressFraction.coerceIn(0f, 1f))
                        .height(6.dp)
                        .background(cardColor, RoundedCornerShape(3.dp))
                )
            }
        }
    }
}

@Composable
private fun AlertListItem(
    title: String,
    location: String,
    status: String,
    urgency: String,
    onClick: () -> Unit
) {
    val statusColor = when (status.lowercase()) {
        "resolved" -> OceanColors.Green
        "in_progress" -> OceanColors.Orange
        "pending" -> OceanColors.Purple
        else -> OceanColors.Gray
    }
    
    val urgencyColor = when (urgency.lowercase()) {
        "critical" -> OceanColors.Error
        "high" -> OceanColors.Orange
        "medium" -> OceanColors.Primary
        else -> OceanColors.Green
    }
    
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        shape = RoundedCornerShape(8.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Urgency indicator dot
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .background(urgencyColor, CircleShape)
            )
            
            Spacer(modifier = Modifier.width(12.dp))
            
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onBackground
                )
                Text(
                    text = location,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
                )
            }
            
            // Status badge
            Surface(
                color = statusColor.copy(alpha = 0.2f),
                shape = RoundedCornerShape(12.dp)
            ) {
                Text(
                    text = status.replace("_", " ").replaceFirstChar { it.uppercase() },
                    style = MaterialTheme.typography.labelSmall,
                    color = statusColor,
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                )
            }
        }
    }
}
