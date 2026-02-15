package com.oceansentinels.app.presentation.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import com.oceansentinels.app.domain.model.UserRole
import com.oceansentinels.app.domain.model.UserSession
import com.oceansentinels.app.presentation.ui.screens.admin.AdminConsoleScreen
import com.oceansentinels.app.presentation.ui.screens.admin.AdminDashboardScreen
import com.oceansentinels.app.presentation.ui.screens.admin.CreateAuthorityScreen
import com.oceansentinels.app.presentation.ui.screens.admin.CreateRescueTeamScreen
import com.oceansentinels.app.presentation.ui.screens.admin.UserManagementScreen
import com.oceansentinels.app.presentation.ui.screens.analytics.AnalyticsScreen
import com.oceansentinels.app.presentation.ui.screens.auth.LoginScreen
import com.oceansentinels.app.presentation.ui.screens.auth.RegisterScreen
import com.oceansentinels.app.presentation.ui.screens.auth.SplashScreen
import com.oceansentinels.app.presentation.ui.screens.authority.AuthorityConsoleScreen
import com.oceansentinels.app.presentation.ui.screens.home.HomeScreen
import com.oceansentinels.app.presentation.ui.screens.incidents.IncidentDetailScreen
import com.oceansentinels.app.presentation.ui.screens.incidents.IncidentsDashboardScreen
import com.oceansentinels.app.presentation.ui.screens.incidents.MyReportsScreen
import com.oceansentinels.app.presentation.ui.screens.incidents.ReportIncidentScreen
import com.oceansentinels.app.presentation.ui.screens.map.MapScreen
import com.oceansentinels.app.presentation.ui.screens.mesh.MeshNetworkScreen
import com.oceansentinels.app.presentation.ui.screens.profile.ProfileScreen
import com.oceansentinels.app.presentation.ui.screens.profile.SettingsScreen
import com.oceansentinels.app.presentation.ui.screens.profile.TermsConditionsScreen
import com.oceansentinels.app.presentation.ui.screens.rescue.RescueConsoleScreen
import com.oceansentinels.app.presentation.ui.screens.weather.WeatherScreen
import com.oceansentinels.app.presentation.viewmodel.AuthViewModel

/**
 * Main Navigation Host for Ocean Sentinels app
 */
