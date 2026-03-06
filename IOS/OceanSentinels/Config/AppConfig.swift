import Foundation

/// App configuration — API keys and base URLs
/// Converted from: build.gradle.kts buildConfigField entries
enum AppConfig {
    
    // MARK: - API Configuration
    
    static let apiBaseURL: String = {
        #if DEBUG
        return "https://ocean-hazard-1-6j5g.onrender.com/api"
        #else
        return "https://ocean-hazard-1-6j5g.onrender.com/api"
        #endif
    }()
    
    // MARK: - API Keys
    // Production: store in Config.xcconfig or Xcode build settings.
    // These defaults match the Android local.properties for development.
    
    static var mapboxAccessToken: String {
        Bundle.main.infoDictionary?["MBXAccessToken"] as? String
            ?? "pk.eyJ1IjoiZ293c2hpayIsImEiOiJjbWdqcWh6b2kwbWlyMmtvbWN2bzd0NjFkIn0.wMmUOMSKTWV4gROT4CvlIQ"
    }
    
    static var weatherAPIKey: String {
        Bundle.main.infoDictionary?["WEATHERAPI_KEY"] as? String
            ?? "f65978b7b4d24271a6364713261402"
    }
    
    static var indianAPIKey: String {
        Bundle.main.infoDictionary?["INDIAN_API_KEY"] as? String
            ?? "sk-live-mLpjO5IlL34DIXcaD0RGKm3Gm49GMaVAs0b9w3Vi"
    }
    
    // MARK: - App Constants
    
    static let appName = "Ocean Sentinels"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // MARK: - Notification Channel IDs (iOS uses category identifiers)
    
    static let notificationCategoryAlerts = "ocean_sentinels_alerts"
    static let notificationCategoryUpdates = "ocean_sentinels_updates"
    static let notificationCategoryGeneral = "ocean_sentinels_general"
    static let notificationCategoryMesh = "ocean_mesh_service"

    // MARK: - Aliases (referenced by API services)

    static var baseURL: String { apiBaseURL }
    static var weatherApiKey: String { weatherAPIKey }
    static var indianApiKey: String { indianAPIKey }
}
