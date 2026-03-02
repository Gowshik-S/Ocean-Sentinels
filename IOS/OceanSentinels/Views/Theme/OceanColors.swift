import SwiftUI

/// Ocean Sentinels Color Palette
/// Converted from: Color.kt (OceanColors + DarkModeColors)
enum OceanColors {
    // Primary Colors - Yellow/Gold from designs (#FDDA0D, #E0C002)
    static let primary = Color(hex: 0xFDDA0D)
    static let primaryDark = Color(hex: 0xE0C002)
    static let primaryLight = Color(hex: 0xFFE54C)
    static let onPrimary = Color(hex: 0x111111)
    
    // Secondary Colors - Deep Blue
    static let secondary = Color(hex: 0x005A9C)
    static let secondaryDark = Color(hex: 0x003D6B)
    static let secondaryLight = Color(hex: 0x3D8BC9)
    static let onSecondary = Color.white
    
    // Accent
    static let accent = Color(hex: 0xFDDA0D)
    static let accentVariant = Color(hex: 0xFFE54C)
    
    // Background
    static let background = Color.white
    static let backgroundSecondary = Color(hex: 0xF8F9FA)
    static let surface = Color.white
    static let surfaceVariant = Color(hex: 0xE9ECEF)
    static let onBackground = Color(hex: 0x111111)
    static let onSurface = Color(hex: 0x111111)
    
    // Text
    static let textPrimary = Color(hex: 0x111111)
    static let textSecondary = Color(hex: 0x6C757D)
    static let textHint = Color(hex: 0xADB5BD)
    static let textDisabled = Color(hex: 0xCED4DA)
    static let textOnPrimary = Color(hex: 0x111111)
    static let textOnSecondary = Color.white
    static let textLight = Color(hex: 0xF8F9FA)
    
    // Status Colors
    static let success = Color(hex: 0x32BA23)
    static let successLight = Color(hex: 0xD4EDDA)
    static let onSuccess = Color.white
    
    static let warning = Color(hex: 0xE97612)
    static let warningLight = Color(hex: 0xFFF3CD)
    static let onWarning = Color.white
    
    static let error = Color(hex: 0xE12828)
    static let errorLight = Color(hex: 0xF8D7DA)
    static let onError = Color.white
    
    static let info = Color(hex: 0x5867F1)
    static let infoLight = Color(hex: 0xE8EAFD)
    static let onInfo = Color.white
    
    // Additional
    static let orange = Color(hex: 0xE97612)
    static let danger = Color(hex: 0xE12828)
    static let gray = Color(hex: 0x6C757D)
    static let purple = Color(hex: 0x5867F1)
    static let green = Color(hex: 0x32BA23)
    static let placeholderGray = Color(hex: 0xD9D9D9)
    
    // Dashboard
    static let dashboardBlue = Color(hex: 0x3B698F)
    static let filterPurple = Color(hex: 0x6244BC)
    static let filterBlue = Color(hex: 0x61BBD9)
    static let liveFeedBlue = Color(hex: 0x1824C5)
    static let liveFeedRed = Color(hex: 0xF40A0A)
    
    // Urgency
    static let urgencyLow = Color(hex: 0x28A745)
    static let urgencyLowBg = Color(hex: 0xD4EDDA)
    static let urgencyMedium = Color(hex: 0xFFC107)
    static let urgencyMediumBg = Color(hex: 0xFFF3CD)
    static let urgencyHigh = Color(hex: 0xFD7E14)
    static let urgencyHighBg = Color(hex: 0xFFE5D0)
    static let urgencyCritical = Color(hex: 0xDC3545)
    static let urgencyCriticalBg = Color(hex: 0xF8D7DA)
    
    // Status
    static let statusPending = Color(hex: 0x6C757D)
    static let statusPendingBg = Color(hex: 0xE9ECEF)
    static let statusVerified = Color(hex: 0x17A2B8)
    static let statusVerifiedBg = Color(hex: 0xD1ECF1)
    static let statusInProgress = Color(hex: 0xFFC107)
    static let statusInProgressBg = Color(hex: 0xFFF3CD)
    static let statusResolved = Color(hex: 0x28A745)
    static let statusResolvedBg = Color(hex: 0xD4EDDA)
    static let statusClosed = Color(hex: 0x6C757D)
    static let statusClosedBg = Color(hex: 0xE9ECEF)
    
    // Hazard Type Colors
    static let hazardHighWaves = Color(hex: 0x0077B6)
    static let hazardStrongCurrents = Color(hex: 0x00B4D8)
    static let hazardFlooding = Color(hex: 0x48CAE4)
    static let hazardTsunami = Color(hex: 0xE63946)
    static let hazardDebris = Color(hex: 0x6C757D)
    static let hazardErosion = Color(hex: 0xBC6C25)
    static let hazardStorm = Color(hex: 0x7B2CBF)
    static let hazardOther = Color(hex: 0xADB5BD)
}

/// Dark mode color overrides
enum DarkModeColors {
    static let primary = Color(hex: 0xFFE54C)
    static let onPrimary = Color(hex: 0x1A1A2E)
    static let primaryVariant = Color(hex: 0xE0C002)
    
    static let secondary = Color(hex: 0x4DA8DA)
    static let onSecondary = Color(hex: 0x1A1A2E)
    static let secondaryVariant = Color(hex: 0x2D6A8A)
    
    static let background = Color(hex: 0x0F0F23)
    static let surface = Color(hex: 0x1A1A2E)
    static let surfaceVariant = Color(hex: 0x252545)
    
    static let textPrimary = Color(hex: 0xE8E8F0)
    static let textSecondary = Color(hex: 0xA0A0B8)
    
    static let error = Color(hex: 0xFF6B6B)
    static let errorLight = Color(hex: 0x3D1F1F)
    static let onError = Color(hex: 0x1A1A2E)
    
    static let success = Color(hex: 0x51CF66)
    static let warning = Color(hex: 0xFFB347)
    static let info = Color(hex: 0x7C85F5)
    static let purple = Color(hex: 0x9775FA)
    
    static let border = Color(hex: 0x3A3A5C)
    static let borderMuted = Color(hex: 0x2A2A45)
}

/// Color extension for hex initialization
extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }

    // Convenience aliases so views can write `Color.oceanPrimary` etc.
    static let oceanPrimary = OceanColors.primary
    static let oceanPrimaryDark = OceanColors.primaryDark
    static let oceanSecondary = OceanColors.secondary
    static let oceanAccent = OceanColors.accent
    static let oceanSuccess = OceanColors.success
    static let oceanWarning = OceanColors.warning
    static let oceanError = OceanColors.error
    static let oceanInfo = OceanColors.info
    static let oceanOrange = OceanColors.orange
    static let oceanDanger = OceanColors.danger
}
