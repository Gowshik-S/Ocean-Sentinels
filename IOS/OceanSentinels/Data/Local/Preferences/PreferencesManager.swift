import Foundation
import Combine
import os

/// UserDefaults-based preferences manager.
/// Replaces Android DataStore PreferencesManager.
///
/// Uses @AppStorage-compatible keys for SwiftUI binding.
/// Published properties emit Combine events for reactive updates.
final class PreferencesManager: ObservableObject {
    
    static let shared = PreferencesManager()
    
    private let defaults: UserDefaults
    private let logger = Logger(subsystem: "com.oceansentinels.app", category: "Preferences")
    
    // MARK: - Keys
    
    private enum Keys {
        static let authToken = "auth_token"
        static let userData = "user_data"
        static let isLoggedIn = "is_logged_in"
        static let rememberMe = "remember_me"
        static let darkMode = "dark_mode"
        static let notificationsEnabled = "notifications_enabled"
        static let apnsToken = "apns_token"  // Replaces FCM token
        static let firstLaunch = "first_launch"
        static let demoPopupShown = "demo_popup_shown"
        static let offlineMode = "offline_mode"
    }
    
    // MARK: - Published Properties
    
    @Published var authToken: String? {
        didSet { defaults.set(authToken, forKey: Keys.authToken) }
    }
    
    @Published var isLoggedIn: Bool {
        didSet { defaults.set(isLoggedIn, forKey: Keys.isLoggedIn) }
    }
    
    @Published var rememberMe: Bool {
        didSet { defaults.set(rememberMe, forKey: Keys.rememberMe) }
    }
    
    @Published var isDarkMode: Bool {
        didSet { defaults.set(isDarkMode, forKey: Keys.darkMode) }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }
    
    @Published var isFirstLaunch: Bool {
        didSet { defaults.set(isFirstLaunch, forKey: Keys.firstLaunch) }
    }
    
    @Published var hasDemoPopupShown: Bool {
        didSet { defaults.set(hasDemoPopupShown, forKey: Keys.demoPopupShown) }
    }
    
    @Published var isOfflineMode: Bool {
        didSet { defaults.set(isOfflineMode, forKey: Keys.offlineMode) }
    }
    
    // MARK: - Init
    
    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        
        // Load persisted values
        self.authToken = defaults.string(forKey: Keys.authToken)
        self.isLoggedIn = defaults.bool(forKey: Keys.isLoggedIn)
        self.rememberMe = defaults.bool(forKey: Keys.rememberMe)
        self.isDarkMode = defaults.bool(forKey: Keys.darkMode)
        self.notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
        self.isFirstLaunch = defaults.object(forKey: Keys.firstLaunch) as? Bool ?? true
        self.hasDemoPopupShown = defaults.bool(forKey: Keys.demoPopupShown)
        self.isOfflineMode = defaults.bool(forKey: Keys.offlineMode)
    }
    
    // MARK: - Auth Token
    
    func saveAuthToken(_ token: String) {
        authToken = token
        logger.debug("Auth token saved")
    }
    
    func clearAuthToken() {
        authToken = nil
        logger.debug("Auth token cleared")
    }
    
    // MARK: - User Data (Codable → JSON)
    
    var userData: User? {
        get {
            guard let data = defaults.data(forKey: Keys.userData) else { return nil }
            return try? JSONDecoder().decode(User.self, from: data)
        }
        set {
            if let user = newValue {
                let data = try? JSONEncoder().encode(user)
                defaults.set(data, forKey: Keys.userData)
            } else {
                defaults.removeObject(forKey: Keys.userData)
            }
            objectWillChange.send()
        }
    }
    
    func saveUserData(_ user: User) {
        userData = user
        logger.debug("User data saved: \(user.username)")
    }
    
    func clearUserData() {
        userData = nil
        logger.debug("User data cleared")
    }
    
    // MARK: - APNs Token (replaces FCM)
    
    var apnsToken: String? {
        get { defaults.string(forKey: Keys.apnsToken) }
        set { defaults.set(newValue, forKey: Keys.apnsToken) }
    }
    
    func saveAPNsToken(_ token: String) {
        apnsToken = token
        logger.debug("APNs token saved")
    }
    
    // MARK: - Session Management
    
    func setLoggedIn(_ loggedIn: Bool) {
        isLoggedIn = loggedIn
    }
    
    func setFirstLaunchComplete() {
        isFirstLaunch = false
    }
    
    func setDemoPopupShown() {
        hasDemoPopupShown = true
    }
    
    // MARK: - Clear
    
    func clearSession() {
        authToken = nil
        userData = nil
        isLoggedIn = false
        logger.info("Session cleared")
    }
    
    func clearAll() {
        let domain = Bundle.main.bundleIdentifier ?? "com.oceansentinels.app"
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()
        
        // Reset published properties to defaults
        authToken = nil
        isLoggedIn = false
        rememberMe = false
        isDarkMode = false
        notificationsEnabled = true
        isFirstLaunch = true
        hasDemoPopupShown = false
        isOfflineMode = false
        
        logger.info("All preferences cleared")
    }
}
