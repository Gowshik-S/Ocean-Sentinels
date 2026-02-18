package com.oceansentinels.app.presentation

import android.Manifest
import android.content.IntentSender
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import androidx.compose.animation.*
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.navigation.compose.rememberNavController
import com.google.android.gms.common.api.ResolvableApiException
import com.google.android.gms.location.*
import com.oceansentinels.app.presentation.navigation.OceanNavHost
import com.oceansentinels.app.presentation.ui.theme.OceanColors
import com.oceansentinels.app.presentation.ui.theme.OceanSentinelsTheme
import com.oceansentinels.app.presentation.viewmodel.ThemeViewModel
import dagger.hilt.android.AndroidEntryPoint

/**
 * Main Activity for Ocean Sentinels Android App.
 * Requires location permission before allowing app access.
 * Prompts user to enable GPS if location services are off.
 */
@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    
    private val themeViewModel: ThemeViewModel by viewModels()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        // Install splash screen
        installSplashScreen()
        
        super.onCreate(savedInstanceState)
        
        // Enable edge-to-edge display
        enableEdgeToEdge()
        
        setContent {
            val isDarkMode by themeViewModel.isDarkMode.collectAsState()
            
            OceanSentinelsTheme(darkTheme = isDarkMode) {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    LocationPermissionGate()
                }
            }
        }
    }
}

/**
 * Gate composable that blocks app access until location permission is granted
 * and GPS/location services are enabled.
 */
@Composable
private fun LocationPermissionGate() {
    val context = LocalContext.current

    // Permission state
    var locationGranted by remember { mutableStateOf(false) }
    var permissionDeniedPermanently by remember { mutableStateOf(false) }
    var permissionRequested by remember { mutableStateOf(false) }

    // GPS enabled state
    var gpsEnabled by remember { mutableStateOf(false) }
    var gpsCheckDone by remember { mutableStateOf(false) }

    // Permission launcher
    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        permissionRequested = true
        val fineGranted = permissions[Manifest.permission.ACCESS_FINE_LOCATION] ?: false
        val coarseGranted = permissions[Manifest.permission.ACCESS_COARSE_LOCATION] ?: false
        locationGranted = fineGranted || coarseGranted
        if (!locationGranted) {
            permissionDeniedPermanently = true
        }
    }

    // GPS enable resolution launcher
    val gpsResolutionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.StartIntentSenderForResult()
    ) { result ->
        gpsEnabled = result.resultCode == android.app.Activity.RESULT_OK
        gpsCheckDone = true
    }

    // Function to check and prompt GPS enable
    fun checkAndEnableGps() {
        val locationRequest = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY, 10000L
        ).build()

        val settingsRequest = LocationSettingsRequest.Builder()
            .addLocationRequest(locationRequest)
            .setAlwaysShow(true) // Forces the dialog even if settings are partially available
            .build()

        val settingsClient = LocationServices.getSettingsClient(context)
        settingsClient.checkLocationSettings(settingsRequest)
            .addOnSuccessListener {
                // GPS is already enabled
                gpsEnabled = true
                gpsCheckDone = true
            }
            .addOnFailureListener { exception ->
                if (exception is ResolvableApiException) {
                    // GPS is off → show system dialog to enable
                    try {
                        val intentSenderRequest = IntentSenderRequest.Builder(exception.resolution).build()
                        gpsResolutionLauncher.launch(intentSenderRequest)
                    } catch (sendEx: IntentSender.SendIntentException) {
                        Log.e("LocationGate", "Error launching GPS resolution", sendEx)
                        gpsCheckDone = true
                    }
                } else {
                    gpsCheckDone = true
                }
            }
    }

    // Auto-request permission on first launch
    LaunchedEffect(Unit) {
        // Check if already granted
        val hasPermission = context.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) ==
                android.content.pm.PackageManager.PERMISSION_GRANTED
        if (hasPermission) {
            locationGranted = true
        } else {
            permissionLauncher.launch(
                arrayOf(
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                )
            )
        }
    }

    // After permission is granted, check GPS
    LaunchedEffect(locationGranted) {
        if (locationGranted) {
            checkAndEnableGps()
        }
    }

    // Decide what to show
    when {
        // Permission granted AND GPS enabled → show app
        locationGranted && (gpsEnabled || gpsCheckDone) -> {
            val navController = rememberNavController()
            OceanNavHost(navController = navController)
        }
        // Permission granted but GPS check still in progress
        locationGranted && !gpsCheckDone -> {
            PermissionGateScreen(
                icon = Icons.Default.GpsNotFixed,
                title = "Checking Location Services...",
                subtitle = "Verifying GPS is enabled",
                showProgress = true
            )
        }
        // Permission denied permanently
        permissionDeniedPermanently -> {
            PermissionGateScreen(
                icon = Icons.Default.LocationOff,
                title = "Location Permission Required",
                subtitle = "Ocean Sentinels needs location access to detect hazard positions and enable mesh networking.\n\nPlease grant location permission in Settings.",
                buttonText = "Open Settings",
                onButtonClick = {
                    val intent = android.content.Intent(
                        android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        android.net.Uri.fromParts("package", context.packageName, null)
                    )
                    context.startActivity(intent)
                    // Reset so we re-check when user returns
                    permissionDeniedPermanently = false
                    permissionRequested = false
                },
                secondaryButtonText = "Try Again",
                onSecondaryClick = {
                    permissionDeniedPermanently = false
                    permissionLauncher.launch(
                        arrayOf(
                            Manifest.permission.ACCESS_FINE_LOCATION,
                            Manifest.permission.ACCESS_COARSE_LOCATION
                        )
                    )
                }
            )
        }
        // Waiting for initial permission dialog
        else -> {
            PermissionGateScreen(
                icon = Icons.Default.MyLocation,
                title = "Location Access Needed",
                subtitle = "Ocean Sentinels requires your location to accurately report hazard positions and enable BLE mesh networking.",
                showProgress = !permissionRequested,
                buttonText = if (permissionRequested) "Grant Permission" else null,
                onButtonClick = {
                    permissionLauncher.launch(
                        arrayOf(
                            Manifest.permission.ACCESS_FINE_LOCATION,
                            Manifest.permission.ACCESS_COARSE_LOCATION
                        )
                    )
                }
            )
        }
    }
}

