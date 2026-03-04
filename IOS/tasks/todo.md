# Ocean Sentinels iOS — Bug Fix Tracker

## Build Errors (2026-03-04)

### Root Cause
Package.swift only declared `.iOS(.v17)` as a platform. When Xcode built for a macOS destination
(e.g. "My Mac"), it defaulted to `arm64-apple-macos10.13` which is too old for SwiftData (macOS 14+)
and os.Logger (macOS 11+).

### Fix Applied
- [x] **Package.swift** — Added `.macOS(.v14)` to platforms array

### Affected Files (all resolved by the single platform fix)
- [x] `Data/Local/Database/UserEntity.swift` — `@Model` requires macOS 14+
- [x] `Data/Local/Database/IncidentEntity.swift` — `@Model` requires macOS 14+
- [x] `Data/Local/Database/MeshMessageEntity.swift` — `@Model` requires macOS 14+
- [x] `Data/Local/Database/OceanSentinelsStore.swift` — `@ModelActor` + `Logger` requires macOS 14+ / 11+
- [x] `Data/Repository/UserRepositoryImpl.swift` — `Logger` requires macOS 11+
- [x] `Data/Repository/WeatherRepositoryImpl.swift` — `Logger` requires macOS 11+
- [x] `Data/Repository/IncidentRepositoryImpl.swift` — `Logger` (cascading)
- [x] `Data/Repository/AnalyticsRepositoryImpl.swift` — `Logger` (cascading)
- [x] `Data/Repository/AuthRepositoryImpl.swift` — `Logger` (cascading)
- [x] `Data/Local/Preferences/PreferencesManager.swift` — `Logger` (cascading)
- [x] `Data/Remote/API/NetworkClient.swift` — `Logger` (cascading)
- [x] `Mesh/BLE/BleMeshManager.swift` — `Logger` (cascading)
- [x] `Mesh/BLE/DeviceIdentifier.swift` — `Logger` (cascading)
- [x] `Mesh/Network/NetworkConnectivityManager.swift` — `Logger` (cascading)
- [x] `Mesh/Repository/MeshMessageRepository.swift` — `Logger` (cascading)
- [x] `Mesh/Service/MeshBackgroundService.swift` — `Logger` (cascading)
- [x] `Utils/AppLogger.swift` — `Logger` (cascading)

### Error Count
- **Before fix:** ~100+ errors (all "only available in macOS X" type)
- **After fix:** 0 (confirmed by Build 2, deployment-target errors gone)

---

## Build 2 Errors — iOS-only SwiftUI APIs (2026-03-04)

### Root Cause
After adding `.macOS(.v14)`, the macOS build succeeded for Data/Domain/Mesh layers but
revealed 40+ errors across 20 Presentation files. These files used iOS-only SwiftUI APIs:
- `Color(.systemGray4/.systemGray6/.secondarySystemBackground/.systemBackground/.systemGray)` — UIColor names unavailable on macOS
- `.topBarTrailing` — ToolbarItemPlacement unavailable on macOS
- `.listStyle(.insetGrouped)` — ListStyle unavailable on macOS
- `.navigationBarTitleDisplayMode(.inline)` — unavailable on macOS
- `.keyboardType()`, `.textContentType()`, `.textInputAutocapitalization()` — iOS-only modifiers

### Fix Applied
- [x] **Created `Utils/PlatformCompat.swift`** — Cross-platform compatibility extensions with `#if os(iOS)` / `#else` wrappers:
  - `Color.compatSystemGray`, `.compatSystemGray4`, `.compatSystemGray6`
  - `Color.compatSystemBackground`, `.compatSecondarySystemBackground`
  - `ToolbarItemPlacement.compatTopBarTrailing`
  - `.compatInlineNavigationTitle()`, `.compatInsetGroupedListStyle()`
  - `.compatEmailInputModifiers()`, `.compatPhoneInputModifiers()`

### All 20 Files Fixed
- [x] `Presentation/UI/Components/Cards.swift` — systemGray6, systemGray4
- [x] `Presentation/UI/Components/TextFields.swift` — systemGray4 x3, systemGray6, keyboardType, textContentType, textInputAutocapitalization
- [x] `Presentation/UI/Screens/Admin/AdminConsoleScreen.swift` — topBarTrailing, secondarySystemBackground, insetGrouped, navigationBarTitleDisplayMode x2
- [x] `Presentation/UI/Screens/Admin/AdminDashboardScreen.swift` — insetGrouped, topBarTrailing, secondarySystemBackground
- [x] `Presentation/UI/Screens/Admin/UserManagementScreen.swift` — topBarTrailing
- [x] `Presentation/UI/Screens/Weather/WeatherScreen.swift` — topBarTrailing, secondarySystemBackground
- [x] `Presentation/UI/Screens/Rescue/RescueConsoleScreen.swift` — topBarTrailing, secondarySystemBackground
- [x] `Presentation/UI/Screens/Profile/ProfileScreen.swift` — topBarTrailing
- [x] `Presentation/UI/Screens/Profile/SettingsScreen.swift` — insetGrouped
- [x] `Presentation/UI/Screens/Map/MapScreen.swift` — navigationBarTitleDisplayMode, topBarTrailing, secondarySystemBackground
- [x] `Presentation/UI/Screens/Mesh/MeshNetworkScreen.swift` — insetGrouped, topBarTrailing, secondarySystemBackground x2
- [x] `Presentation/UI/Screens/Home/HomeScreen.swift` — systemGray6, systemBackground, secondarySystemBackground, systemGray
- [x] `Presentation/UI/Screens/Incidents/IncidentDetailScreen.swift` — navigationBarTitleDisplayMode, secondarySystemBackground x4, systemGray4 x2
- [x] `Presentation/UI/Screens/Incidents/AlertsScreen.swift` — insetGrouped, topBarTrailing, systemBackground
- [x] `Presentation/UI/Screens/Incidents/IncidentsDashboardScreen.swift` — topBarTrailing, navigationBarTitleDisplayMode
- [x] `Presentation/UI/Screens/Incidents/MyReportsScreen.swift` — topBarTrailing
- [x] `Presentation/UI/Screens/Incidents/ReportIncidentScreen.swift` — systemGray6, navigationBarTitleDisplayMode
- [x] `Presentation/UI/Screens/Authority/AuthorityConsoleScreen.swift` — topBarTrailing, secondarySystemBackground
- [x] `Presentation/UI/Screens/Auth/RegisterScreen.swift` — systemGray6, navigationBarTitleDisplayMode, systemGray4
- [x] `Presentation/UI/Screens/Auth/LoginScreen.swift` — textContentType, textInputAutocapitalization, systemGray6 x2

---

## Remaining Work (Post-Build Fixes)

### Known Gaps from CONVERSION_PLAN.md
- [ ] PHY Coded advertising — iOS has no public API for Coded PHY advertising
- [ ] Firebase push (token registration) — needs APNs config + Firebase iOS SDK
- [ ] Mapbox Maps — Different API from Android, needs MapboxMaps iOS SDK integration
- [ ] Photo picker — PHPickerViewController needed instead of Android ActivityResult
- [ ] EncryptedSharedPreferences → Keychain migration

### Build Verification
- [ ] Rebuild on macOS with "My Mac" destination → confirm 0 errors
- [ ] Rebuild for iOS Simulator → confirm 0 errors
- [ ] Run on physical iOS 17+ device
