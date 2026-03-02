import SwiftUI

// MARK: - AppRoute

/// All navigation routes for Ocean Sentinels.
/// Replaces the Android `Screen` sealed class.
enum AppRoute: Hashable {
    // Auth
    case splash
    case login
    case register

    // Main
    case home
    case map
    case reportIncident
    case myReports
    case incidentDetail(incidentId: Int)

    // Dashboard
    case incidentsDashboard
    case analytics
    case weather

    // Admin
    case adminDashboard
    case adminConsole
    case createRescueTeam
    case createAuthority
    case userManagement

    // Role-specific consoles
    case rescueConsole
    case authorityConsole

    // Profile
    case profile
    case settings
    case termsConditions

    // Mesh
    case meshNetwork
}