@Composable
fun OceanNavHost(
    navController: NavHostController,
    startDestination: String = Screen.Splash.route
) {
    val authViewModel: AuthViewModel = hiltViewModel()
    val userSession by authViewModel.userSession.collectAsState()
    
    // Helper to navigate to role-specific console
    val navigateToRoleConsole: () -> Unit = {
        val currentUser = (userSession as? UserSession.Authenticated)?.user
        when (currentUser?.role) {
            UserRole.RESCUE_TEAM -> navController.navigate(Screen.RescueConsole.route)
            UserRole.AUTHORITY -> navController.navigate(Screen.AuthorityConsole.route)
            else -> navController.navigate(Screen.AdminConsole.route)
        }
    }
    
    NavHost(
        navController = navController,
        startDestination = startDestination
    ) {
        // Splash Screen
        composable(Screen.Splash.route) {
            SplashScreen(
                onNavigateToHome = {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Splash.route) { inclusive = true }
                    }
                },
                onNavigateToLogin = {
                    navController.navigate(Screen.Login.route) {
                        popUpTo(Screen.Splash.route) { inclusive = true }
                    }
                }
            )
        }
        
        // Auth Screens
        composable(Screen.Login.route) {
            LoginScreen(
                onNavigateToRegister = {
                    navController.navigate(Screen.Register.route)
                },
                onNavigateToHome = {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Login.route) { inclusive = true }
                    }
                }
            )
        }
        
        composable(Screen.Register.route) {
            RegisterScreen(
                onNavigateToLogin = {
                    navController.popBackStack()
                },
                onNavigateToHome = {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Register.route) { inclusive = true }
                    }
                }
            )
        }
        
        // Home Screen
        composable(Screen.Home.route) {
            HomeScreen(
                onNavigateToMap = {
                    navController.navigate(Screen.Map.route)
                },
                onNavigateToReport = {
                    navController.navigate(Screen.ReportIncident.route)
                },
                onNavigateToMyReports = {
                    navController.navigate(Screen.MyReports.route)
                },
                onNavigateToIncidents = {
                    navController.navigate(Screen.IncidentsDashboard.route)
                },
                onNavigateToAnalytics = {
                    navController.navigate(Screen.Analytics.route)
                },
                onNavigateToWeather = {
                    navController.navigate(Screen.Weather.route)
                },
                onNavigateToAdmin = navigateToRoleConsole,
                onNavigateToProfile = {
                    navController.navigate(Screen.Profile.route)
                },
                onNavigateToMesh = {
                    navController.navigate(Screen.MeshNetwork.route)
                },
                onLogout = {
                    navController.navigate(Screen.Login.route) {
                        popUpTo(Screen.Home.route) { inclusive = true }
                    }
                }
            )
        }
        
        // Map Screen
        composable(Screen.Map.route) {
            MapScreen(
                onNavigateBack = { navController.popBackStack() },
                onNavigateToDetail = { incidentId ->
                    navController.navigate(Screen.IncidentDetail.createRoute(incidentId))
                },
                onNavigateToReport = {
                    navController.navigate(Screen.ReportIncident.route)
                }
            )
        }
        
        // Report Incident Screen
        composable(Screen.ReportIncident.route) {
            ReportIncidentScreen(
                onNavigateBack = { navController.popBackStack() },
                onIncidentCreated = { incidentId ->
                    navController.navigate(Screen.IncidentDetail.createRoute(incidentId)) {
                        popUpTo(Screen.Home.route)
                    }
                }
            )
        }
        
        // My Reports Screen
        composable(Screen.MyReports.route) {
            MyReportsScreen(
                onNavigateBack = { navController.popBackStack() },
                onNavigateToDetail = { incidentId ->
                    navController.navigate(Screen.IncidentDetail.createRoute(incidentId))
                },
                onNavigateToReport = {
                    navController.navigate(Screen.ReportIncident.route)
                }
            )
        }
        
        // Incident Detail Screen
        composable(
            route = Screen.IncidentDetail.route,
            arguments = listOf(
                navArgument("incidentId") { type = NavType.IntType }
            )
        ) { backStackEntry ->
            val incidentId = backStackEntry.arguments?.getInt("incidentId") ?: 0
            IncidentDetailScreen(
                incidentId = incidentId,
                onNavigateBack = { navController.popBackStack() },
                onNavigateToMap = { lat, lng ->
                    // Navigate to map with coordinates (for now just navigate to map)
                    navController.navigate(Screen.Map.route)
                }
            )
        }
        
        // Incidents Dashboard Screen (for admin/authority/rescue)
        composable(Screen.IncidentsDashboard.route) {
            IncidentsDashboardScreen(
                onNavigateBack = { navController.popBackStack() },
                onNavigateToDetail = { incidentId ->
                    navController.navigate(Screen.IncidentDetail.createRoute(incidentId))
                },
                onNavigateToHome = {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Home.route) { inclusive = true }
                    }
                },
                onNavigateToAlerts = { },
                onNavigateToWeather = {
                    navController.navigate(Screen.Weather.route)
                },
                onNavigateToReport = {
                    navController.navigate(Screen.ReportIncident.route)
                },
                onNavigateToProfile = {
                    navController.navigate(Screen.Profile.route)
                },
                onNavigateToAdmin = navigateToRoleConsole,
                onNavigateToMesh = {
                    navController.navigate(Screen.MeshNetwork.route)
                }
            )
        }
        
        // Analytics Screen
        composable(Screen.Analytics.route) {
            AnalyticsScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }

        // Weather Screen
        composable(Screen.Weather.route) {
            WeatherScreen(
                onNavigateBack = { navController.popBackStack() },
                onNavigateToHome = {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Home.route) { inclusive = true }
                    }
                },
                onNavigateToAlerts = {
                    navController.navigate(Screen.IncidentsDashboard.route)
                },
                onNavigateToReport = {
                    navController.navigate(Screen.ReportIncident.route)
                },
                onNavigateToProfile = {
                    navController.navigate(Screen.Profile.route)
                },
                onNavigateToAdmin = navigateToRoleConsole,
                onNavigateToMesh = {
                    navController.navigate(Screen.MeshNetwork.route)
                }
            )
        }
        
        // Admin Console Screen (incident management + assignment)
        composable(Screen.AdminConsole.route) {
            AdminConsoleScreen(
                onNavigateBack = { navController.popBackStack() },
                onNavigateToHome = {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Home.route) { inclusive = true }
                    }
                },
                onNavigateToAlerts = {
                    navController.navigate(Screen.IncidentsDashboard.route)
                },
                onNavigateToWeather = {
                    navController.navigate(Screen.Weather.route)
                },
                onNavigateToReport = {
                    navController.navigate(Screen.ReportIncident.route)
                },
                onNavigateToProfile = {
                    navController.navigate(Screen.Profile.route)
                },
                onNavigateToDetail = { incidentId ->
                    navController.navigate(Screen.IncidentDetail.createRoute(incidentId))
                },
                onNavigateToAdmin = navigateToRoleConsole,
                onNavigateToMesh = {
                    navController.navigate(Screen.MeshNetwork.route)
                }
            )
        }
        
        // Admin Dashboard Screen
        composable(Screen.AdminDashboard.route) {
            AdminDashboardScreen(
                onNavigateBack = { navController.popBackStack() },
                onNavigateToCreateRescueTeam = {
                    navController.navigate(Screen.CreateRescueTeam.route)
                },
                onNavigateToCreateAuthority = {
                    navController.navigate(Screen.CreateAuthority.route)
                },
                onNavigateToUserManagement = {
                    navController.navigate(Screen.UserManagement.route)
                }
            )
        }
        
        // Create Rescue Team Screen
        composable(Screen.CreateRescueTeam.route) {
            CreateRescueTeamScreen(
                onNavigateBack = { navController.popBackStack() },
                onCreateSuccess = { navController.popBackStack() }
            )
        }
        
        // Create Authority Screen
        composable(Screen.CreateAuthority.route) {
            CreateAuthorityScreen(
                onNavigateBack = { navController.popBackStack() },
                onCreateSuccess = { navController.popBackStack() }
            )
        }
        
        // User Management Screen
        composable(Screen.UserManagement.route) {
            UserManagementScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }
        
        // Profile Screen
        composable(Screen.Profile.route) {
            ProfileScreen(
                onNavigateBack = { navController.popBackStack() },
                onNavigateToSettings = {
                    navController.navigate(Screen.Settings.route)
                },
                onLogout = {
                    navController.navigate(Screen.Login.route) {
                        popUpTo(Screen.Home.route) { inclusive = true }
                    }
                },
                onNavigateToHome = {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Home.route) { inclusive = true }
                    }
                },
                onNavigateToAlerts = {
                    navController.navigate(Screen.IncidentsDashboard.route)
                },
                onNavigateToWeather = {
                    navController.navigate(Screen.Weather.route)
                },
                onNavigateToReport = {
                    navController.navigate(Screen.ReportIncident.route)
                },
                onNavigateToAdmin = navigateToRoleConsole,
                onNavigateToMesh = {
                    navController.navigate(Screen.MeshNetwork.route)
                }
            )
        }
        
        // Settings Screen
        composable(Screen.Settings.route) {
            SettingsScreen(
                onNavigateBack = { navController.popBackStack() },
                onNavigateToTerms = {
                    navController.navigate(Screen.TermsConditions.route)
                }
            )
        }
        
        // Terms & Conditions Screen
        composable(Screen.TermsConditions.route) {
            TermsConditionsScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }
        
        // Mesh Network Screen (BLE mesh hazard reporting + message tracking)
        composable(Screen.MeshNetwork.route) {
            MeshNetworkScreen(
                onNavigateBack = { navController.popBackStack() },
                onNavigateToHome = {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Home.route) { inclusive = true }
                    }
                },
                onNavigateToAlerts = {
                    navController.navigate(Screen.IncidentsDashboard.route)
                },
                onNavigateToWeather = {
                    navController.navigate(Screen.Weather.route)
                },
                onNavigateToReport = {
                    navController.navigate(Screen.ReportIncident.route)
                },
                onNavigateToProfile = {
                    navController.navigate(Screen.Profile.route)
                }
            )
        }
        
        // Rescue Console Screen
        composable(Screen.RescueConsole.route) {
            RescueConsoleScreen(
                onNavigateBack = { navController.popBackStack() },
                onNavigateToHome = {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Home.route) { inclusive = true }
                    }
                },
                onNavigateToAlerts = {
                    navController.navigate(Screen.IncidentsDashboard.route)
                },
                onNavigateToWeather = {
                    navController.navigate(Screen.Weather.route)
                },
                onNavigateToReport = {
                    navController.navigate(Screen.ReportIncident.route)
                },
                onNavigateToProfile = {
                    navController.navigate(Screen.Profile.route)
                },
                onNavigateToDetail = { incidentId ->
                    navController.navigate(Screen.IncidentDetail.createRoute(incidentId))
                },
                onNavigateToAdmin = navigateToRoleConsole,
                onNavigateToMesh = {
                    navController.navigate(Screen.MeshNetwork.route)
                }
            )
        }
        
        // Authority Console Screen
        composable(Screen.AuthorityConsole.route) {
            AuthorityConsoleScreen(
                onNavigateBack = { navController.popBackStack() },
                onNavigateToHome = {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Home.route) { inclusive = true }
                    }
                },
                onNavigateToAlerts = {
                    navController.navigate(Screen.IncidentsDashboard.route)
                },
                onNavigateToWeather = {
                    navController.navigate(Screen.Weather.route)
                },
                onNavigateToReport = {
                    navController.navigate(Screen.ReportIncident.route)
                },
                onNavigateToProfile = {
                    navController.navigate(Screen.Profile.route)
                },
                onNavigateToDetail = { incidentId ->
                    navController.navigate(Screen.IncidentDetail.createRoute(incidentId))
                },
                onNavigateToAdmin = navigateToRoleConsole,
                onNavigateToMesh = {
                    navController.navigate(Screen.MeshNetwork.route)
                }
            )
        }
    }
}
