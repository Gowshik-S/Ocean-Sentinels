package com.oceansentinels.app.presentation.ui.screens.map

import android.Manifest
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.isGranted
import com.google.accompanist.permissions.rememberPermissionState
import com.google.android.gms.location.LocationServices
import com.mapbox.geojson.Point
import com.mapbox.maps.CameraOptions
import com.mapbox.maps.MapView
import com.mapbox.maps.Style
import com.mapbox.maps.plugin.animation.flyTo
import com.mapbox.maps.plugin.annotation.annotations
import com.mapbox.maps.plugin.annotation.generated.CircleAnnotationManager
import com.mapbox.maps.plugin.annotation.generated.CircleAnnotationOptions
import com.mapbox.maps.plugin.annotation.generated.createCircleAnnotationManager
import com.mapbox.maps.plugin.locationcomponent.location
import com.oceansentinels.app.domain.model.*
import com.oceansentinels.app.presentation.ui.components.*
import com.oceansentinels.app.presentation.ui.theme.OceanColors
import com.oceansentinels.app.presentation.viewmodel.IncidentViewModel

/**
 * Map screen showing all incidents using Mapbox
 */
@OptIn(ExperimentalMaterial3Api::class, ExperimentalPermissionsApi::class)
@Composable
fun MapScreen(
    onNavigateBack: () -> Unit,
    onNavigateToDetail: (Int) -> Unit,
    onNavigateToReport: () -> Unit,
    initialLat: Double? = null,
    initialLng: Double? = null,
    viewModel: IncidentViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    val incidents by viewModel.incidents.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    
    // Default to India coastal region if no initial position
    val defaultLat = initialLat ?: 19.0760
    val defaultLng = initialLng ?: 72.8777
    val defaultZoom = if (initialLat != null) 12.0 else 5.0
    
    val locationPermissionState = rememberPermissionState(Manifest.permission.ACCESS_FINE_LOCATION)
    
    var showIncidentSheet by remember { mutableStateOf(false) }
    var selectedMarkerIncident by remember { mutableStateOf<Incident?>(null) }
    var mapView by remember { mutableStateOf<MapView?>(null) }
    
    // FusedLocationClient for getting user location
    val fusedLocationClient = remember { LocationServices.getFusedLocationProviderClient(context) }
    
    // Load incidents
    LaunchedEffect(Unit) {
        viewModel.loadIncidents(IncidentFilters(size = 100))
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Live Incident Map") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = { viewModel.loadIncidents() }) {
                        Icon(Icons.Default.Refresh, contentDescription = "Refresh")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = OceanColors.Primary,
                    titleContentColor = Color.White,
                    navigationIconContentColor = Color.White,
                    actionIconContentColor = Color.White
                )
            )
        },
        floatingActionButton = {
            Column {
                // My location button
                if (locationPermissionState.status.isGranted) {
                    SmallFloatingActionButton(
                        onClick = {
                            // Center on user location using FusedLocationClient
                            try {
                                fusedLocationClient.lastLocation.addOnSuccessListener { location ->
                                    location?.let {
                                        mapView?.mapboxMap?.flyTo(
                                            CameraOptions.Builder()
                                                .center(Point.fromLngLat(it.longitude, it.latitude))
                                                .zoom(14.0)
                                                .build()
                                        )
                                    }
                                }
                            } catch (e: SecurityException) {
                                // Permission not granted
                            }
                        },
                        containerColor = MaterialTheme.colorScheme.surface
                    ) {
                        Icon(Icons.Default.MyLocation, contentDescription = "My Location")
                    }
                    
                    Spacer(modifier = Modifier.height(8.dp))
                }
                
                // Report FAB
                ExtendedFloatingActionButton(
                    onClick = onNavigateToReport,
                    containerColor = OceanColors.Primary,
                    contentColor = Color.White
                ) {
                    Icon(Icons.Default.Add, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Report")
                }
            }
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Mapbox Map
            MapboxMapView(
                modifier = Modifier.fillMaxSize(),
                initialLat = defaultLat,
                initialLng = defaultLng,
                initialZoom = defaultZoom,
                incidents = incidents,
                onMapViewCreated = { mapView = it },
                onIncidentClick = { incident ->
                    selectedMarkerIncident = incident
                    showIncidentSheet = true
                },
                showUserLocation = locationPermissionState.status.isGranted
            )
            
            // Loading indicator
            if (isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier
                        .align(Alignment.TopCenter)
                        .padding(16.dp),
                    color = OceanColors.Primary
                )
            }
            
            // Legend
            Card(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(8.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.95f)
                ),
                elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
            ) {
                Column(
                    modifier = Modifier.padding(12.dp)
                ) {
                    Text(
                        text = "Legend",
                        style = MaterialTheme.typography.labelMedium,
                        color = OceanColors.Primary
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    LegendItem(color = OceanColors.Warning, label = "Pending")
                    LegendItem(color = OceanColors.Info, label = "Verified")
                    LegendItem(color = OceanColors.Primary, label = "In Progress")
                    LegendItem(color = OceanColors.Success, label = "Resolved")
                }
            }
            
            // Incident count
            Card(
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .padding(8.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.95f)
                ),
                elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Place,
                        contentDescription = null,
                        tint = OceanColors.Primary,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "${incidents.size} incidents",
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
        }
    }
    
    // Incident detail bottom sheet
    if (showIncidentSheet && selectedMarkerIncident != null) {
        IncidentBottomSheet(
            incident = selectedMarkerIncident!!,
            onDismiss = { 
                showIncidentSheet = false
                selectedMarkerIncident = null
            },
            onViewDetails = {
                onNavigateToDetail(selectedMarkerIncident!!.id)
                showIncidentSheet = false
            }
        )
    }
}

