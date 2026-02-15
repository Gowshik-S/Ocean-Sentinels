package com.oceansentinels.app.presentation.ui.screens.home

import android.Manifest
import android.content.pm.PackageManager
import android.location.Geocoder
import androidx.compose.animation.core.*
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.basicMarquee
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.hilt.navigation.compose.hiltViewModel
import com.google.android.gms.location.LocationServices
import com.oceansentinels.app.domain.model.IncidentFilters
import com.oceansentinels.app.domain.model.IncidentStatus
import com.oceansentinels.app.domain.model.UserRole
import com.oceansentinels.app.domain.model.UserSession
import com.oceansentinels.app.presentation.ui.components.*
import com.oceansentinels.app.presentation.ui.theme.OceanColors
import com.oceansentinels.app.presentation.viewmodel.AnalyticsViewModel
import com.oceansentinels.app.presentation.viewmodel.AuthViewModel
import com.oceansentinels.app.presentation.viewmodel.IncidentViewModel
import com.oceansentinels.app.presentation.viewmodel.WeatherViewModel
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlinx.coroutines.delay

/**
 * Home screen - matches app Figma design
 * Location header, yellow marquee banner, blue dashboard cards,
 * ocean watermark background, bottom navigation bar
 */
@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun HomeScreen(
    onNavigateToMap: () -> Unit,
    onNavigateToReport: () -> Unit,
    onNavigateToMyReports: () -> Unit,
    onNavigateToIncidents: () -> Unit,
    onNavigateToAnalytics: () -> Unit,
    onNavigateToWeather: () -> Unit,
    onNavigateToAdmin: () -> Unit,
    onNavigateToProfile: () -> Unit,
    onNavigateToMesh: () -> Unit = {},
    onLogout: () -> Unit,
    authViewModel: AuthViewModel = hiltViewModel(),
    analyticsViewModel: AnalyticsViewModel = hiltViewModel(),
    weatherViewModel: WeatherViewModel = hiltViewModel()
) {
    val incidentViewModel: IncidentViewModel = hiltViewModel()
    
    val userSession by authViewModel.userSession.collectAsState()
    val dashboardAnalytics by analyticsViewModel.dashboardAnalytics.collectAsState()
    val isLoading by analyticsViewModel.isLoading.collectAsState()
    val currentWeather by weatherViewModel.currentWeather.collectAsState()
    val indianCityWeather by weatherViewModel.indianCityWeather.collectAsState()
    val weatherAlerts by weatherViewModel.weatherAlerts.collectAsState()
    val incidents by incidentViewModel.incidents.collectAsState()
    val assignedIncidents by incidentViewModel.assignedIncidents.collectAsState()
    
    val scrollState = rememberScrollState()
    
    val currentUser = (userSession as? UserSession.Authenticated)?.user
    val userRole = currentUser?.role ?: UserRole.PUBLIC
    
    // Current time display — updates every second
    var currentTime by remember {
        mutableStateOf(
            LocalDateTime.now().format(DateTimeFormatter.ofPattern("HH:mm:ss 'Hrs,' EEEE", Locale.ENGLISH))
        )
    }
    LaunchedEffect(Unit) {
        while (true) {
            delay(1000L)
            currentTime = LocalDateTime.now().format(
                DateTimeFormatter.ofPattern("HH:mm:ss 'Hrs,' EEEE", Locale.ENGLISH)
            )
        }
    }
    
    val userLocation = currentUser?.location ?: "Chennai, India"
    
    // GPS auto-detect location
    val context = LocalContext.current
    var detectedLocation by remember { mutableStateOf<String?>(null) }
    val displayLocation = detectedLocation ?: userLocation
    
    // Auto-detect location via GPS
    LaunchedEffect(Unit) {
        val hasLocationPermission = ContextCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED || ContextCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        if (hasLocationPermission) {
            try {
                val fusedLocationClient = LocationServices.getFusedLocationProviderClient(context)
                fusedLocationClient.lastLocation.addOnSuccessListener { location ->
                    if (location != null) {
                        try {
                            @Suppress("DEPRECATION")
                            val geocoder = Geocoder(context, Locale.getDefault())
                            val addresses = geocoder.getFromLocation(location.latitude, location.longitude, 1)
                            if (!addresses.isNullOrEmpty()) {
                                val address = addresses[0]
                                val city = address.locality ?: address.subAdminArea ?: address.adminArea
                                val country = address.countryName
                                detectedLocation = if (city != null && country != null) {
                                    "$city, $country"
                                } else if (city != null) {
                                    city
                                } else {
                                    null
                                }
                            }
                        } catch (_: Exception) {
                            // Geocoder failed, use default
                        }
                    }
                }
            } catch (_: SecurityException) {
                // Permission denied
            }
        }
    }
    
    // Load incidents for rescue team dashboard — only assigned-to-me
    LaunchedEffect(userRole) {
        if (userRole == UserRole.RESCUE_TEAM) {
            incidentViewModel.loadAssignedIncidents()
        }
    }
    
    // Update weather based on detected or user location
    LaunchedEffect(displayLocation) {
        val city = displayLocation.split(",").firstOrNull()?.trim() ?: "Chennai"
        weatherViewModel.updateLocation(city)
    }
    
    // Build marquee alert text from live API data
    val marqueeText = remember(weatherAlerts) {
        if (weatherAlerts.isNotEmpty()) {
            weatherAlerts.joinToString("   \u2022   ")
        } else {
            "No active weather alerts for your region   \u2022   Ocean Sentinels — Monitoring coastal safety"
        }
    }
    
    Scaffold(
        bottomBar = {
            // Bottom navigation bar - shared component
            OceanBottomNavBar(
                activeTab = "home",
                onNavigateToHome = { },
                onNavigateToAlerts = onNavigateToIncidents,
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
                .background(MaterialTheme.colorScheme.background)
        ) {
            // Ocean watermark background circle - matching Figma 0.5 alpha
            Box(
                modifier = Modifier
                    .size(420.dp)
                    .offset(x = (-140).dp, y = 20.dp)
                    .alpha(0.08f)
                    .background(OceanColors.Secondary, shape = RoundedCornerShape(50))
            )
            
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(scrollState)
            ) {
                // Header section - Logo + Time + Location
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(start = 20.dp, end = 20.dp, top = 16.dp)
                ) {
                    // Logo and Time/Location row
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        // Logo icon - top left
                        Surface(
                            modifier = Modifier.size(40.dp),
                            shape = CircleShape,
                            color = OceanColors.Secondary
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(
                                    Icons.Default.Waves,
                                    contentDescription = "Ocean Sentinels",
                                    tint = OceanColors.Primary,
                                    modifier = Modifier.size(24.dp)
                                )
                            }
                        }
                        Column(horizontalAlignment = Alignment.End) {
                            Text(
                                text = currentTime,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onBackground
                            )
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    Icons.Default.LocationOn,
                                    contentDescription = null,
                                    modifier = Modifier.size(20.dp),
                                    tint = MaterialTheme.colorScheme.onBackground
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    text = displayLocation,
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onBackground
                                )
                            }
                        }
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Yellow marquee banner - matching Figma design
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 0.dp)
                        .height(27.dp)
                        .background(OceanColors.Primary, RoundedCornerShape(8.dp)),
                    contentAlignment = Alignment.CenterStart
                ) {
                    Text(
                        text = marqueeText,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onPrimary,
                        maxLines = 1,
                        modifier = Modifier
                            .padding(horizontal = 20.dp)
                            .basicMarquee(
                                iterations = Int.MAX_VALUE,
                                delayMillis = 0,
                                velocity = 40.dp
                            )
                    )
                }
                
                Spacer(modifier = Modifier.height(20.dp))
                
                // LIVE DASHBOARD card - uses theme background color
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp)
                        .clickable { onNavigateToMap() },
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surface
                    ),
                    shape = RoundedCornerShape(8.dp),
                    elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(279.dp)
                            .padding(20.dp)
                    ) {
                        Column(
                            modifier = Modifier.fillMaxSize(),
                            verticalArrangement = Arrangement.SpaceBetween
                        ) {
                            // Top: LIVE badge with pulsing dot
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                // Pulsing LIVE badge
                                LivePulseBadge()
                                
                                // Active zones count
                                Surface(
                                    color = OceanColors.Secondary.copy(alpha = 0.15f),
                                    shape = RoundedCornerShape(12.dp)
                                ) {
                                    Row(
                                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Icon(
                                            Icons.Default.MyLocation,
                                            contentDescription = null,
                                            modifier = Modifier.size(14.dp),
                                            tint = OceanColors.DashboardBlue
                                        )
                                        Spacer(modifier = Modifier.width(6.dp))
                                        Text(
                                            text = "${dashboardAnalytics?.activeIncidents ?: 0} Active Zones",
                                            style = MaterialTheme.typography.labelSmall,
                                            color = Color(0xFF333333)
                                        )
                                    }
                                }
                            }
                            
                            // Middle: Role-specific content
                            when (userRole) {
                                UserRole.PUBLIC -> {
                                    // Citizen: Show local weather from IndianAPI
                                    if (indianCityWeather != null) {
                                        Column(
                                            modifier = Modifier.fillMaxWidth(),
                                            horizontalAlignment = Alignment.CenterHorizontally
                                        ) {
                                            val temp = indianCityWeather?.weather?.current?.temperature?.max?.value
                                            val humidity = indianCityWeather?.weather?.current?.humidity?.morning
                                            val city = indianCityWeather?.city ?: displayLocation
                                            
                                            Text(
                                                text = "Local Weather — $city",
                                                style = MaterialTheme.typography.titleSmall,
                                                fontWeight = FontWeight.SemiBold,
                                                color = OceanColors.DashboardBlue
                                            )
                                            Spacer(modifier = Modifier.height(8.dp))
                                            Row(
                                                modifier = Modifier.fillMaxWidth(),
                                                horizontalArrangement = Arrangement.SpaceEvenly
                                            ) {
                                                DashboardStatItem(
                                                    value = "${temp?.toInt() ?: "--"}°C",
                                                    label = "Temp",
                                                    color = OceanColors.DashboardBlue
                                                )
                                                DashboardStatItem(
                                                    value = "${humidity?.toInt() ?: "--"}%",
                                                    label = "Humidity",
                                                    color = OceanColors.Info
                                                )
                                                val forecast = indianCityWeather?.weather?.forecast?.firstOrNull()
                                                DashboardStatItem(
                                                    value = forecast?.description?.take(12) ?: "Clear",
                                                    label = "Condition",
                                                    color = OceanColors.Success
                                                )
                                            }
                                        }
                                    } else if (currentWeather != null) {
                                        // Fallback to WeatherAPI data
                                        Column(
                                            modifier = Modifier.fillMaxWidth(),
                                            horizontalAlignment = Alignment.CenterHorizontally
                                        ) {
                                            Text(
                                                text = "Local Weather — ${currentWeather!!.location.name}",
                                                style = MaterialTheme.typography.titleSmall,
                                                fontWeight = FontWeight.SemiBold,
                                                color = OceanColors.DashboardBlue
                                            )
                                            Spacer(modifier = Modifier.height(8.dp))
                                            Row(
                                                modifier = Modifier.fillMaxWidth(),
                                                horizontalArrangement = Arrangement.SpaceEvenly
                                            ) {
                                                DashboardStatItem(
                                                    value = "${currentWeather!!.current.tempC.toInt()}°C",
                                                    label = "Temp",
                                                    color = OceanColors.DashboardBlue
                                                )
                                                DashboardStatItem(
                                                    value = "${currentWeather!!.current.humidity}%",
                                                    label = "Humidity",
                                                    color = OceanColors.Info
                                                )
                                                DashboardStatItem(
                                                    value = currentWeather!!.current.condition.text.take(12),
                                                    label = "Condition",
                                                    color = OceanColors.Success
                                                )
                                            }
                                        }
                                    } else if (isLoading) {
                                        Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                                            CircularProgressIndicator(color = OceanColors.DashboardBlue, modifier = Modifier.size(32.dp))
                                        }
                                    } else {
                                        Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                                            Text("LIVE DASHBOARD", style = MaterialTheme.typography.headlineSmall, color = OceanColors.DashboardBlue)
                                        }
                                    }
                                }
                                UserRole.RESCUE_TEAM -> {
                                    // Rescue Team: Show my assigned jobs only
                                    val activeJobs = assignedIncidents.filter { it.status == IncidentStatus.IN_PROGRESS || it.status == IncidentStatus.VERIFIED }
                                    Column(
                                        modifier = Modifier.fillMaxWidth(),
                                        horizontalAlignment = Alignment.CenterHorizontally
                                    ) {
                                        Text(
                                            text = "Assigned Jobs",
                                            style = MaterialTheme.typography.titleSmall,
                                            fontWeight = FontWeight.SemiBold,
                                            color = OceanColors.DashboardBlue
                                        )
                                        Spacer(modifier = Modifier.height(8.dp))
                                        Row(
                                            modifier = Modifier.fillMaxWidth(),
                                            horizontalArrangement = Arrangement.SpaceEvenly
                                        ) {
                                            DashboardStatItem(
                                                value = activeJobs.size.toString(),
                                                label = "Active Jobs",
                                                color = OceanColors.Error
                                            )
                                            DashboardStatItem(
                                                value = assignedIncidents.filter { it.status == IncidentStatus.VERIFIED }.size.toString(),
                                                label = "Pending Deploy",
                                                color = OceanColors.Warning
                                            )
                                            DashboardStatItem(
                                                value = assignedIncidents.filter { it.status == IncidentStatus.RESOLVED }.size.toString(),
                                                label = "Completed",
                                                color = OceanColors.Success
                                            )
                                        }
                                    }
                                }
                                else -> {
                                    // Admin/Authority: Show incident stats
                                    if (dashboardAnalytics != null) {
                                        Row(
                                            modifier = Modifier.fillMaxWidth(),
                                            horizontalArrangement = Arrangement.SpaceEvenly
                                        ) {
                                            DashboardStatItem(
                                                value = (dashboardAnalytics?.totalIncidents ?: 0).toString(),
                                                label = "Total",
                                                color = OceanColors.DashboardBlue
                                            )
                                            DashboardStatItem(
                                                value = (dashboardAnalytics?.activeIncidents ?: 0).toString(),
                                                label = "Active",
                                                color = OceanColors.Error
                                            )
                                            DashboardStatItem(
                                                value = (dashboardAnalytics?.pendingCount ?: 0).toString(),
                                                label = "Pending",
                                                color = OceanColors.Warning
                                            )
                                            DashboardStatItem(
                                                value = (dashboardAnalytics?.resolvedCount ?: 0).toString(),
                                                label = "Resolved",
                                                color = OceanColors.Success
                                            )
                                        }
                                    } else if (isLoading) {
                                        Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                                            CircularProgressIndicator(color = OceanColors.DashboardBlue, modifier = Modifier.size(32.dp))
                                        }
                                    } else {
                                        Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                                            Text("LIVE DASHBOARD", style = MaterialTheme.typography.headlineSmall, color = OceanColors.DashboardBlue)
                                        }
                                    }
                                }
                            }
                            
                            // Bottom: Status indicators row
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .background(
                                        Color(0xFFF5F5F5),
                                        RoundedCornerShape(8.dp)
                                    )
                                    .padding(horizontal = 12.dp, vertical = 10.dp),
                                horizontalArrangement = Arrangement.SpaceEvenly
                            ) {
                                StatusIndicator(
                                    icon = Icons.Default.NotificationsActive,
                                    label = "Alerts",
                                    isActive = (dashboardAnalytics?.activeIncidents ?: 0) > 0
                                )
                                StatusIndicator(
                                    icon = Icons.Default.Wifi,
                                    label = "Network",
                                    isActive = true
                                )
                                StatusIndicator(
                                    icon = Icons.Default.CloudDone,
                                    label = "Sync",
                                    isActive = true
                                )
                            }
                        }
                    }
                }
                
                Spacer(modifier = Modifier.height(20.dp))
                
                // Alerts card - blue with 0.9 alpha
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp)
                        .clickable { onNavigateToIncidents() },
                    colors = CardDefaults.cardColors(
                        containerColor = OceanColors.DashboardBlue.copy(alpha = 0.9f)
                    ),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(77.dp),
                        contentAlignment = Alignment.CenterStart
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 24.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Default.Warning,
                                contentDescription = null,
                                modifier = Modifier.size(28.dp),
                                tint = OceanColors.Primary
                            )
                            Spacer(modifier = Modifier.width(16.dp))
                            Text(
                                text = "Alerts",
                                style = MaterialTheme.typography.titleMedium,
                                color = MaterialTheme.colorScheme.onSecondary
                            )
                            Spacer(modifier = Modifier.weight(1f))
                            Icon(
                                Icons.Default.ChevronRight,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onSecondary.copy(alpha = 0.7f)
                            )
                        }
                    }
                }
                
                Spacer(modifier = Modifier.height(20.dp))
                
                // Weather Forecast card - blue with 0.9 alpha, shows live data
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp)
                        .clickable { onNavigateToWeather() },
                    colors = CardDefaults.cardColors(
                        containerColor = OceanColors.DashboardBlue.copy(alpha = 0.9f)
                    ),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 24.dp, vertical = 16.dp),
                        contentAlignment = Alignment.CenterStart
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Default.Cloud,
                                contentDescription = null,
                                modifier = Modifier.size(28.dp),
                                tint = OceanColors.Primary
                            )
                            Spacer(modifier = Modifier.width(16.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = "Weather Forecast",
                                    style = MaterialTheme.typography.titleMedium,
                                    color = MaterialTheme.colorScheme.onSecondary
                                )
                                if (currentWeather != null) {
                                    Text(
                                        text = "${currentWeather!!.current.tempC.toInt()}°C • ${currentWeather!!.current.condition.text}",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSecondary.copy(alpha = 0.8f)
                                    )
                                }
                            }
                            if (currentWeather != null) {
                                Text(
                                    text = "${currentWeather!!.current.tempC.toInt()}°",
                                    style = MaterialTheme.typography.headlineSmall,
                                    color = OceanColors.Primary,
                                    fontWeight = FontWeight.Bold
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                            }
                            Icon(
                                Icons.Default.ChevronRight,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onSecondary.copy(alpha = 0.7f)
                            )
                        }
                    }
                }
                
                Spacer(modifier = Modifier.height(24.dp))
                
                // Quick Actions based on role
                QuickActionsSection(
                    userRole = userRole,
                    onNavigateToMap = onNavigateToMap,
                    onNavigateToReport = onNavigateToReport,
                    onNavigateToMyReports = onNavigateToMyReports,
                    onNavigateToIncidents = onNavigateToIncidents,
                    onNavigateToAnalytics = onNavigateToAnalytics,
                    onNavigateToAdmin = onNavigateToAdmin
                )
                
                Spacer(modifier = Modifier.height(24.dp))
                
                // How it Works
                HowItWorksSection()
                
                Spacer(modifier = Modifier.height(24.dp))
            }
        }
    }
}

