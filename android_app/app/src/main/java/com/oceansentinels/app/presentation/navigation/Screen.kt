package com.oceansentinels.app.presentation.navigation

/**
 * Navigation routes for Ocean Sentinels app
 */
sealed class Screen(val route: String) {
    
    // Auth screens
    data object Splash : Screen("splash")
    data object Login : Screen("login")
    data object Register : Screen("register")
    
    // Main screens
    data object Home : Screen("home")
    data object Map : Screen("map")
    data object ReportIncident : Screen("report_incident")
    data object MyReports : Screen("my_reports")
    data object IncidentDetail : Screen("incident_detail/{incidentId}") {
        fun createRoute(incidentId: Int) = "incident_detail/$incidentId"
    }
    
    // Dashboard screens
    data object IncidentsDashboard : Screen("incidents_dashboard")
    data object Analytics : Screen("analytics")
    data object Weather : Screen("weather")
    
    // Admin screens
    data object AdminDashboard : Screen("admin_dashboard")
    data object AdminConsole : Screen("admin_console")
    data object CreateRescueTeam : Screen("create_rescue_team")
    data object CreateAuthority : Screen("create_authority")
    data object UserManagement : Screen("user_management")
    
    // Role-specific consoles
    data object RescueConsole : Screen("rescue_console")
    data object AuthorityConsole : Screen("authority_console")
    
    // Profile screens
    data object Profile : Screen("profile")
    data object Settings : Screen("settings")
    data object TermsConditions : Screen("terms_conditions")
    
    // Mesh Network screen
    data object MeshNetwork : Screen("mesh_network")
    
    companion object {
        // Auth graph
        const val AUTH_GRAPH = "auth_graph"
        
        // Main graph
        const val MAIN_GRAPH = "main_graph"
        
        // Admin graph
        const val ADMIN_GRAPH = "admin_graph"
    }
}
