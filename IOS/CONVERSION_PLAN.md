# Ocean Sentinels — Android → iOS Conversion Plan

## Project Overview

**Source:** `Ocean-Hazard/android_app/` — Kotlin + Jetpack Compose + Hilt + Room + Retrofit + BLE Mesh  
**Target:** `Ocean-Hazard/IOS/` — Swift + SwiftUI + Manual DI + SwiftData + URLSession + CoreBluetooth  
**Reference:** `bitchat/bitchat/Services/BLE/BLEService.swift` — iOS BLE mesh patterns (CBCentralManager, CBPeripheralManager, PHY Coded)

---

## Architecture Summary (Android → iOS)

| Android | iOS | Notes |
|---|---|---|
| Kotlin | Swift 5.9+ | |
| Jetpack Compose | SwiftUI | |
| Hilt (DI) | Manual DI Container | No native iOS DI framework |
| Room | SwiftData / CoreData | SwiftData preferred (iOS 17+) |
| Retrofit + OkHttp | URLSession + async/await | Native networking |
| DataStore Preferences | UserDefaults / @AppStorage | |
| Navigation Compose | NavigationStack + NavigationPath | |
| StateFlow | @Published + @Observable | |
| ViewModel (AAC) | @Observable class / @MainActor | |
| Coroutines | async/await + Task | |
| Flow | AsyncStream / Combine | |
| Foreground Service | BGTaskScheduler + BLE background modes | |
| Firebase Messaging | APNs + Firebase iOS SDK | |
| Mapbox Android SDK | Mapbox Maps iOS SDK | |
| Timber | os.Logger / OSLog | |
| Gson | Codable (JSONDecoder/Encoder) | |
| Coil (images) | AsyncImage (native SwiftUI) | |
| MPAndroidChart | Swift Charts (iOS 16+) | |
| Lottie Compose | Lottie iOS (lottie-ios) | |
| BLE (android.bluetooth) | CoreBluetooth | Reference: bitchat BLEService.swift |

---

## File Mapping (52 Android → ~55 iOS Swift files)

### 1. App Entry Point
| Android | iOS Swift |
|---|---|
| `OceanSentinelsApp.kt` | `OceanSentinelsApp.swift` |
| `MainActivity.kt` | `ContentView.swift` (SwiftUI lifecycle) |

### 2. Domain Layer (/Domain)
| Android | iOS Swift |
|---|---|
| `domain/model/Incident.kt` | `Domain/Models/Incident.swift` |
| `domain/model/User.kt` | `Domain/Models/User.swift` |
| `domain/model/Analytics.kt` | `Domain/Models/Analytics.swift` |
| `domain/repository/AuthRepository.kt` | `Domain/Repositories/AuthRepository.swift` (protocol) |
| `domain/repository/IncidentRepository.kt` | `Domain/Repositories/IncidentRepository.swift` (protocol) |
| `domain/repository/AnalyticsRepository.kt` | `Domain/Repositories/AnalyticsRepository.swift` (protocol) |
| `domain/repository/UserRepository.kt` | `Domain/Repositories/UserRepository.swift` (protocol) |