@Composable
private fun DashboardStatItem(
    value: String,
    label: String,
    color: Color
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = value,
            style = MaterialTheme.typography.headlineMedium,
            color = color
        )
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = Color(0xFF666666)
        )
    }
}

@Composable
private fun QuickActionsSection(
    userRole: UserRole,
    onNavigateToMap: () -> Unit,
    onNavigateToReport: () -> Unit,
    onNavigateToMyReports: () -> Unit,
    onNavigateToIncidents: () -> Unit,
    onNavigateToAnalytics: () -> Unit,
    onNavigateToAdmin: () -> Unit
) {
    Column(
        modifier = Modifier.padding(horizontal = 16.dp)
    ) {
        Text(
            text = "Quick Actions",
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        val actions = buildList {
            add(QuickAction("Live Map", Icons.Default.Map, OceanColors.Secondary, onNavigateToMap))
            add(QuickAction("Report Hazard", Icons.Default.Warning, OceanColors.Error, onNavigateToReport))
            add(QuickAction("My Reports", Icons.Default.History, OceanColors.Purple, onNavigateToMyReports))
            
            if (userRole in listOf(UserRole.ADMIN, UserRole.RESCUE_TEAM, UserRole.AUTHORITY)) {
                add(QuickAction("All Incidents", Icons.Default.List, OceanColors.Orange, onNavigateToIncidents))
                add(QuickAction("Analytics", Icons.Default.Analytics, OceanColors.Green, onNavigateToAnalytics))
            }
            
            if (userRole == UserRole.ADMIN) {
                add(QuickAction("Admin Panel", Icons.Default.AdminPanelSettings, OceanColors.Error, onNavigateToAdmin))
            }
        }
        
        LazyRow(
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(actions) { action ->
                QuickActionCard(
                    title = action.title,
                    icon = action.icon,
                    color = action.color,
                    onClick = action.onClick
                )
            }
        }
    }
}

@Composable
private fun QuickActionCard(
    title: String,
    icon: ImageVector,
    color: androidx.compose.ui.graphics.Color,
    onClick: () -> Unit
) {
    Card(
        onClick = onClick,
        modifier = Modifier.width(120.dp),
        colors = CardDefaults.cardColors(
            containerColor = color.copy(alpha = 0.1f)
        )
    ) {
        Column(
            modifier = Modifier
                .padding(16.dp)
                .fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = color,
                modifier = Modifier.size(32.dp)
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = title,
                style = MaterialTheme.typography.labelMedium,
                color = color,
                textAlign = TextAlign.Center,
                fontWeight = FontWeight.Medium
            )
        }
    }
}

