import SwiftUI

// MARK: - ContentView

/// Root view that manages auth state and navigation.
/// Replaces Android's `MainActivity` + `LocationPermissionGate` + `OceanNavHost`.
struct ContentView: View {
    @EnvironmentObject private var container: DependencyContainer
    @State private var authViewModel: AuthViewModel?
    @State private var router = NavigationRouter()

    var body: some View {
        Group {
            if let authVM = authViewModel {
                switch authVM.userSession {
                case .loading:
                    SplashScreen()
                case .unauthenticated:
                    NavigationStack(path: $router.authPath) {
                        LoginScreen()
                            .navigationDestination(for: AuthRoute.self) { route in
                                switch route {
                                case .register:
                                    RegisterScreen()
                                }
                            }
                    }
                    .environment(authVM)
                    .environment(router)
                case .authenticated:
                    MainTabView()
                        .environment(authVM)
                        .environment(router)
                }
            } else {
                SplashScreen()
            }
        }
        .task {
            let vm = container.makeAuthViewModel()
            authViewModel = vm
            await container.restoreSession()
        }
    }
}

// MARK: - Auth Routes

enum AuthRoute: Hashable {
    case register
}

// MARK: - NavigationRouter

/// Centralized navigation state for the app.
@Observable
final class NavigationRouter {
    var authPath = NavigationPath()
    var mainPath = NavigationPath()
    var profilePath = NavigationPath()
    var selectedTab: AppTab = .home

    func navigateToLogin() {
        authPath = NavigationPath()
    }

    func navigate(to route: AppRoute) {
        mainPath.append(route)
    }

    func navigateInProfile(to route: AppRoute) {
        profilePath.append(route)
    }

    func popToRoot() {
        mainPath = NavigationPath()
    }
}

// MARK: - App Tabs

enum AppTab: String, CaseIterable {
    case home = "Home"
    case alerts = "Alerts"
    case weather = "Weather"
    case report = "Report"
    case mesh = "Mesh"
    case profile = "Profile"

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .alerts: "exclamationmark.triangle.fill"
        case .weather: "cloud.fill"
        case .report: "camera.fill"
        case .mesh: "point.3.filled.connected.trianglepath.dotted"
        case .profile: "person.fill"
        }
    }
}

// MARK: - MainTabView

/// Main tab bar view after authentication.
struct MainTabView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(NavigationRouter.self) private var router
    @EnvironmentObject private var container: DependencyContainer

    @State private var incidentVM: IncidentViewModel?
    @State private var adminVM: AdminViewModel?
    @State private var analyticsVM: AnalyticsViewModel?
    @State private var weatherVM: WeatherViewModel?
    @State private var meshVM: MeshViewModel?

    var body: some View {
        @Bindable var router = router

        Group {
            if let incidentVM, let adminVM, let analyticsVM, let weatherVM, let meshVM {
                mainContent(router: router)
                    .environment(incidentVM)
                    .environment(adminVM)
                    .environment(analyticsVM)
                    .environment(weatherVM)
                    .environment(meshVM)
            } else {
                ProgressView("Loading...")
            }
        }
        .task {
            incidentVM = container.makeIncidentViewModel()
            adminVM = container.makeAdminViewModel()
            analyticsVM = container.makeAnalyticsViewModel()
            weatherVM = container.makeWeatherViewModel()
            meshVM = container.makeMeshViewModel()
        }
    }

    @ViewBuilder
    private func mainContent(router: NavigationRouter) -> some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.mainPath) {
                HomeScreen()
                    .navigationDestination(for: AppRoute.self) { route in
                        destinationView(for: route)
                    }
            }
            .tabItem {
                Label(AppTab.home.rawValue, systemImage: AppTab.home.icon)
            }
            .tag(AppTab.home)

            NavigationStack {
                IncidentsDashboardScreen()
                    .navigationDestination(for: AppRoute.self) { route in
                        destinationView(for: route)
                    }
            }
            .tabItem {
                Label(AppTab.alerts.rawValue, systemImage: AppTab.alerts.icon)
            }
            .tag(AppTab.alerts)

            NavigationStack {
                WeatherScreen()
            }
            .tabItem {
                Label(AppTab.weather.rawValue, systemImage: AppTab.weather.icon)
            }
            .tag(AppTab.weather)

            NavigationStack {
                ReportIncidentScreen()
            }
            .tabItem {
                Label(AppTab.report.rawValue, systemImage: AppTab.report.icon)
            }
            .tag(AppTab.report)

            NavigationStack {
                MeshNetworkScreen()
            }
            .tabItem {
                Label(AppTab.mesh.rawValue, systemImage: AppTab.mesh.icon)
            }
            .tag(AppTab.mesh)

            NavigationStack(path: $router.profilePath) {
                ProfileScreen()
                    .navigationDestination(for: AppRoute.self) { route in
                        destinationView(for: route)
                    }
            }
            .tabItem {
                Label(AppTab.profile.rawValue, systemImage: AppTab.profile.icon)
            }
            .tag(AppTab.profile)
        }
        .tint(Color.oceanPrimary)
    }

    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .incidentDetail(let id):
            IncidentDetailScreen(incidentId: id)
        case .reportIncident:
            ReportIncidentScreen()
        case .myReports:
            MyReportsScreen()
        case .incidentsDashboard:
            IncidentsDashboardScreen()
        case .analytics:
            AnalyticsScreen()
        case .weather:
            WeatherScreen()
        case .map:
            MapScreen()
        case .meshNetwork:
            MeshNetworkScreen()
        case .adminConsole:
            AdminConsoleScreen()
        case .adminDashboard:
            AdminDashboardScreen()
        case .createRescueTeam:
            CreateRescueTeamScreen()
        case .createAuthority:
            CreateAuthorityScreen()
        case .userManagement:
            UserManagementScreen()
        case .rescueConsole:
            RescueConsoleScreen()
        case .authorityConsole:
            AuthorityConsoleScreen()
        case .profile:
            ProfileScreen()
        case .settings:
            SettingsScreen()
        case .termsConditions:
            TermsConditionsScreen()
        default:
            HomeScreen()
        }
    }
}
