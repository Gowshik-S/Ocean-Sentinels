# Ocean Sentinels - iOS

A SwiftUI-based iOS clone of the Ocean Sentinels Android app for coastal hazard reporting, monitoring, and BLE mesh communication.

## Requirements

- **Xcode 15.0+**
- **iOS 17.0+** (uses `@Observable`, SwiftData, `AsyncStream`)
- **Swift 5.9+**

## Project Setup

### 1. Create Xcode Project

1. Open Xcode → File → New → Project → iOS → App
2. Product Name: **OceanSentinels**
3. Bundle Identifier: `com.oceansentinels.app`
4. Interface: **SwiftUI**
5. Storage: **SwiftData**
6. Delete the auto-generated `ContentView.swift` and `Item.swift`
7. Drag the `OceanSentinels/` folder contents into the project

### 2. Add Swift Package Dependencies

File → Add Package Dependencies:

| Package | URL | Notes |
|---------|-----|-------|
| Firebase iOS SDK | `https://github.com/firebase/firebase-ios-sdk` | Messaging + Analytics |
| MapboxMaps | `https://github.com/mapbox/mapbox-maps-ios` | Map screen (optional) |

### 3. Configure Info.plist

The `Info.plist` is already created with all necessary entries:
- `UIBackgroundModes`: bluetooth-central, bluetooth-peripheral, location, remote-notification
- `NSBluetoothAlwaysUsageDescription` — BLE mesh relay
- `NSLocationWhenInUseUsageDescription` — Incident location & weather
- `NSCameraUsageDescription` — Incident photo capture
- `NSPhotoLibraryUsageDescription` — Attach existing photos

### 4. Configure Entitlements

The `OceanSentinels.entitlements` file includes:
- Bluetooth, Network Client, Camera, Location, Photos
- Keychain access for BLE device identity persistence

### 5. Build & Run

1. Select an iOS 17+ simulator or device
2. Build (⌘B) and Run (⌘R)

## Architecture

```
OceanSentinels/
├── OceanSentinelsApp.swift              # @main entry point
├── Info.plist                            # Permissions & background modes
├── OceanSentinels.entitlements          # Sandbox capabilities
│
├── Domain/                              # Business logic layer
│   ├── Models/                          # Incident, User, Analytics, DomainTypes
│   └── Repositories/                    # Protocol definitions
│
├── Data/                                # Data layer
│   ├── API/                             # NetworkClient, API services
│   ├── DTO/                             # Codable transfer objects
│   ├── Database/                        # SwiftData entities + DatabaseManager
│   ├── Preferences/                     # UserDefaults wrapper
│   └── Repository/                      # Protocol implementations
│
├── DI/                                  # Dependency injection
│   └── DependencyContainer.swift        # Manual DI container
│
├── Config/                              # App config, logging, theme
│   ├── AppConfig.swift
│   ├── AppLogger.swift
│   ├── OceanColors.swift
│   └── OceanTypography.swift
│
├── Mesh/                                # BLE Mesh networking layer
│   ├── Model/                           # MeshMessage, MeshPeer
│   ├── BLE/                             # BleMeshManager, DeviceIdentifier
│   ├── Network/                         # NetworkConnectivityManager
│   ├── Service/                         # MeshBackgroundService
│   └── Repository/                      # MeshMessageRepository
│
└── Presentation/                        # UI layer
    ├── ViewModels/                      # @Observable @MainActor VMs
    ├── Navigation/                      # AppRoute, ContentView, NavigationRouter
    └── UI/
        ├── Components/                  # Reusable UI (Badges, Buttons, Cards, TextFields)
        └── Screens/                     # Feature screens
            ├── Auth/                    # Splash, Login, Register
            ├── Home/                    # HomeScreen
            ├── Incidents/               # Alerts, Detail, Dashboard, MyReports, Report
            ├── Weather/                 # WeatherScreen
            ├── Map/                     # MapScreen (placeholder)
            ├── Mesh/                    # MeshNetworkScreen
            ├── Analytics/               # AnalyticsScreen
            ├── Admin/                   # Console, Dashboard, CreateUser, UserManagement
            ├── Authority/               # AuthorityConsoleScreen
            ├── Rescue/                  # RescueConsoleScreen
            └── Profile/                 # Profile, Settings, TermsConditions
```

## Mesh Networking

The BLE mesh layer implements:
- **PHY Coded (Long Range S=8)** for ~400m range with standard 1M fallback
- **72-hour time-based** message expiry (not hop-based TTL)
- **SHA-256 deterministic** message IDs for deduplication
- **LRU dedup cache** (10K entries)
- **Always-relay-first** strategy — internet delivery + mesh broadcast simultaneously
- **CoreBluetooth** state restoration for background BLE operation
- Max relay path: 255 devices

### iOS BLE Limitations
- Cannot advertise with Coded PHY — uses 1M for advertising, Coded only for connections
- Background execution limited — uses CoreBluetooth background modes + state restoration

## API Backend

Base URL: `https://ocean-hazard-1-6j5g.onrender.com/api`

- Auth: Form-encoded login, token-based
- Incidents: CRUD with status workflow (pending → verified → in_progress → resolved)
- Weather: Dual API (WeatherAPI.com + IndianAPI.in)
- Analytics: Dashboard stats, distribution data

## Key Differences from Android

| Android | iOS |
|---------|-----|
| Jetpack Compose | SwiftUI |
| Hilt DI | Manual DependencyContainer |
| Room Database | SwiftData (@Model + @ModelActor) |
| Retrofit + Gson | URLSession + Codable |
| android.bluetooth | CoreBluetooth |
| Coroutines + Flow | async/await + AsyncStream |
| StateFlow | @Observable + @Published |
| Foreground Service | CoreBluetooth background modes |
| Mapbox Android SDK | MapboxMaps iOS SDK (via SPM) |

## TODOs

- [ ] Integrate MapboxMaps SDK and replace MapScreen placeholder
- [ ] Implement camera/gallery photo capture in ReportIncidentScreen
- [ ] Add Firebase Messaging for push notifications
- [ ] Add Firebase Analytics
- [ ] Implement proper image upload to backend
- [ ] Add unit tests
- [ ] Add UI tests