private data class QuickAction(
    val title: String,
    val icon: ImageVector,
    val color: androidx.compose.ui.graphics.Color,
    val onClick: () -> Unit
)

@Composable
private fun HowItWorksSection() {
    Column(
        modifier = Modifier.padding(horizontal = 16.dp)
    ) {
        Text(
            text = "How It Works",
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        val steps = listOf(
            HowItWorksStep(
                number = "1",
                title = "Spot a Hazard",
                description = "See pollution, debris, or marine life in distress?",
                icon = Icons.Default.Visibility,
                color = OceanColors.Purple
            ),
            HowItWorksStep(
                number = "2",
                title = "Report It",
                description = "Take a photo and share the location details",
                icon = Icons.Default.CameraAlt,
                color = OceanColors.Orange
            ),
            HowItWorksStep(
                number = "3",
                title = "Track Response",
                description = "Watch as authorities respond and resolve the issue",
                icon = Icons.Default.TrackChanges,
                color = OceanColors.Green
            )
        )
        
        steps.forEach { step ->
            HowItWorksCard(step)
            if (step != steps.last()) {
                Spacer(modifier = Modifier.height(12.dp))
            }
        }
    }
}

@Composable
private fun HowItWorksCard(step: HowItWorksStep) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
        )
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Step number
            Surface(
                shape = MaterialTheme.shapes.medium,
                color = step.color,
                modifier = Modifier.size(48.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Text(
                        text = step.number,
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onPrimary
                    )
                }
            }
            
            Spacer(modifier = Modifier.width(16.dp))
            
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = step.title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    text = step.description,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            Icon(
                imageVector = step.icon,
                contentDescription = null,
                tint = step.color,
                modifier = Modifier.size(28.dp)
            )
        }
    }
}

