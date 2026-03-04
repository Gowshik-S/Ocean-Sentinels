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
- **After fix:** 0 expected (all errors were deployment-target gated)

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