### 3. Data Layer (/Data)
| Android | iOS Swift |
|---|---|
| `data/remote/api/OceanSentinelsApi.kt` | `Data/Remote/API/OceanSentinelsAPI.swift` (URLSession) |
| `data/remote/api/WeatherApi.kt` | `Data/Remote/API/WeatherAPI.swift` |
| `data/remote/api/IndianWeatherApi.kt` | `Data/Remote/API/IndianWeatherAPI.swift` |
| `data/remote/dto/IncidentDto.kt` | `Data/Remote/DTO/IncidentDTO.swift` (Codable) |
| `data/remote/dto/UserDto.kt` | `Data/Remote/DTO/UserDTO.swift` |
| `data/remote/dto/WeatherDto.kt` | `Data/Remote/DTO/WeatherDTO.swift` |
| `data/remote/dto/IndianWeatherDto.kt` | `Data/Remote/DTO/IndianWeatherDTO.swift` |
| `data/remote/dto/AnalyticsDto.kt` | `Data/Remote/DTO/AnalyticsDTO.swift` |
| `data/local/database/OceanSentinelsDatabase.kt` | `Data/Local/Database/OceanSentinelsStore.swift` (SwiftData) |
| `data/local/database/Converters.kt` | (Not needed — Codable handles this) |
| `data/local/database/entity/*.kt` (3 files) | `Data/Local/Database/Entities/*.swift` (SwiftData @Model) |
| `data/local/database/dao/*.kt` (3 files) | Inline on SwiftData ModelContext (no separate DAO) |
| `data/local/preferences/PreferencesManager.kt` | `Data/Local/Preferences/PreferencesManager.swift` (@AppStorage) |
| `data/repository/AuthRepositoryImpl.kt` | `Data/Repositories/AuthRepositoryImpl.swift` |
| `data/repository/IncidentRepositoryImpl.kt` | `Data/Repositories/IncidentRepositoryImpl.swift` |
| `data/repository/UserRepositoryImpl.kt` | `Data/Repositories/UserRepositoryImpl.swift` |
| `data/repository/AnalyticsRepositoryImpl.kt` | `Data/Repositories/AnalyticsRepositoryImpl.swift` |
| `data/repository/WeatherRepository.kt` | `Data/Repositories/WeatherRepository.swift` |
| `data/service/OceanSentinelsMessagingService.kt` | `Data/Services/PushNotificationService.swift` (APNs) |

### 4. DI Layer (/DI)
| Android | iOS Swift |
|---|---|
| `di/NetworkModule.kt` | `DI/DependencyContainer.swift` (single file, manual DI) |
| `di/DatabaseModule.kt` | (merged into DependencyContainer) |
| `di/RepositoryModule.kt` | (merged into DependencyContainer) |
| `di/LocationModule.kt` | (merged into DependencyContainer) |
| `di/MeshModule.kt` | (merged into DependencyContainer) |

### 5. Mesh Layer (/Mesh) — **Critical: Use bitchat BLEService.swift patterns**
| Android | iOS Swift |
|---|---|
| `mesh/ble/BleMeshManager.kt` (1931 lines) | `Mesh/BLE/BleMeshManager.swift` (CoreBluetooth) |
| `mesh/ble/DeviceIdentifier.kt` | `Mesh/BLE/DeviceIdentifier.swift` (Keychain + UUID) |
| `mesh/model/MeshMessage.kt` | `Mesh/Models/MeshMessage.swift` |
| `mesh/model/MeshPeer.kt` | `Mesh/Models/MeshPeer.swift` |
| `mesh/network/NetworkConnectivityManager.kt` | `Mesh/Network/NetworkConnectivityManager.swift` (NWPathMonitor) |
| `mesh/repository/MeshMessageRepository.kt` | `Mesh/Repository/MeshMessageRepository.swift` |
| `mesh/service/MeshForegroundService.kt` | `Mesh/Service/MeshBackgroundService.swift` (BLE background modes) |

### 6. Presentation Layer (/Presentation)
| Android | iOS Swift |
|---|---|
| `presentation/navigation/Screen.kt` | `Navigation/AppRoute.swift` (enum) |
| `presentation/navigation/OceanNavHost.kt` | `Navigation/AppNavigator.swift` (NavigationStack) |

### 7. ViewModels (/ViewModels)
| Android | iOS Swift |
|---|---|
| `viewmodel/AuthViewModel.kt` | `ViewModels/AuthViewModel.swift` |
| `viewmodel/IncidentViewModel.kt` | `ViewModels/IncidentViewModel.swift` |
| `viewmodel/MeshViewModel.kt` | `ViewModels/MeshViewModel.swift` |
| `viewmodel/AdminViewModel.kt` | `ViewModels/AdminViewModel.swift` |
| `viewmodel/AnalyticsViewModel.kt` | `ViewModels/AnalyticsViewModel.swift` |
| `viewmodel/WeatherViewModel.kt` | `ViewModels/WeatherViewModel.swift` |
| `viewmodel/ThemeViewModel.kt` | `ViewModels/ThemeViewModel.swift` |

