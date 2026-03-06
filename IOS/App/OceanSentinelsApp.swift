import SwiftUI
import MapboxMaps

/// Ocean Sentinels iOS App — Entry Point
/// Converted from: OceanSentinelsApp.kt + MainActivity.kt
@main
struct OceanSentinelsApp: App {

    @StateObject private var container = DependencyContainer.shared
    @State private var themeViewModel = ThemeViewModel()

    init() {
        // Configure logging
        #if DEBUG
        AppLogger.configure(level: .debug)
        #else
        AppLogger.configure(level: .info)
        #endif

        // Initialize Mapbox access token
        MapboxOptions.accessToken = AppConfig.mapboxAccessToken
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(container)
                .environment(themeViewModel)
                .preferredColorScheme(themeViewModel.isDarkMode ? .dark : .light)
        }
    }
}