@Composable
private fun MapboxMapView(
    modifier: Modifier = Modifier,
    initialLat: Double,
    initialLng: Double,
    initialZoom: Double,
    incidents: List<Incident>,
    onMapViewCreated: (MapView) -> Unit,
    onIncidentClick: (Incident) -> Unit,
    showUserLocation: Boolean
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val incidentMap = remember { mutableMapOf<String, Incident>() }
    var circleAnnotationManager by remember { mutableStateOf<CircleAnnotationManager?>(null) }
    
    // Create MapView once and remember it
    val mapView = remember {
        MapView(context).apply {
            mapboxMap.loadStyle(Style.MAPBOX_STREETS) { style ->
                // Set initial camera position
                mapboxMap.setCamera(
                    CameraOptions.Builder()
                        .center(Point.fromLngLat(initialLng, initialLat))
                        .zoom(initialZoom)
                        .build()
                )
                
                // Enable location component if permission granted
                if (showUserLocation) {
                    location.updateSettings {
                        enabled = true
                        pulsingEnabled = true
                    }
                }
                
                // Create annotation manager once
                circleAnnotationManager = annotations.createCircleAnnotationManager()
            }
        }
    }
    
    // Handle lifecycle
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_START -> mapView.onStart()
                Lifecycle.Event.ON_STOP -> mapView.onStop()
                Lifecycle.Event.ON_DESTROY -> mapView.onDestroy()
                else -> {}
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onMapViewCreated(mapView)
        
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
        }
    }
    
    // Update markers when incidents change
    LaunchedEffect(incidents, circleAnnotationManager) {
        circleAnnotationManager?.let { manager ->
            // Clear existing annotations
            manager.deleteAll()
            incidentMap.clear()
            
            // Add markers for each incident
            incidents.filter { it.latitude != null && it.longitude != null }.forEach { incident ->
                val color = when (incident.status) {
                    IncidentStatus.PENDING -> "#FFC107"      // Warning Yellow
                    IncidentStatus.VERIFIED -> "#17A2B8"     // Info Blue
                    IncidentStatus.IN_PROGRESS -> "#005A9C"  // Primary Blue
                    IncidentStatus.RESOLVED -> "#28A745"     // Success Green
                    else -> "#DC3545"                        // Error Red
                }
                
                val circleAnnotationOptions = CircleAnnotationOptions()
                    .withPoint(Point.fromLngLat(incident.longitude!!, incident.latitude!!))
                    .withCircleRadius(12.0)
                    .withCircleColor(color)
                    .withCircleStrokeWidth(2.0)
                    .withCircleStrokeColor("#FFFFFF")
                
                val annotation = manager.create(circleAnnotationOptions)
                incidentMap[annotation.id] = incident
            }
            
            // Handle click on annotations
            manager.addClickListener { annotation ->
                incidentMap[annotation.id]?.let { incident ->
                    onIncidentClick(incident)
                }
                true
            }
        }
    }
    
    AndroidView(
        modifier = modifier,
        factory = { mapView }
    )
}

@Composable
private fun LegendItem(
    color: Color,
    label: String
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.padding(vertical = 2.dp)
    ) {
        Box(
            modifier = Modifier
                .size(12.dp)
                .clip(CircleShape)
                .background(color)
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun IncidentBottomSheet(
    incident: Incident,
    onDismiss: () -> Unit,
    onViewDetails: () -> Unit
) {
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
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = incident.hazardType.displayName,
                        style = MaterialTheme.typography.titleLarge,
                        color = OceanColors.Primary
                    )
                    Text(
                        text = incident.referenceId,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                StatusBadge(status = incident.status)
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Badges
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                HazardTypeBadge(hazardType = incident.hazardType)
                UrgencyBadge(urgency = incident.urgency)
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Description
            Text(
                text = incident.description,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 3
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Location
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.LocationOn,
                    contentDescription = null,
                    tint = OceanColors.Primary,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = incident.location.ifBlank { "%.4f, %.4f".format(incident.latitude ?: 0.0, incident.longitude ?: 0.0) },
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // View details button
            OceanPrimaryButton(
                text = "View Full Details",
                onClick = onViewDetails,
                modifier = Modifier.fillMaxWidth(),
                icon = Icons.Default.OpenInNew
            )
        }
    }
}