### 8. UI Layer (/Views)
| Android | iOS Swift |
|---|---|
| `ui/theme/Color.kt` | `Views/Theme/OceanColors.swift` |
| `ui/theme/Theme.kt` | `Views/Theme/OceanTheme.swift` |
| `ui/theme/Type.kt` | `Views/Theme/OceanTypography.swift` |
| `ui/components/Badges.kt` | `Views/Components/Badges.swift` |
| `ui/components/BottomNavBar.kt` | `Views/Components/BottomNavBar.swift` |
| `ui/components/Buttons.kt` | `Views/Components/Buttons.swift` |
| `ui/components/Cards.kt` | `Views/Components/Cards.swift` |
| `ui/components/TextFields.kt` | `Views/Components/TextFields.swift` |
| `ui/screens/auth/LoginScreen.kt` | `Views/Screens/Auth/LoginView.swift` |
| `ui/screens/auth/RegisterScreen.kt` | `Views/Screens/Auth/RegisterView.swift` |
| `ui/screens/auth/SplashScreen.kt` | `Views/Screens/Auth/SplashView.swift` |
| `ui/screens/home/HomeScreen.kt` | `Views/Screens/Home/HomeView.swift` |
| `ui/screens/incidents/AlertsScreen.kt` | `Views/Screens/Incidents/AlertsView.swift` |
| `ui/screens/incidents/IncidentDetailScreen.kt` | `Views/Screens/Incidents/IncidentDetailView.swift` |
| `ui/screens/incidents/IncidentsDashboardScreen.kt` | `Views/Screens/Incidents/IncidentsDashboardView.swift` |
| `ui/screens/incidents/MyReportsScreen.kt` | `Views/Screens/Incidents/MyReportsView.swift` |
| `ui/screens/incidents/ReportIncidentScreen.kt` | `Views/Screens/Incidents/ReportIncidentView.swift` |
| `ui/screens/map/MapScreen.kt` | `Views/Screens/Map/MapView.swift` |
| `ui/screens/mesh/MeshNetworkScreen.kt` | `Views/Screens/Mesh/MeshNetworkView.swift` |
| `ui/screens/profile/ProfileScreen.kt` | `Views/Screens/Profile/ProfileView.swift` |
| `ui/screens/profile/TermsConditionsScreen.kt` | `Views/Screens/Profile/TermsConditionsView.swift` |
| `ui/screens/weather/WeatherScreen.kt` | `Views/Screens/Weather/WeatherView.swift` |
| `ui/screens/analytics/AnalyticsScreen.kt` | `Views/Screens/Analytics/AnalyticsView.swift` |
| `ui/screens/admin/AdminConsoleScreen.kt` | `Views/Screens/Admin/AdminConsoleView.swift` |
| `ui/screens/admin/AdminDashboardScreen.kt` | `Views/Screens/Admin/AdminDashboardView.swift` |
| `ui/screens/admin/CreateUserScreens.kt` | `Views/Screens/Admin/CreateUserViews.swift` |
| `ui/screens/admin/UserManagementScreen.kt` | `Views/Screens/Admin/UserManagementView.swift` |
| `ui/screens/authority/AuthorityConsoleScreen.kt` | `Views/Screens/Authority/AuthorityConsoleView.swift` |
| `ui/screens/rescue/RescueConsoleScreen.kt` | `Views/Screens/Rescue/RescueConsoleView.swift` |

---

## Dependency Mapping (Android → iOS)

