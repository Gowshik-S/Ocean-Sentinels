package com.oceansentinels.app.presentation.ui.theme

import androidx.compose.ui.graphics.Color

/**
 * Ocean Sentinels Color Palette
 * Based on app.assets design files
 */
object OceanColors {
    // Primary Colors - Yellow/Gold from designs (#FDDA0D, #E0C002)
    val Primary = Color(0xFFFDDA0D)
    val PrimaryDark = Color(0xFFE0C002)
    val PrimaryLight = Color(0xFFFFE54C)
    val OnPrimary = Color(0xFF111111)
    
    // Secondary Colors - Deep Blue for contrast
    val Secondary = Color(0xFF005A9C)
    val SecondaryDark = Color(0xFF003D6B)
    val SecondaryLight = Color(0xFF3D8BC9)
    val OnSecondary = Color.White
    
    // Accent
    val Accent = Color(0xFFFDDA0D)
    val AccentVariant = Color(0xFFFFE54C)
    
    // Background
    val Background = Color.White
    val BackgroundSecondary = Color(0xFFF8F9FA)
    val Surface = Color.White
    val SurfaceVariant = Color(0xFFE9ECEF)
    val OnBackground = Color(0xFF111111)
    val OnSurface = Color(0xFF111111)
    
    // Text
    val TextPrimary = Color(0xFF111111)
    val TextSecondary = Color(0xFF6C757D)
    val TextHint = Color(0xFFADB5BD)
    val TextDisabled = Color(0xFFCED4DA)
    val TextOnPrimary = Color(0xFF111111)
    val TextOnSecondary = Color.White
    val TextLight = Color(0xFFF8F9FA)
    
    // Status Colors from Alerts screen design
    val Success = Color(0xFF32BA23)  // Green #32BA23
    val SuccessLight = Color(0xFFD4EDDA)
    val OnSuccess = Color.White
    
    val Warning = Color(0xFFE97612)  // Orange #E97612
    val WarningLight = Color(0xFFFFF3CD)
    val OnWarning = Color.White
    
    val Error = Color(0xFFE12828)  // Red #E12828
    val ErrorLight = Color(0xFFF8D7DA)
    val OnError = Color.White
    
    val Info = Color(0xFF5867F1)  // Purple #5867F1
    val InfoLight = Color(0xFFE8EAFD)
    val OnInfo = Color.White
    
    // Additional Colors
    val Orange = Color(0xFFE97612)
    val Danger = Color(0xFFE12828)
    val Gray = Color(0xFF6C757D)
    val Purple = Color(0xFF5867F1)
    val Green = Color(0xFF32BA23)
    val PlaceholderGray = Color(0xFFD9D9D9)
    
    // Dashboard Card Colors from Figma UI designs
    val DashboardBlue = Color(0xFF3B698F)       // Blue card backgrounds
    val FilterPurple = Color(0xFF6244BC)         // Filter/refresh button purple
    val FilterBlue = Color(0xFF61BBD9)           // Filter section light blue
    val LiveFeedBlue = Color(0xFF1824C5)         // Live indicator dot
    val LiveFeedRed = Color(0xFFF40A0A)          // Alert indicator dot
    
    // Urgency Level Colors
    val UrgencyLow = Color(0xFF28A745)
    val UrgencyLowBg = Color(0xFFD4EDDA)
    val UrgencyMedium = Color(0xFFFFC107)
    val UrgencyMediumBg = Color(0xFFFFF3CD)
    val UrgencyHigh = Color(0xFFFD7E14)
    val UrgencyHighBg = Color(0xFFFFE5D0)
    val UrgencyCritical = Color(0xFFDC3545)
    val UrgencyCriticalBg = Color(0xFFF8D7DA)
    
    // Status Colors
    val StatusPending = Color(0xFF6C757D)
    val StatusPendingBg = Color(0xFFE9ECEF)
    val StatusVerified = Color(0xFF17A2B8)
    val StatusVerifiedBg = Color(0xFFD1ECF1)
    val StatusInProgress = Color(0xFFFFC107)
    val StatusInProgressBg = Color(0xFFFFF3CD)
    val StatusResolved = Color(0xFF28A745)
    val StatusResolvedBg = Color(0xFFD4EDDA)
    val StatusClosed = Color(0xFF6C757D)
    val StatusClosedBg = Color(0xFFE9ECEF)
    
    // Hazard Type Colors
    val HazardHighWaves = Color(0xFF0077B6)
    val HazardStrongCurrents = Color(0xFF00B4D8)
    val HazardFlooding = Color(0xFF48CAE4)
    val HazardTsunami = Color(0xFFDC3545)
    val HazardDebris = Color(0xFF6C757D)
    val HazardErosion = Color(0xFF8B5E3C)
    val HazardStorm = Color(0xFF7C3AED)
    val HazardOther = Color(0xFF495057)
    