private data class HowItWorksStep(
    val number: String,
    val title: String,
    val description: String,
    val icon: ImageVector,
    val color: androidx.compose.ui.graphics.Color
)

/**
 * Pulsing LIVE badge with animated red dot
 */
@Composable
private fun LivePulseBadge() {
    val infiniteTransition = rememberInfiniteTransition(label = "pulse")
    val pulseAlpha by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 0.3f,
        animationSpec = infiniteRepeatable(
            animation = tween(800, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulseAlpha"
    )

    Surface(
        color = OceanColors.LiveFeedRed.copy(alpha = 0.2f),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Blinking red dot — fixed size, alpha blink only
            Box(
                modifier = Modifier
                    .size(10.dp)
                    .alpha(pulseAlpha)
                    .background(OceanColors.LiveFeedRed, CircleShape)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = "LIVE",
                style = MaterialTheme.typography.labelMedium,
                color = OceanColors.LiveFeedRed,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

/**
 * Status indicator chip — icons only, green dot when active, gray when inactive
 */
@Composable
private fun StatusIndicator(
    icon: ImageVector,
    label: String,
    isActive: Boolean
) {
    val dotColor = if (isActive) OceanColors.Success else OceanColors.Gray
    
    Box(contentAlignment = Alignment.TopEnd) {
        Icon(
            imageVector = icon,
            contentDescription = label,
            modifier = Modifier.size(22.dp),
            tint = Color(0xFF555555)
        )
        // Tiny status dot
        Box(
            modifier = Modifier
                .size(8.dp)
                .border(1.dp, Color.White, CircleShape)
                .background(dotColor, CircleShape)
        )
    }
}
