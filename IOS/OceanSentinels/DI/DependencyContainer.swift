import Foundation
import SwiftData

/// Manual dependency injection container.
/// Replaces Hilt DI modules: NetworkModule, DatabaseModule, RepositoryModule, LocationModule, MeshModule.
///
/// Usage: Create once at app startup, pass to views via .environmentObject()
@MainActor
final class DependencyContainer: ObservableObject {

    // MARK: - Shared Singleton

    static let shared = DependencyContainer()

    // MARK: - Singletons

    let modelContainer: ModelContainer
    let preferences: PreferencesManager
    let networkClient: NetworkClient

    // MARK: - Database

    let database: DatabaseManager

    // MARK: - API Services

    let oceanAPI: OceanSentinelsAPI
    let weatherAPI: WeatherAPIService
    let indianWeatherAPI: IndianWeatherAPIService

    // MARK: - Repositories

    let authRepository: AuthRepositoryImpl
    let incidentRepository: IncidentRepositoryImpl
    let analyticsRepository: AnalyticsRepositoryImpl
    let userRepository: UserRepositoryImpl
    let weatherRepository: WeatherRepositoryImpl

    // MARK: - Mesh

    let bleMeshManager: BleMeshManager
    let meshMessageRepository: MeshMessageRepository
    let networkConnectivityManager: NetworkConnectivityManager

    // MARK: - Init

    init() {
        // Database
        self.modelContainer = OceanSentinelsStore.makeContainer()
        self.database = DatabaseManager(modelContainer: modelContainer)

        // Preferences
        self.preferences = PreferencesManager.shared

        // Network
        self.networkClient = NetworkClient.shared
        self.networkConnectivityManager = NetworkConnectivityManager.shared

        // API Services
        self.oceanAPI = OceanSentinelsAPI(client: networkClient)
        self.weatherAPI = WeatherAPIService()
        self.indianWeatherAPI = IndianWeatherAPIService()

        // Mesh
        self.bleMeshManager = BleMeshManager.shared
        self.meshMessageRepository = MeshMessageRepository(
            databaseManager: database,
            api: oceanAPI,
            bleMeshManager: bleMeshManager,
            deviceIdentifier: DeviceIdentifier.shared,
            networkConnectivityManager: networkConnectivityManager
        )

        // Repositories
        self.authRepository = AuthRepositoryImpl(
            api: oceanAPI,
            preferences: preferences,
            database: database,
            networkClient: networkClient
        )

        self.incidentRepository = IncidentRepositoryImpl(
            api: oceanAPI,
            database: database
        )

        self.analyticsRepository = AnalyticsRepositoryImpl(
            api: oceanAPI
        )

        self.userRepository = UserRepositoryImpl(
            api: oceanAPI,
            database: database
        )

        self.weatherRepository = WeatherRepositoryImpl(
            weatherAPI: weatherAPI,
            indianWeatherAPI: indianWeatherAPI
        )

        // Start monitoring connectivity
        networkConnectivityManager.startMonitoring()

        // Configure mesh background service
        MeshBackgroundService.shared.configure(
            meshRepository: meshMessageRepository,
            bleMeshManager: bleMeshManager,
            deviceIdentifier: DeviceIdentifier.shared,
            networkConnectivityManager: networkConnectivityManager
        )
    }

    // MARK: - ViewModel Factories

    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(authRepository: authRepository)
    }

    func makeIncidentViewModel() -> IncidentViewModel {
        IncidentViewModel(
            incidentRepository: incidentRepository,
            meshMessageRepository: meshMessageRepository,
            networkConnectivityManager: networkConnectivityManager
        )
    }

    func makeAnalyticsViewModel() -> AnalyticsViewModel {
        AnalyticsViewModel(analyticsRepository: analyticsRepository)
    }

    func makeAdminViewModel() -> AdminViewModel {
        AdminViewModel(userRepository: userRepository)
    }

    func makeWeatherViewModel() -> WeatherViewModel {
        WeatherViewModel(weatherRepository: weatherRepository)
    }

    func makeMeshViewModel() -> MeshViewModel {
        MeshViewModel(
            meshRepository: meshMessageRepository,
            bleMeshManager: bleMeshManager
        )
    }

    func makeThemeViewModel() -> ThemeViewModel {
        ThemeViewModel(preferencesManager: preferences)
    }

    // MARK: - Session Restore

    func restoreSession() async {
        await authRepository.restoreSession()
    }
}
