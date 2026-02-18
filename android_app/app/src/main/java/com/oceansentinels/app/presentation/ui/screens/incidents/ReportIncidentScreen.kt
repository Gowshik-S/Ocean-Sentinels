package com.oceansentinels.app.presentation.ui.screens.incidents

import android.Manifest
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.google.android.gms.location.LocationServices
import com.oceansentinels.app.domain.model.*
import com.oceansentinels.app.presentation.ui.components.*
import com.oceansentinels.app.presentation.ui.theme.OceanColors
import com.oceansentinels.app.presentation.viewmodel.CreateIncidentState
import com.oceansentinels.app.presentation.viewmodel.IncidentViewModel

/**
 * Report incident screen with form
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReportIncidentScreen(
    onNavigateBack: () -> Unit,
    onIncidentCreated: (Int) -> Unit,
    viewModel: IncidentViewModel = hiltViewModel()
) {
    val createState by viewModel.createIncidentState.collectAsState()
    val context = LocalContext.current
    
    // Form state
    var description by remember { mutableStateOf("") }
    var selectedHazardType by remember { mutableStateOf<HazardType?>(null) }
    var selectedUrgency by remember { mutableStateOf(UrgencyLevel.MEDIUM) }
    var latitude by remember { mutableStateOf("") }
    var longitude by remember { mutableStateOf("") }
    var locationDescription by remember { mutableStateOf("") }
    var imageUri by remember { mutableStateOf<Uri?>(null) }
    var isGettingLocation by remember { mutableStateOf(false) }
    var locationError by remember { mutableStateOf<String?>(null) }
    var hazardTypeExpanded by remember { mutableStateOf(false) }
    var urgencyExpanded by remember { mutableStateOf(false) }

    val fusedLocationClient = remember {
        LocationServices.getFusedLocationProviderClient(context)
    }

    // Function to fetch GPS location with high accuracy
    fun fetchGpsLocation() {
        isGettingLocation = true
        locationError = null
        try {
            val cancellationToken = com.google.android.gms.tasks.CancellationTokenSource()
            fusedLocationClient.getCurrentLocation(
                com.google.android.gms.location.Priority.PRIORITY_HIGH_ACCURACY,
                cancellationToken.token
            ).addOnSuccessListener { location ->
                if (location != null) {
                    latitude = "%.6f".format(location.latitude)
                    longitude = "%.6f".format(location.longitude)
                    locationError = null
                } else {
                    // Fallback to lastLocation
                    fusedLocationClient.lastLocation.addOnSuccessListener { lastLoc ->
                        if (lastLoc != null) {
                            latitude = "%.6f".format(lastLoc.latitude)
                            longitude = "%.6f".format(lastLoc.longitude)
                            locationError = null
                        } else {
                            locationError = "Could not get location. Ensure GPS is enabled."
                        }
                        isGettingLocation = false
                    }
                    return@addOnSuccessListener
                }
                isGettingLocation = false
            }.addOnFailureListener { e ->
                locationError = "Location error: ${e.localizedMessage}"
                isGettingLocation = false
            }
        } catch (e: SecurityException) {
            locationError = "Location permission denied"
            isGettingLocation = false
        }
    }
    
    // Location permission
    val locationPermissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            fetchGpsLocation()
        }
    }

    // Auto-detect GPS on screen load
    LaunchedEffect(Unit) {
        if (latitude.isBlank() && longitude.isBlank()) {
            // Request permission which auto-fetches on grant
            locationPermissionLauncher.launch(Manifest.permission.ACCESS_FINE_LOCATION)
        }
    }
    
    // Camera launcher
    val cameraLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.TakePicturePreview()
    ) { bitmap ->
        // Handle captured image
        // In production, save bitmap to file and get URI
    }
    
    // Gallery launcher
    val galleryLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri ->
        imageUri = uri
    }
    
    // Handle success
    LaunchedEffect(createState) {
        if (createState is CreateIncidentState.Success) {
            val incident = (createState as CreateIncidentState.Success).incident
            onIncidentCreated(incident.id)
            viewModel.resetCreateState()
        }
    }
    
    // Track mesh fallback success (show snackbar, then navigate back)
    var meshFallbackMessage by remember { mutableStateOf<String?>(null) }
    LaunchedEffect(createState) {
        if (createState is CreateIncidentState.MeshFallbackSuccess) {
            meshFallbackMessage = (createState as CreateIncidentState.MeshFallbackSuccess).message
            viewModel.resetCreateState()
        }
    }
    
    val scrollState = rememberScrollState()
    
    val isFormValid = description.isNotBlank() && 
                      selectedHazardType != null &&
                      latitude.isNotBlank() && 
                      longitude.isNotBlank()
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Report Hazard") },
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
                .padding(horizontal = 16.dp)
                .verticalScroll(scrollState)
        ) {
            Spacer(modifier = Modifier.height(16.dp))
            
            // Info banner
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = OceanColors.Info.copy(alpha = 0.1f)
                )
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Info,
                        contentDescription = null,
                        tint = OceanColors.Info
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        text = "Your report helps protect our marine environment. Please provide accurate details.",
                        style = MaterialTheme.typography.bodySmall,
                        color = OceanColors.Info
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Description
            OutlinedTextField(
                value = description,
                onValueChange = { description = it },
                label = { Text("Description *") },
                placeholder = { Text("Detailed description of what you observed...") },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(120.dp),
                shape = MaterialTheme.shapes.medium,
                maxLines = 5
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Hazard Type Dropdown
            ExposedDropdownMenuBox(
                expanded = hazardTypeExpanded,
                onExpandedChange = { hazardTypeExpanded = !hazardTypeExpanded }
            ) {
                OutlinedTextField(
                    value = selectedHazardType?.name?.replace("_", " ")?.lowercase()?.replaceFirstChar { it.uppercase() } ?: "",
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("Hazard Type *") },
                    leadingIcon = { Icon(Icons.Default.Category, contentDescription = null) },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = hazardTypeExpanded) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor(),
                    shape = MaterialTheme.shapes.medium
                )
                
                ExposedDropdownMenu(
                    expanded = hazardTypeExpanded,
                    onDismissRequest = { hazardTypeExpanded = false }
                ) {
                    HazardType.entries.forEach { type ->
                        val (color, text, icon) = getHazardTypeInfo(type)
                        DropdownMenuItem(
                            text = {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(20.dp))
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(text)
                                }
                            },
                            onClick = {
                                selectedHazardType = type
                                hazardTypeExpanded = false
                            }
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Urgency Level Dropdown
            ExposedDropdownMenuBox(
                expanded = urgencyExpanded,
                onExpandedChange = { urgencyExpanded = !urgencyExpanded }
            ) {
                OutlinedTextField(
                    value = selectedUrgency.name.lowercase().replaceFirstChar { it.uppercase() },
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("Urgency Level") },
                    leadingIcon = { Icon(Icons.Default.PriorityHigh, contentDescription = null) },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = urgencyExpanded) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor(),
                    shape = MaterialTheme.shapes.medium
                )
                
                ExposedDropdownMenu(
                    expanded = urgencyExpanded,
                    onDismissRequest = { urgencyExpanded = false }
                ) {
                    UrgencyLevel.entries.forEach { level ->
                        val color = when (level) {
                            UrgencyLevel.LOW -> OceanColors.Success
                            UrgencyLevel.MEDIUM -> OceanColors.Warning
                            UrgencyLevel.HIGH -> OceanColors.Orange
                            UrgencyLevel.CRITICAL -> OceanColors.Danger
                        }
                        DropdownMenuItem(
                            text = {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Surface(
                                        shape = MaterialTheme.shapes.small,
                                        color = color,
                                        modifier = Modifier.size(12.dp)
                                    ) {}
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(level.name.lowercase().replaceFirstChar { it.uppercase() })
                                }
                            },
                            onClick = {
                                selectedUrgency = level
                                urgencyExpanded = false
                            }
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Location Section
            Text(
                text = "Location",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Auto-detected GPS Location Card
            val hasLocation = latitude.isNotBlank() && longitude.isNotBlank()
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = when {
                        isGettingLocation -> MaterialTheme.colorScheme.surfaceVariant
                        hasLocation -> OceanColors.Success.copy(alpha = 0.08f)
                        else -> OceanColors.Warning.copy(alpha = 0.08f)
                    }
                ),
                border = BorderStroke(
                    1.dp,
                    when {
                        isGettingLocation -> MaterialTheme.colorScheme.outline
                        hasLocation -> OceanColors.Success
                        else -> OceanColors.Warning
                    }
                )
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = when {
                            isGettingLocation -> Icons.Default.GpsNotFixed
                            hasLocation -> Icons.Default.GpsFixed
                            else -> Icons.Default.GpsOff
                        },
                        contentDescription = null,
                        tint = when {
                            hasLocation -> OceanColors.Success
                            isGettingLocation -> MaterialTheme.colorScheme.primary
                            else -> OceanColors.Warning
                        },
                        modifier = Modifier.size(28.dp)
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = when {
                                isGettingLocation -> "Detecting GPS location..."
                                hasLocation -> "Location detected"
                                else -> "Location unavailable"
                            },
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.SemiBold
                        )
                        if (hasLocation) {
                            Text(
                                text = "$latitude, $longitude",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        if (locationError != null) {
                            Text(
                                text = locationError!!,
                                style = MaterialTheme.typography.bodySmall,
                                color = OceanColors.Danger
                            )
                        }
                    }
                    if (isGettingLocation) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(24.dp),
                            strokeWidth = 2.dp
                        )
                    } else {
                        IconButton(onClick = {
                            locationPermissionLauncher.launch(Manifest.permission.ACCESS_FINE_LOCATION)
                        }) {
                            Icon(
                                Icons.Default.Refresh,
                                contentDescription = "Refresh location",
                                tint = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            OutlinedTextField(
                value = locationDescription,
                onValueChange = { locationDescription = it },
                label = { Text("Location Description (Optional)") },
                placeholder = { Text("e.g., Near the pier, 100m from shore") },
                modifier = Modifier.fillMaxWidth(),
                shape = MaterialTheme.shapes.medium
            )
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Photo Section
            Text(
                text = "Photo Evidence (Optional)",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedButton(
                    onClick = { cameraLauncher.launch(null) },
                    modifier = Modifier.weight(1f)
                ) {
                    Icon(Icons.Default.CameraAlt, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Camera")
                }
                
                OutlinedButton(
                    onClick = { galleryLauncher.launch("image/*") },
                    modifier = Modifier.weight(1f)
                ) {
                    Icon(Icons.Default.PhotoLibrary, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Gallery")
                }
            }
            
            if (imageUri != null) {
                Spacer(modifier = Modifier.height(12.dp))
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    border = BorderStroke(1.dp, OceanColors.Success)
                ) {
                    Row(
                        modifier = Modifier.padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Default.CheckCircle, contentDescription = null, tint = OceanColors.Success)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Photo attached", color = OceanColors.Success)
                        Spacer(modifier = Modifier.weight(1f))
                        IconButton(onClick = { imageUri = null }) {
                            Icon(Icons.Default.Close, contentDescription = "Remove")
                        }
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Error message
            if (createState is CreateIncidentState.Error) {
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = OceanColors.Danger.copy(alpha = 0.1f)
                    ),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier.padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Default.Error, contentDescription = null, tint = OceanColors.Danger)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = (createState as CreateIncidentState.Error).message,
                            color = OceanColors.Danger,
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }
            }
            
            // Mesh fallback success banner
            if (meshFallbackMessage != null) {
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = OceanColors.Info.copy(alpha = 0.15f)
                    ),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier.padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Default.Bluetooth, contentDescription = null, tint = OceanColors.Info)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = meshFallbackMessage!!,
                            color = OceanColors.Info,
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Submit Button
            OceanPrimaryButton(
                text = "Submit Report",
                onClick = {
                    viewModel.createIncident(
                        CreateIncidentRequest(
                            hazardType = selectedHazardType!!,
                            location = locationDescription.ifBlank { "$latitude, $longitude" },
                            latitude = latitude.toDoubleOrNull(),
                            longitude = longitude.toDoubleOrNull(),
                            description = description,
                            urgency = selectedUrgency,
                            contactInfo = null,
                            photoUrl = imageUri?.toString()
                        )
                    )
                },
                isLoading = createState is CreateIncidentState.Loading,
                enabled = isFormValid,
                modifier = Modifier.fillMaxWidth(),
                icon = Icons.Default.Send
            )
            
            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}