| Android Dependency | iOS Replacement | Swift Package / Native |
|---|---|---|
| Retrofit + Gson | URLSession + Codable | Native |
| OkHttp (interceptors) | URLSession + URLProtocol | Native |
| Room | SwiftData | Native (iOS 17+) |
| Hilt | Manual DI Container | Custom |
| DataStore Preferences | UserDefaults / @AppStorage | Native |
| Navigation Compose | NavigationStack | Native |
| Coil | AsyncImage | Native (SwiftUI) |
| MPAndroidChart | Swift Charts | Native (iOS 16+) |
| Timber | os.Logger | Native |
| Firebase Messaging | Firebase iOS SDK (FCM) | SPM: firebase-ios-sdk |
| Firebase Analytics | Firebase iOS SDK | SPM: firebase-ios-sdk |
| Mapbox Maps | Mapbox Maps SDK for iOS | SPM: mapbox-maps-ios |
| Accompanist Permissions | Custom PermissionManager | Custom |
| Lottie Compose | Lottie iOS | SPM: lottie-ios |
| play-services-location | CoreLocation | Native |
| ConnectivityManager | NWPathMonitor | Native (Network framework) |
| BLE (android.bluetooth) | CoreBluetooth | Native — reference bitchat BLEService.swift |

---

## BLE Mesh Conversion Strategy (Critical Section)

### Android BleMeshManager (1931 lines) → iOS BleMeshManager

**Key PHY Coded (Long Range) patterns from bitchat BLEService.swift:**
- Uses `CBCentralManager` + `CBPeripheralManager` dual-mode
- State restoration via `CBCentralManagerOptionRestoreIdentifierKey`
- Background execution via BLE background modes in Info.plist
- PHY Coded support via `CBPeripheralManager` advertising options (limited on iOS)

**Android → iOS BLE mapping:**

| Android | iOS (CoreBluetooth) |
|---|---|
| `BluetoothAdapter` | `CBCentralManager` + `CBPeripheralManager` |
| `BluetoothLeScanner.startScan()` | `CBCentralManager.scanForPeripherals()` |
| `BluetoothLeAdvertiser.startAdvertising()` | `CBPeripheralManager.startAdvertising()` |
| `BluetoothGattServer` | `CBPeripheralManager.add(CBMutableService)` |
| `BluetoothGatt` (client) | `CBPeripheral` (discovered) |
| `ScanSettings.PHY_LE_CODED` | iOS auto-negotiates PHY (no explicit API) |
| `AdvertisingSetParameters.PHY_LE_CODED` | **⚠️ iOS limitation: No public API for Coded PHY advertising** |
| `SCAN_DUTY_ON_MS / OFF_MS` | `CBCentralManagerScanOptionAllowDuplicatesKey` |
| `BluetoothGattCharacteristic` | `CBMutableCharacteristic` / `CBCharacteristic` |
| `notifyCharacteristicChanged()` | `CBPeripheralManager.updateValue()` |
| `onCharacteristicWriteRequest` | `peripheralManager(_:didReceiveWrite:)` |

**⚠️ iOS PHY Coded Limitation:**
iOS does NOT expose a public API for advertising on Coded PHY (LE Long Range).  
However, iOS CAN **scan and connect** to Coded PHY peripherals automatically.  
For advertising, we use standard 1M PHY and note this limitation.  
The bitchat approach (BLEService.swift) uses standard advertising too.

### Wire Protocol (identical between platforms)
- Length-prefix: `[4-byte BE length][UTF-8 JSON payload]`
- Legacy fallback: brace-counting for old peers
- Fragment reassembly with per-device buffers
- Same JSON field names (`id`, `mac`, `fp`, `ht`, `loc`, etc.)

### Relay Strategy (identical)
- Time-based expiry (72 hours) — NOT hop-based TTL
- Loop prevention: relayPath + LRU dedup cache + DB dedup
- MAX_RELAY_PATH = 255
- Relay batch size = 25

---

## iOS-Specific Considerations

### Background Execution
- No foreground service on iOS. Instead:
  - BLE background modes in Info.plist (`bluetooth-central`, `bluetooth-peripheral`)
  - State restoration for CBCentralManager/CBPeripheralManager
  - BGTaskScheduler for periodic queue processing
  - Reference: bitchat uses these exact patterns

