package com.oceansentinels.app.presentation.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.oceansentinels.app.domain.model.HazardType
import com.oceansentinels.app.domain.model.IncidentStatus
import com.oceansentinels.app.domain.model.UrgencyLevel
import com.oceansentinels.app.domain.model.UserRole
import com.oceansentinels.app.presentation.ui.theme.OceanColors

/**
 * Badge for incident status
 */
@Composable
fun StatusBadge(
    status: IncidentStatus,
    modifier: Modifier = Modifier
) {
    val (color, text, icon) = when (status) {
        IncidentStatus.PENDING -> Triple(OceanColors.Warning, "Pending", Icons.Default.HourglassEmpty)
        IncidentStatus.VERIFIED -> Triple(OceanColors.Info, "Verified", Icons.Default.Verified)
        IncidentStatus.IN_PROGRESS -> Triple(OceanColors.Primary, "In Progress", Icons.Default.LocalShipping)
        IncidentStatus.RESOLVED -> Triple(OceanColors.Success, "Resolved", Icons.Default.CheckCircle)
        IncidentStatus.CLOSED -> Triple(OceanColors.Gray, "Closed", Icons.Default.Close)
    }
    
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(20.dp),
        color = color.copy(alpha = 0.1f)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = color,
                modifier = Modifier.size(16.dp)
            )
            Spacer(modifier = Modifier.width(6.dp))
            Text(
                text = text,
                style = MaterialTheme.typography.labelMedium,
                color = color,
                fontWeight = FontWeight.SemiBold
            )
        }
    }
}

/**
 * Badge for urgency level
 */
@Composable
fun UrgencyBadge(
    urgency: UrgencyLevel,
    modifier: Modifier = Modifier
) {
    val (color, text, icon) = when (urgency) {
        UrgencyLevel.LOW -> Triple(OceanColors.Success, "Low", Icons.Default.ArrowDownward)
        UrgencyLevel.MEDIUM -> Triple(OceanColors.Warning, "Medium", Icons.Default.Remove)
        UrgencyLevel.HIGH -> Triple(OceanColors.Orange, "High", Icons.Default.ArrowUpward)
        UrgencyLevel.CRITICAL -> Triple(OceanColors.Danger, "Critical", Icons.Default.PriorityHigh)
    }
    
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(20.dp),
        color = color.copy(alpha = 0.1f)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = color,
                modifier = Modifier.size(16.dp)
            )
            Spacer(modifier = Modifier.width(6.dp))
            Text(
                text = text,
                style = MaterialTheme.typography.labelMedium,
                color = color,
                fontWeight = FontWeight.SemiBold
            )
        }
    }
}

/**
 * Badge for hazard type
 */
@Composable
fun HazardTypeBadge(
    hazardType: HazardType,
    modifier: Modifier = Modifier,
    compact: Boolean = false
) {
    val (color, text, icon) = getHazardTypeInfo(hazardType)
    
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(if (compact) 8.dp else 12.dp),
        color = color.copy(alpha = 0.15f)
    ) {
        Row(
            modifier = Modifier.padding(
                horizontal = if (compact) 8.dp else 12.dp,
                vertical = if (compact) 4.dp else 8.dp
            ),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = color,
                modifier = Modifier.size(if (compact) 14.dp else 18.dp)
            )
            if (!compact) {
                Spacer(modifier = Modifier.width(6.dp))
                Text(
                    text = text,
                    style = MaterialTheme.typography.labelMedium,
                    color = color,
                    fontWeight = FontWeight.Medium
                )
            }
        }
    }
}

/**
 * Get hazard type display info
 */