    // Map Colors
    val MapMarkerDefault = Color(0xFF005A9C)
    val MapMarkerUrgent = Color(0xFFDC3545)
    val MapCluster = Color(0xFFFFC107)
    
    // Card Colors
    val CardBackground = Color.White
    val CardBorder = Color(0xFFE9ECEF)
    
    // Divider
    val Divider = Color(0xFFDEE2E6)
    
    // Ripple
    val Ripple = Color(0x1A005A9C)
    
    // Scrim
    val Scrim = Color(0x80000000)
    
    // Gradient
    val GradientOceanStart = Color(0xFF005A9C)
    val GradientOceanEnd = Color(0xFF00B4D8)
    val GradientSunsetStart = Color(0xFFFFC107)
    val GradientSunsetEnd = Color(0xFFFD7E14)
}

/**
 * Dark Theme Color Palette
 * Professional dark mode colors for better readability and reduced eye strain
 */
object DarkModeColors {
    // Background Colors - Professional dark palette
    val Background = Color(0xFF0D1117)           // GitHub-style dark
    val BackgroundElevated = Color(0xFF161B22)   // Slightly elevated surfaces
    val Surface = Color(0xFF1C2128)              // Card surfaces
    val SurfaceVariant = Color(0xFF21262D)       // Variant surfaces
    val SurfaceElevated = Color(0xFF2D333B)      // High elevation surfaces
    
    // Primary Colors - Brighter yellow for dark mode visibility
    val Primary = Color(0xFFFFE066)              // Brighter yellow for dark mode
    val PrimaryVariant = Color(0xFFFDDA0D)       // Original yellow
    val OnPrimary = Color(0xFF1C2128)            // Dark text on primary
    
    // Secondary Colors
    val Secondary = Color(0xFF58A6FF)            // Bright blue for dark mode
    val SecondaryVariant = Color(0xFF388BFD)
    val OnSecondary = Color(0xFF0D1117)
    
    // Text Colors - High contrast for readability
    val TextPrimary = Color(0xFFF0F3F6)          // High contrast white
    val TextSecondary = Color(0xFF8B949E)        // Muted secondary text
    val TextTertiary = Color(0xFF6E7681)         // Less prominent text
    val TextDisabled = Color(0xFF484F58)         // Disabled state
    val TextLink = Color(0xFF58A6FF)             // Link color
    
    // Status Colors - Vibrant for dark mode
    val Success = Color(0xFF3FB950)              // Brighter green
    val SuccessLight = Color(0xFF238636)
    val OnSuccess = Color(0xFF0D1117)
    
    val Warning = Color(0xFFD29922)              // Golden warning
    val WarningLight = Color(0xFF9E6A03)
    val OnWarning = Color(0xFF0D1117)
    
    val Error = Color(0xFFF85149)                // Bright red
    val ErrorLight = Color(0xFFDA3633)
    val OnError = Color(0xFFF0F3F6)
    
    val Info = Color(0xFF79C0FF)                 // Light blue info
    val InfoLight = Color(0xFF388BFD)
    val OnInfo = Color(0xFF0D1117)
    
    // Border & Divider
    val Border = Color(0xFF30363D)
    val BorderMuted = Color(0xFF21262D)
    val Divider = Color(0xFF30363D)
    
    // Card
    val CardBackground = Color(0xFF161B22)
    val CardBorder = Color(0xFF30363D)
    
    // Status specific for dark mode
    val Purple = Color(0xFFA371F7)               // Brighter purple
    val Green = Color(0xFF3FB950)
    val Orange = Color(0xFFD29922)
    val Red = Color(0xFFF85149)
    
    // Urgency Colors for dark mode
    val UrgencyLow = Color(0xFF3FB950)
    val UrgencyLowBg = Color(0xFF238636)
    val UrgencyMedium = Color(0xFFD29922)
    val UrgencyMediumBg = Color(0xFF9E6A03)
    val UrgencyHigh = Color(0xFFDB6D28)
    val UrgencyHighBg = Color(0xFF762D0A)
    val UrgencyCritical = Color(0xFFF85149)
    val UrgencyCriticalBg = Color(0xFF8B1A10)
    
    // Status Colors for dark mode
    val StatusPending = Color(0xFFA371F7)
    val StatusPendingBg = Color(0xFF3D1F79)
    val StatusVerified = Color(0xFF58A6FF)
    val StatusVerifiedBg = Color(0xFF0C2D6B)
    val StatusInProgress = Color(0xFFD29922)
    val StatusInProgressBg = Color(0xFF533D00)
    val StatusResolved = Color(0xFF3FB950)
    val StatusResolvedBg = Color(0xFF1A4721)
    val StatusClosed = Color(0xFF8B949E)
    val StatusClosedBg = Color(0xFF21262D)
}