/**
 * Full-screen permission gate UI
 */
@Composable
private fun PermissionGateScreen(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    subtitle: String,
    showProgress: Boolean = false,
    buttonText: String? = null,
    onButtonClick: (() -> Unit)? = null,
    secondaryButtonText: String? = null,
    onSecondaryClick: (() -> Unit)? = null
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(32.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            // Icon
            Box(
                modifier = Modifier
                    .size(96.dp)
                    .clip(CircleShape)
                    .background(OceanColors.Primary.copy(alpha = 0.1f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    modifier = Modifier.size(48.dp),
                    tint = OceanColors.Primary
                )
            }

            // Title
            Text(
                text = title,
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center
            )

            // Subtitle
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodyMedium,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            if (showProgress) {
                CircularProgressIndicator(
                    modifier = Modifier.size(32.dp),
                    color = OceanColors.Primary,
                    strokeWidth = 3.dp
                )
            }

            // Primary button
            if (buttonText != null && onButtonClick != null) {
                Button(
                    onClick = onButtonClick,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = OceanColors.Primary
                    ),
                    shape = MaterialTheme.shapes.medium
                ) {
                    Icon(Icons.Default.MyLocation, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(buttonText, fontWeight = FontWeight.SemiBold)
                }
            }

            // Secondary button
            if (secondaryButtonText != null && onSecondaryClick != null) {
                OutlinedButton(
                    onClick = onSecondaryClick,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp),
                    shape = MaterialTheme.shapes.medium
                ) {
                    Text(secondaryButtonText)
                }
            }
        }
    }
}