fun getHazardTypeInfo(hazardType: HazardType): Triple<Color, String, ImageVector> {
    return when (hazardType) {
        HazardType.HIGH_WAVES -> Triple(Color(0xFF1976D2), "High Waves", Icons.Default.Water)
        HazardType.STRONG_CURRENTS -> Triple(Color(0xFF0288D1), "Strong Currents", Icons.Default.Waves)
        HazardType.FLOODING -> Triple(Color(0xFF00897B), "Coastal Flooding", Icons.Default.WaterDrop)
        HazardType.TSUNAMI -> Triple(Color(0xFFD32F2F), "Tsunami Warning", Icons.Default.Warning)
        HazardType.DEBRIS -> Triple(Color(0xFF607D8B), "Debris/Pollution", Icons.Default.Delete)
        HazardType.EROSION -> Triple(Color(0xFF795548), "Coastal Erosion", Icons.Default.Terrain)
        HazardType.STORM -> Triple(Color(0xFF5E35B1), "Storm Alert", Icons.Default.Thunderstorm)
        HazardType.OTHER -> Triple(Color(0xFF9E9E9E), "Other Hazard", Icons.Default.MoreHoriz)
    }
}

/**
 * Badge for user role
 */
@Composable
fun RoleBadge(
    role: UserRole,
    modifier: Modifier = Modifier
) {
    val (color, text, icon) = when (role) {
        UserRole.ADMIN -> Triple(OceanColors.Danger, "Admin", Icons.Default.AdminPanelSettings)
        UserRole.RESCUE_TEAM -> Triple(OceanColors.Primary, "Rescue Team", Icons.Default.LocalHospital)
        UserRole.AUTHORITY -> Triple(OceanColors.Warning, "Authority", Icons.Default.Shield)
        UserRole.PUBLIC -> Triple(OceanColors.Success, "Citizen", Icons.Default.Person)
    }
    
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(8.dp),
        color = color.copy(alpha = 0.1f)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = color,
                modifier = Modifier.size(14.dp)
            )
            Spacer(modifier = Modifier.width(4.dp))
            Text(
                text = text,
                style = MaterialTheme.typography.labelSmall,
                color = color,
                fontWeight = FontWeight.SemiBold
            )
        }
    }
}

/**
 * Count badge (e.g., for notifications)
 */
@Composable
fun CountBadge(
    count: Int,
    modifier: Modifier = Modifier,
    color: Color = OceanColors.Danger
) {
    if (count > 0) {
        Surface(
            modifier = modifier.size(20.dp),
            shape = RoundedCornerShape(10.dp),
            color = color
        ) {
            Box(contentAlignment = Alignment.Center) {
                Text(
                    text = if (count > 99) "99+" else count.toString(),
                    style = MaterialTheme.typography.labelSmall,
                    color = Color.White,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

/**
 * Dot indicator (e.g., for online status)
 */
@Composable
fun StatusDot(
    isActive: Boolean,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .size(10.dp)
            .background(
                color = if (isActive) OceanColors.Success else OceanColors.Gray,
                shape = RoundedCornerShape(5.dp)
            )
    )
}

/**
 * Verification badge
 */
@Composable
fun VerifiedBadge(
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(4.dp),
        color = OceanColors.Success.copy(alpha = 0.1f)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.Verified,
                contentDescription = "Verified",
                tint = OceanColors.Success,
                modifier = Modifier.size(12.dp)
            )
            Spacer(modifier = Modifier.width(4.dp))
            Text(
                text = "Verified",
                style = MaterialTheme.typography.labelSmall,
                color = OceanColors.Success
            )
        }
    }
}

/**
 * Priority indicator (animated pulse for critical)
 */
@Composable
fun PriorityIndicator(
    urgency: UrgencyLevel,
    modifier: Modifier = Modifier
) {
    val color = when (urgency) {
        UrgencyLevel.LOW -> OceanColors.Success
        UrgencyLevel.MEDIUM -> OceanColors.Warning
        UrgencyLevel.HIGH -> OceanColors.Orange
        UrgencyLevel.CRITICAL -> OceanColors.Danger
    }
    
    Box(
        modifier = modifier
            .width(4.dp)
            .fillMaxHeight()
            .background(color, RoundedCornerShape(2.dp))
    )
}
