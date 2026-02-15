package com.oceansentinels.app.presentation.ui.screens.incidents

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
import coil.compose.AsyncImage
import com.oceansentinels.app.domain.model.IncidentStatus
import com.oceansentinels.app.domain.model.UserRole
import com.oceansentinels.app.domain.model.UserSession
import com.oceansentinels.app.presentation.ui.components.*
import com.oceansentinels.app.presentation.ui.theme.OceanColors
import com.oceansentinels.app.presentation.viewmodel.AuthViewModel
import com.oceansentinels.app.presentation.viewmodel.IncidentViewModel
import java.text.SimpleDateFormat
import java.util.*

/**
 * Incident detail screen
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun IncidentDetailScreen(
    incidentId: Int,
    onNavigateBack: () -> Unit,
    onNavigateToMap: (Double, Double) -> Unit,
    incidentViewModel: IncidentViewModel = hiltViewModel(),
    authViewModel: AuthViewModel = hiltViewModel()
) {
    val incident by incidentViewModel.selectedIncident.collectAsState()
    val isLoading by incidentViewModel.isLoading.collectAsState()
    val error by incidentViewModel.error.collectAsState()
    val userSession by authViewModel.userSession.collectAsState()
    
    val currentUser = (userSession as? UserSession.Authenticated)?.user
    val canTakeAction = currentUser?.role in listOf(UserRole.ADMIN, UserRole.RESCUE_TEAM, UserRole.AUTHORITY)
    
    // Load incident details
    LaunchedEffect(incidentId) {
        incidentViewModel.getIncident(incidentId)
    }
    
    val scrollState = rememberScrollState()
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Incident Details") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    incident?.let {
                        IconButton(onClick = { onNavigateToMap(it.latitude ?: 0.0, it.longitude ?: 0.0) }) {
                            Icon(Icons.Default.Map, contentDescription = "View on Map")
                        }
                    }
                }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when {
                isLoading && incident == null -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                }
                
                error != null && incident == null -> {
                    EmptyStateCard(
                        title = "Error Loading Incident",
                        description = error ?: "Something went wrong",
                        icon = Icons.Default.Error,
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp)
                    ) {
                        OceanPrimaryButton(
                            text = "Try Again",
                            onClick = { incidentViewModel.getIncident(incidentId) }
                        )
                    }
                }
                
                incident != null -> {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .verticalScroll(scrollState)
                            .padding(16.dp)
                    ) {
                        val inc = incident!!
                        
                        // Reference ID
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            colors = CardDefaults.cardColors(
                                containerColor = OceanColors.Primary.copy(alpha = 0.1f)
                            )
                        ) {
                            Row(
                                modifier = Modifier
                                    .padding(16.dp)
                                    .fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column {
                                    Text(
                                        text = "Reference ID",
                                        style = MaterialTheme.typography.labelMedium,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                    Text(
                                        text = inc.referenceId,
                                        style = MaterialTheme.typography.titleMedium,
                                        fontWeight = FontWeight.Bold,
                                        color = OceanColors.Primary
                                    )
                                }
                                StatusBadge(status = inc.status)
                            }
                        }
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        // Title and Description
                        Card(
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Column(
                                modifier = Modifier.padding(16.dp)
                            ) {
                                Text(
                                    text = inc.hazardType.displayName,
                                    style = MaterialTheme.typography.headlineSmall,
                                    fontWeight = FontWeight.Bold
                                )
                                
                                Spacer(modifier = Modifier.height(12.dp))
                                
                                Row(
                                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    HazardTypeBadge(hazardType = inc.hazardType)
                                    UrgencyBadge(urgency = inc.urgency)
                                }
                                
                                Spacer(modifier = Modifier.height(16.dp))
                                
                                Text(
                                    text = "Description",
                                    style = MaterialTheme.typography.titleSmall,
                                    fontWeight = FontWeight.SemiBold
                                )
                                Spacer(modifier = Modifier.height(4.dp))
                                Text(
                                    text = inc.description,
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        // Location
                        Card(
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Column(
                                modifier = Modifier.padding(16.dp)
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.LocationOn,
                                        contentDescription = null,
                                        tint = OceanColors.Primary
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(
                                        text = "Location",
                                        style = MaterialTheme.typography.titleMedium,
                                        fontWeight = FontWeight.SemiBold
                                    )
                                }
                                
                                Spacer(modifier = Modifier.height(12.dp))
                                
                                Text(
                                    text = inc.location,
                                    style = MaterialTheme.typography.bodyMedium
                                )
                                Spacer(modifier = Modifier.height(8.dp))
                                
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                                ) {
                                    Column {
                                        Text(
                                            text = "Latitude",
                                            style = MaterialTheme.typography.labelSmall,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                        Text(
                                            text = "%.6f".format(inc.latitude ?: 0.0),
                                            style = MaterialTheme.typography.bodyMedium,
                                            fontWeight = FontWeight.Medium
                                        )
                                    }
                                    Column {
                                        Text(
                                            text = "Longitude",
                                            style = MaterialTheme.typography.labelSmall,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                        Text(
                                            text = "%.6f".format(inc.longitude ?: 0.0),
                                            style = MaterialTheme.typography.bodyMedium,
                                            fontWeight = FontWeight.Medium
                                        )
                                    }
                                }
                                
                                Spacer(modifier = Modifier.height(12.dp))
                                
                                OutlinedButton(
                                    onClick = { onNavigateToMap(inc.latitude ?: 0.0, inc.longitude ?: 0.0) },
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Icon(Icons.Default.Map, contentDescription = null)
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text("View on Map")
                                }
                            }
                        }
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        // Image if available
                        inc.photoUrl?.let { url ->
                            Card(
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Column(
                                    modifier = Modifier.padding(16.dp)
                                ) {
                                    Row(
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Icon(
                                            imageVector = Icons.Default.Image,
                                            contentDescription = null,
                                            tint = OceanColors.Primary
                                        )
                                        Spacer(modifier = Modifier.width(8.dp))
                                        Text(
                                            text = "Photo Evidence",
                                            style = MaterialTheme.typography.titleMedium,
                                            fontWeight = FontWeight.SemiBold
                                        )
                                    }
                                    
                                    Spacer(modifier = Modifier.height(12.dp))
                                    
                                    AsyncImage(
                                        model = url,
                                        contentDescription = "Incident photo",
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .height(200.dp)
                                    )
                                }
                            }
                            
                            Spacer(modifier = Modifier.height(16.dp))
                        }
                        
                        // Timeline/Timestamps
                        Card(
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Column(
                                modifier = Modifier.padding(16.dp)
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Timeline,
                                        contentDescription = null,
                                        tint = OceanColors.Primary
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(
                                        text = "Timeline",
                                        style = MaterialTheme.typography.titleMedium,
                                        fontWeight = FontWeight.SemiBold
                                    )
                                }
                                
                                Spacer(modifier = Modifier.height(12.dp))
                                
                                TimelineItem(
                                    title = "Reported",
                                    date = inc.createdAt,
                                    isCompleted = true
                                )
                                
                                TimelineItem(
                                    title = "Verified",
                                    date = inc.verifiedAt,
                                    isCompleted = inc.status in listOf(
                                        IncidentStatus.VERIFIED,
                                        IncidentStatus.IN_PROGRESS,
                                        IncidentStatus.RESOLVED
                                    )
                                )
                                
                                TimelineItem(
                                    title = "Response Deployed",
                                    date = inc.updatedAt,
                                    isCompleted = inc.status in listOf(
                                        IncidentStatus.IN_PROGRESS,
                                        IncidentStatus.RESOLVED
                                    )
                                )
                                
                                TimelineItem(
                                    title = "Resolved",
                                    date = inc.resolvedAt,
                                    isCompleted = inc.status == IncidentStatus.RESOLVED,
                                    isLast = true
                                )
                            }
                        }
                        
                        // Actions for authorized users
                        if (canTakeAction && inc.status != IncidentStatus.RESOLVED) {
                            Spacer(modifier = Modifier.height(24.dp))
                            
                            Text(
                                text = "Actions",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.SemiBold
                            )
                            
                            Spacer(modifier = Modifier.height(12.dp))
                            
                            when (inc.status) {
                                IncidentStatus.PENDING -> {
                                    OceanPrimaryButton(
                                        text = "Verify Incident",
                                        onClick = { incidentViewModel.verifyIncident(inc.id) },
                                        modifier = Modifier.fillMaxWidth(),
                                        icon = Icons.Default.Verified,
                                        isLoading = isLoading
                                    )
                                }
                                IncidentStatus.VERIFIED -> {
                                    OceanPrimaryButton(
                                        text = "Deploy Response",
                                        onClick = { incidentViewModel.deployResponse(inc.id) },
                                        modifier = Modifier.fillMaxWidth(),
                                        icon = Icons.Default.LocalShipping,
                                        isLoading = isLoading
                                    )
                                }
                                IncidentStatus.IN_PROGRESS -> {
                                    OceanPrimaryButton(
                                        text = "Mark as Resolved",
                                        onClick = { incidentViewModel.resolveIncident(inc.id) },
                                        modifier = Modifier.fillMaxWidth(),
                                        icon = Icons.Default.CheckCircle,
                                        isLoading = isLoading
                                    )
                                }
                                else -> {}
                            }
                        }
                        
                        Spacer(modifier = Modifier.height(32.dp))
                    }
                }
            }
        }
    }
}

@Composable
private fun TimelineItem(
    title: String,
    date: java.time.LocalDateTime?,
    isCompleted: Boolean,
    isLast: Boolean = false
) {
    val dateFormatter = java.time.format.DateTimeFormatter.ofPattern("MMM d, yyyy 'at' h:mm a")
    
    Row(
        modifier = Modifier.height(IntrinsicSize.Min)
    ) {
        // Timeline indicator
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Surface(
                shape = MaterialTheme.shapes.extraSmall,
                color = if (isCompleted) OceanColors.Success else MaterialTheme.colorScheme.outlineVariant,
                modifier = Modifier.size(12.dp)
            ) {}
            
            if (!isLast) {
                Box(
                    modifier = Modifier
                        .width(2.dp)
                        .weight(1f)
                        .padding(vertical = 4.dp)
                ) {
                    Divider(
                        modifier = Modifier.fillMaxHeight(),
                        color = if (isCompleted) OceanColors.Success else MaterialTheme.colorScheme.outlineVariant
                    )
                }
            }
        }
        
        Spacer(modifier = Modifier.width(12.dp))
        
        Column(
            modifier = Modifier.padding(bottom = if (isLast) 0.dp else 16.dp)
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                color = if (isCompleted) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.onSurfaceVariant
            )
            if (date != null) {
                Text(
                    text = date.format(dateFormatter),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            } else if (!isCompleted) {
                Text(
                    text = "Pending",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                )
            }
        }
    }
}
