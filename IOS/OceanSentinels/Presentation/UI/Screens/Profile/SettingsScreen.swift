import SwiftUI

// MARK: - SettingsScreen

struct SettingsScreen: View {
    @Environment(ThemeViewModel.self) private var themeVM
    @Environment(NavigationRouter.self) private var router

    @State private var notificationsEnabled = true
    @State private var locationEnabled = true

    var body: some View {
        List {
            // Notifications
            Section("Notifications") {
                SettingsToggleItem(
                    icon: "bell.fill",
                    title: "Push Notifications",
                    subtitle: "Receive alerts for incidents and updates",
                    isOn: $notificationsEnabled
                )
            }

            // Location
            Section("Location") {
                SettingsToggleItem(
                    icon: "location.fill",
                    title: "Location Services",
                    subtitle: "Allow app to access your location",
                    isOn: $locationEnabled
                )
            }

            // Appearance
            Section("Appearance") {
                SettingsToggleItem(
                    icon: "moon.fill",
                    title: "Dark Mode",
                    subtitle: "Use dark theme",
                    isOn: Binding(
                        get: { themeVM.isDarkMode },
                        set: { themeVM.toggleDarkMode($0) }
                    )
                )
            }

            // Data
            Section("Data") {
                SettingsToggleItem(
                    icon: "icloud.slash.fill",
                    title: "Offline Mode",
                    subtitle: "Cache data for offline access",
                    isOn: Binding(
                        get: { themeVM.isOfflineMode },
                        set: { themeVM.toggleOfflineMode($0) }
                    )
                )

                SettingsClickItem(icon: "trash.fill", title: "Clear Cache", subtitle: "Free up storage space") {
                    // TODO: Implement cache clearing
                }
            }

            // Legal
            Section("Legal") {
                SettingsClickItem(icon: "doc.text.fill", title: "Terms & Conditions", subtitle: "Read our terms of service") {
                    router.navigate(to: .termsConditions)
                }

                SettingsClickItem(icon: "hand.raised.fill", title: "Privacy Policy", subtitle: "How we handle your data") {
                    router.navigate(to: .termsConditions)
                }
            }

            // Version
            Section {
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            }
        }
        .compatInsetGroupedListStyle()
        .navigationTitle("Settings")
    }
}

// MARK: - Settings Toggle Item

private struct SettingsToggleItem: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon).foregroundStyle(.secondary).frame(width: 24)
            VStack(alignment: .leading) {
                Text(title).font(.body)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden().tint(Color.oceanPrimary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Settings Click Item

private struct SettingsClickItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon).foregroundStyle(.secondary).frame(width: 24)
                VStack(alignment: .leading) {
                    Text(title).font(.body).foregroundStyle(.primary)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
    }
}