### Permissions (Info.plist)
```
NSBluetoothAlwaysUsageDescription
NSBluetoothPeripheralUsageDescription
NSLocationWhenInUseUsageDescription
NSLocationAlwaysAndWhenInUseUsageDescription
NSCameraUsageDescription
NSPhotoLibraryUsageDescription
```

### Minimum Deployment Target
- iOS 17.0 (for SwiftData, @Observable macro)
- Fallback: iOS 16.0 with CoreData + ObservableObject

---

## Conversion Order (Priority)

### Phase 1: Foundation (do first)
1. ✅ `OceanSentinelsApp.swift` — App entry point
2. ✅ Domain models (`Incident.swift`, `User.swift`, `Analytics.swift`)
3. ✅ Domain repository protocols
4. ✅ Theme / Colors
5. ✅ `DependencyContainer.swift`

### Phase 2: Data Layer
6. ✅ DTOs (Codable structs)
7. ✅ API services (URLSession)
8. ✅ SwiftData entities + store
9. ✅ PreferencesManager
10. ✅ Repository implementations

### Phase 3: Mesh Layer (critical)
11. ✅ MeshMessage + MeshPeer models
12. ✅ DeviceIdentifier (Keychain-based)
13. ✅ NetworkConnectivityManager (NWPathMonitor)
14. ✅ BleMeshManager (CoreBluetooth — reference bitchat)
15. ✅ MeshMessageRepository
16. ✅ MeshBackgroundService

### Phase 4: ViewModels
17. ✅ AuthViewModel
18. ✅ IncidentViewModel
19. ✅ MeshViewModel
20. ✅ AdminViewModel, AnalyticsViewModel, WeatherViewModel, ThemeViewModel

### Phase 5: UI Layer
21. ✅ Navigation (AppRoute + AppNavigator)
22. ✅ Components (Badges, BottomNavBar, Buttons, Cards, TextFields)
23. ✅ Auth screens (Login, Register, Splash)
24. ✅ Home screen
25. ✅ Incident screens (list, detail, report, my reports, alerts)
26. ✅ Map screen (Mapbox iOS)
27. ✅ Mesh Network screen
28. ✅ Weather screen
29. ✅ Analytics screen
30. ✅ Admin/Authority/Rescue consoles
31. ✅ Profile + Settings + Terms

### Phase 6: Config & Build
32. ✅ Package.swift / Xcode project config
33. ✅ Info.plist (permissions, BLE background modes)
34. ✅ Build configuration (API keys, environments)

---

## Known Gaps & Flags

| Feature | Status | Notes |
|---|---|---|
| PHY Coded advertising | ⚠️ | iOS has no public API — scan works, advertising limited to 1M |
| Foreground Service | ⚠️ | Replaced with BLE background modes + BGTaskScheduler |
| Firebase push (token reg) | ⚠️ | Needs APNs config + Firebase iOS SDK setup |
| Mapbox Maps | ⚠️ | Different API than Android — MapboxMaps iOS SDK |
| File upload (multipart) | ✅ | URLSession supports multipart natively |
| Photo picker | ⚠️ | PHPickerViewController instead of Android's ActivityResult |
| Android ID (device identity) | ⚠️ | iOS uses Keychain-persisted UUID (similar to bitchat) |
| GMS FusedLocation | ⚠️ | CoreLocation CLLocationManager instead |
| EncryptedSharedPreferences | ⚠️ | Keychain instead of DataStore with security-crypto |

---

## Config Values (from Android build.gradle.kts)

```
API_BASE_URL = "https://ocean-hazard-1-6j5g.onrender.com/api"
MAPBOX_ACCESS_TOKEN = (from local.properties)
WEATHERAPI_KEY = (from local.properties)
INDIAN_API_KEY = (from local.properties)
```

These will be stored in a `Config.swift` file with `#if DEBUG` variants.
