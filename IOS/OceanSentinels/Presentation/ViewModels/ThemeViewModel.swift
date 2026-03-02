import Foundation
import Observation

// MARK: - ThemeViewModel

/// Manages app-wide theme (dark mode) and offline mode preferences.
///
/// Reads/writes through `PreferencesManager` which persists to UserDefaults.
@Observable
@MainActor
final class ThemeViewModel {

    // MARK: - State

    var isDarkMode: Bool
    var isOfflineMode: Bool

    // MARK: - Dependencies

    private let preferencesManager: PreferencesManager

    // MARK: - Init

    init(preferencesManager: PreferencesManager = .shared) {
        self.preferencesManager = preferencesManager
        self.isDarkMode = preferencesManager.isDarkMode
        self.isOfflineMode = preferencesManager.isOfflineMode
    }

    // MARK: - Actions

    func toggleDarkMode(_ enabled: Bool) {
        isDarkMode = enabled
        preferencesManager.isDarkMode = enabled
    }

    func toggleOfflineMode(_ enabled: Bool) {
        isOfflineMode = enabled
        preferencesManager.isOfflineMode = enabled
    }
}
