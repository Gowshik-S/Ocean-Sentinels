# Ocean Sentinels - iOS Edition

**A native Swift/SwiftUI clone of the Android Ocean Sentinels app for coastal hazard reporting, real-time mapping, and BLE mesh networking on iOS.**

**iOS Version:** 17.0+  
**Swift Version:** 5.9+  
**Xcode Version:** 15.0+  
**Development Status:** In Progress  
**Last Updated:** March 19, 2026

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Features](#features)
3. [Requirements & Prerequisites](#requirements--prerequisites)
4. [Installation & Setup](#installation--setup)
5. [Project Architecture](#project-architecture)
6. [Project Structure](#project-structure)
7. [Key Components](#key-components)
8. [API Integration](#api-integration)
9. [BLE Mesh Networking](#ble-mesh-networking)
10. [Building & Running](#building--running)
11. [Testing](#testing)
12. [Deployment](#deployment)
13. [Troubleshooting](#troubleshooting)
14. [Development Workflow](#development-workflow)
15. [Related Documentation](#related-documentation)

---

## 🌊 Project Overview

**Ocean Sentinels iOS** is a native Swift/SwiftUI application that brings the coastal safety network to Apple devices. This is a direct conversion of the successful Android/Kotlin version, maintaining feature parity while leveraging iOS-native technologies.

### **What is Ocean Sentinels?**

Ocean Sentinels is a real-time coastal hazard reporting and incident management system designed for:
- **Coastal Communities** - Report maritime hazards instantly with GPS and photos
- **Rescue Teams** - Coordinate emergency response and incident verification
- **Authorities** - Monitor, verify, and manage coastal safety operations
- **Administrators** - System oversight and resource management

### **Why iOS?**

- **Native Performance** - Optimized for Apple devices using SwiftUI and CoreBluetooth
- **Feature Parity** - 100% of Android functionality translated to Swift
- **Offline Resilience** - BLE mesh networking for areas with no connectivity
- **Multi-Platform** - Users can switch between iOS and Android seamlessly
- **Modern Swift** - Utilizes latest iOS 17+ capabilities (SwiftUI, SwiftData, async/await)

---

## ✨ Features

### **Core Capabilities**

✅ **Real-Time Incident Reporting**
- Hazard type selection (10+ types)
- GPS-based location capture with map integration
- Photo upload directly from camera or photo library
- Urgency level selection (Low, Medium, High, Critical)
- Incident status tracking (Pending, Verified, In Progress, Resolved, False Alarm)

✅ **Interactive Live Mapping**
- Mapbox GL integration for iOS
- Live incident markers with real-time updates
- Filtering by hazard type, urgency, and status
- Role-based incident visibility
- Zoom, pan, and search capabilities

✅ **Role-Based Dashboards**
- **Public Citizens**: Report incidents, view analytics, check status
- **Authorities**: Verify incidents, deploy resources, view authority analytics
- **Rescue Teams**: View assigned incidents, update status, coordinate response
- **Administrators**: Manage users, monitor system performance, configuration

✅ **Offline BLE Mesh Network**
- Automatic mesh network formation between nearby devices
- Hazard report relay through mesh peers
- Intelligent deduplication (mesh_message_id)
- Automatic backend sync when internet restored
- Background mode support

✅ **Real-Time Notifications**
- Push notifications for incident updates
- Status change alerts
- Assignment & deployment notifications
- Custom notification handling

✅ **Weather Integration**
- Global weather data (WeatherAPI.com)
- India-specific data (Indian Meteorological Department)
- Real-time weather alerts
- Integration with incident severity assessment

✅ **Analytics & Reporting**
- Incident statistics by type, status, urgency
- Time-series trend analysis
- Heatmaps of incident locations
- Response time metrics
- User engagement tracking

✅ **Secure Authentication**
- JWT-based token authentication
- Biometric authentication (Face ID / Touch ID)
- Encrypted credential storage (Keychain)
- Automatic token refresh

---

## 📋 Requirements & Prerequisites

### **System Requirements**

| Requirement | Minimum | Recommended |
|---|---|---|
| iOS Version | 17.0 | 17.5+ |
| Swift Version | 5.9 | 5.10 |
| Xcode | 15.0 | 15.3+ |
| Mac OS (Development) | 13.0 | 14.0+ |
| Device Type | iPhone/iPad | iPhone 12+/iPad Air 2024+ |

### **Development Tools**

- **Xcode 15.0+** - Latest from App Store
- **Command Line Tools** - `xcode-select --install`
- **CocoaPods** (Optional) - For certain dependencies
- **GitHub Account** - To clone the repository

### **Backend Requirements**

- **Ocean Sentinels Backend** - Running at `https://mesh.gowshik.in/`
- **API Version** - 1.0.0 compatible
- **Database** - Remote PostgreSQL (connection handled by backend)

### **Optional Services**

- **Firebase Project** - For push notifications (Cloud Messaging)
- **Mapbox Account** - For map features (public token provided)
- **Swift Package Manager** - Built into Xcode

---

## 🔧 Installation & Setup

### **Step 1: Clone the Repository**

```bash
git clone https://github.com/Gowshik-S/Ocean-Sentinels.git
cd Ocean-Hazard/IOS
```

### **Step 2: Create Xcode Project**

Since this is a Swift package with SwiftUI support, you'll create a native Xcode project:

1. Open **Xcode**
2. File → **New** → **Project**
3. Select **iOS** → **App**
4. Configure project:
   - **Product Name:** `OceanSentinels`
   - **Bundle Identifier:** `com.oceansentinels.app`
   - **Team ID:** Your Apple Developer Team
   - **Interface:** **SwiftUI**
   - **Storage:** **SwiftData**
   - **Language:** **Swift**

### **Step 3: Add Files to Project**

1. In Xcode, right-click on the project navigator
2. Select **Add Files to "OceanSentinels"**
3. Navigate to the cloned repo: `Ocean-Hazard/IOS/OceanSentinels/`
4. Select the entire `OceanSentinels` folder
5. Ensure **Copy items if needed** is unchecked
6. Click **Add**

### **Step 4: Configure Info.plist**

Xcode should automatically use `OceanSentinels/Info.plist`. Verify it includes:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
    <string>bluetooth-peripheral</string>
    <string>location</string>
    <string>remote-notification</string>
</array>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Required for offline mesh networking when internet is unavailable</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Required to capture incident location and provide local weather alerts</string>
<key>NSCameraUsageDescription</key>
<string>Required to capture incident photos as evidence</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Required to attach existing photos to incident reports</string>
```

### **Step 5: Configure Entitlements**

Ensure `OceanSentinels.entitlements` is linked in Xcode:

1. Select project → **OceanSentinels** target
2. Build Settings → Search "Entitlements"
3. Set to: `OceanSentinels/OceanSentinels.entitlements`

The entitlements file should include:
- Bluetooth capabilities (central & peripheral)
- Network client
- Camera
- Location
- Photos
- Keychain groups (for BLE device identity)

### **Step 6: Add Package Dependencies**

1. File → **Add Package Dependencies**
2. Add the following packages:

| Package | URL | Purpose |
|---------|-----|---------|
| Firebase iOS SDK | `https://github.com/firebase/firebase-ios-sdk.git` | Push notifications & analytics |
| Mapbox Maps | `https://github.com/mapbox/mapbox-maps-ios.git` | Interactive mapping |

### **Step 7: Set Minimum Deployment Target**

1. Select project → Build Settings
2. Filter: "Deployment"
3. Set "iOS Deployment Target" to **17.0**

### **Step 8: Configure API Endpoint**

Edit `OceanSentinels/Config/AppConfig.swift`:

```swift
enum AppConfig {
    static let apiBaseURL: String = {
        #if DEBUG
        return "https://mesh.gowshik.in/"  // Update to your backend
        #else
        return "https://mesh.gowshik.in/"
        #endif
    }()
}
```

### **Step 9: Build & Run**

1. Select target device/simulator (iPhone 15+, iOS 17+)
2. Build: **⌘B**
3. Run: **⌘R**

---

## 🏗️ Project Architecture

### **Overall Architecture Pattern**

Ocean Sentinels iOS follows **Clean Architecture** with clear layer separation:

```
┌─────────────────────────────────────────────────────────┐
│               PRESENTATION LAYER (UI)                    │
│         SwiftUI Views + @Observable ViewModels           │
│  (Screens, Components, Navigation, Theme Management)    │
└────────────────────┬────────────────────────────────────┘
                     │ (Data binding via @Observable)
┌────────────────────▼────────────────────────────────────┐
│               DOMAIN LAYER (Business Logic)              │
│    Models, Repositories (Protocols), Use Cases           │
│  (Incident, User, Analytics, Repository Interfaces)    │
└────────────────────┬────────────────────────────────────┘
                     │ (Dependency Inversion via protocols)
┌────────────────────▼────────────────────────────────────┐
│                DATA LAYER (Sources)                      │
│  API, Database, Preferences, Repositories (Impl)        │
│  (Network: URLSession, Async/await)                     │
│  (Local: SwiftData, UserDefaults)                       │
└─────────────────────────────────────────────────────────┘
                     │
    ┌────────────────┼────────────────┐
    ▼                ▼                ▼
 Backend API    SQLite DB     CoreBluetooth
(Ocean-Hazard)  (SwiftData)  (BLE Mesh Network)
```

### **Architecture Decisions**

| Layer | Technologies | Rationale |
|-------|---|---|
| **Presentation** | SwiftUI, @Observable, MVVM | Native iOS, reactive, decoupled |
| **Domain** | Swift enums/structs, Protocols | Type-safe, testable, reusable |
| **Data** | URLSession, SwiftData, Keychain | Native APIs, no external dependencies |
| **Networking** | URLSession + async/await | No Alamofire, native concurrency |
| **Local Storage** | SwiftData (iOS 17+) | Type-safe, modern CoreData replacement |
| **DI** | Manual DependencyContainer | No third-party DI, lightweight |
| **BLE Mesh** | CoreBluetooth | Native iOS, CBCentralManager/CBPeripheralManager |
| **Logging** | os.Logger + OSLog | Built-in, no Timber equivalent needed |

---

## 📁 Project Structure

### **Directory Overview**

```
OceanSentinels/
│
├── 📄 OceanSentinelsApp.swift            # @main entry point with lifespan
├── 📄 Info.plist                         # App metadata & permissions
├── 📄 OceanSentinels.entitlements        # Sandbox capabilities
│
├── 🗂️  Config/                           # App configuration
│   ├── AppConfig.swift                   # API keys, URLs, constants
│   ├── AppLogger.swift                   # Logging utility
│   └── Constants.swift                   # App-wide constants
│
├── 🗂️  Domain/                           # Business logic layer (independent)
│   ├── Models/                           # Value types
│   │   ├── Incident.swift                # Incident domain model
│   │   ├── User.swift                    # User domain model
│   │   └── Analytics.swift               # Analytics domain model
│   │
│   └── Repositories/                     # Interface definitions (protocols)
│       ├── AuthRepository.swift          # Authentication protocol
│       ├── IncidentRepository.swift      # Incident management protocol
│       ├── UserRepository.swift          # User management protocol
│       ├── AnalyticsRepository.swift     # Analytics protocol
│       └── WeatherRepository.swift       # Weather protocol
│
├── 🗂️  Data/                             # Data access layer
│   │
│   ├── Remote/                           # Network layer
│   │   ├── API/
│   │   │   ├── NetworkClient.swift       # URLSession wrapper + interceptors
│   │   │   ├── OceanSentinelsAPI.swift   # Main API service
│   │   │   ├── WeatherAPI.swift          # WeatherAPI.com integration
│   │   │   └── IndianWeatherAPI.swift    # Indian Meteorological Dept
│   │   │
│   │   └── DTO/                          # Codable data transfer objects
│   │       ├── IncidentDTO.swift         # Incident DTO for serialization
│   │       ├── UserDTO.swift             # User DTO
│   │       ├── WeatherDTO.swift          # Weather DTO
│   │       ├── IndianWeatherDTO.swift    # Indian weather DTO
│   │       └── AnalyticsDTO.swift        # Analytics DTO
│   │
│   ├── Local/                            # Local storage layer
│   │   ├── Database/
│   │   │   ├── OceanSentinelsStore.swift # SwiftData container & migrations
│   │   │   ├── IncidentEntity.swift      # Incident @Model (persistence)
│   │   │   ├── UserEntity.swift          # User @Model
│   │   │   └── MeshMessageEntity.swift   # Mesh message @Model
│   │   │
│   │   └── Preferences/
│   │       └── PreferencesManager.swift  # UserDefaults wrapper
│   │
│   ├── Repository/                       # Repository implementations
│   │   ├── AuthRepositoryImpl.swift       # Concrete auth (API + local)
│   │   ├── IncidentRepositoryImpl.swift   # Concrete incidents (API + DB)
│   │   ├── UserRepositoryImpl.swift       # Concrete users (API + pref)
│   │   ├── AnalyticsRepositoryImpl.swift  # Concrete analytics (API + cache)
│   │   └── WeatherRepositoryImpl.swift    # Concrete weather (multi-source)
│   │
│   └── Service/                          # Platform services
│       └── PushNotificationService.swift # APNs handling
│
├── 🗂️  DI/                               # Dependency injection container
│   └── DependencyContainer.swift         # Manual DI factory pattern
│
├── 🗂️  Mesh/                             # BLE Mesh networking layer
│   │
│   ├── BLE/                              # Bluetooth Low Energy
│   │   ├── BleMeshManager.swift          # CBCentralManager + CBPeripheralManager
│   │   │                                  # Coded PHY, mesh relay, peer discovery
│   │   └── DeviceIdentifier.swift        # Unique device ID (Keychain-backed)
│   │
│   ├── Model/                            # Data models
│   │   ├── MeshMessage.swift             # Message structure for relay
│   │   └── MeshPeer.swift                # Connected peer metadata
│   │
│   ├── Network/                          # Connectivity monitoring
│   │   └── NetworkConnectivityManager.swift # NWPathMonitor (internet check)
│   │
│   ├── Repository/                       # Mesh-specific storage
│   │   └── MeshMessageRepository.swift   # SwiftData queries for mesh messages
│   │
│   └── Service/                          # Background mesh service
│       └── MeshBackgroundService.swift   # BGTaskScheduler, background modes
│
├── 🗂️  Presentation/                     # UI layer (SwiftUI)
│   │
│   ├── Navigation/                       # Routing & navigation
│   │   ├── AppRoute.swift                # Route enum (all screens)
│   │   ├── AppNavigator.swift            # NavigationStack routing logic
│   │   └── ContentView.swift             # Root app view
│   │
│   ├── ViewModels/                       # @Observable state managers
│   │   ├── AuthViewModel.swift           # Login/Register/Token state
│   │   ├── IncidentViewModel.swift       # Incident CRUD & filtering
│   │   ├── AdminViewModel.swift          # Admin dashboard state
│   │   ├── AnalyticsViewModel.swift      # Analytics data & charts
│   │   ├── MeshViewModel.swift           # Mesh network state & peers
│   │   ├── WeatherViewModel.swift        # Weather data & alerts
│   │   └── ThemeViewModel.swift          # Theme & appearance state
│   │
│   ├── UI/                               # SwiftUI components & screens
│   │   ├── Components/                   # Reusable UI components
│   │   │   ├── Badges.swift              # Status/urgency badges
│   │   │   ├── Buttons.swift             # Custom button styles
│   │   │   ├── Cards.swift               # Incident/user cards
│   │   │   ├── TextFields.swift          # Custom input fields
│   │   │   ├── LoadingView.swift         # Loading spinner
│   │   │   └── AlertModifier.swift       # Error/success alerts
│   │   │
│   │   └── Screens/                      # Feature screens
│   │       ├── Auth/
│   │       │   ├── SplashView.swift      # App splash/loading screen
│   │       │   ├── LoginView.swift       # Login with JWT
│   │       │   └── RegisterView.swift    # User registration
│   │       │
│   │       ├── Home/
│   │       │   └── HomeView.swift        # Home/dashboard screen
│   │       │
│   │       ├── Incidents/
│   │       │   ├── AlertsView.swift      # Incident alerts/list
│   │       │   ├── IncidentDetailView.swift # Incident details
│   │       │   ├── IncidentsDashboardView.swift # Role-based dashboard
│   │       │   ├── MyReportsView.swift   # User's own reports
│   │       │   └── ReportIncidentView.swift # Create new incident
│   │       │
│   │       ├── Map/
│   │       │   └── MapView.swift         # Mapbox interactive map
│   │       │
│   │       ├── Weather/
│   │       │   └── WeatherView.swift     # Weather display & alerts
│   │       │
│   │       ├── Mesh/
│   │       │   └── MeshNetworkView.swift # Mesh peer status
│   │       │
│   │       ├── Analytics/
│   │       │   └── AnalyticsView.swift   # Charts & statistics
│   │       │
│   │       ├── Admin/
│   │       │   ├── AdminConsoleView.swift # Admin main console
│   │       │   ├── AdminDashboardView.swift # System monitoring
│   │       │   ├── CreateUserViews.swift # User creation screens
│   │       │   └── UserManagementView.swift # User CRUD
│   │       │
│   │       ├── Authority/
│   │       │   └── AuthorityConsoleView.swift # Authority dashboard
│   │       │
│   │       ├── Rescue/
│   │       │   └── RescueConsoleView.swift # Rescue team console
│   │       │
│   │       └── Profile/
│   │           ├── ProfileView.swift     # User profile
│   │           └── TermsConditionsView.swift # T&C
│   │
│   └── Views/                            # Theme & styling
│       ├── Theme/
│       │   ├── OceanColors.swift         # Color palette
│       │   ├── OceanTypography.swift     # Font styles
│       │   └── OceanTheme.swift          # Theme environment
│       │
│       └── Modifiers/
│           └── ViewModifiers.swift       # Reusable SwiftUI modifiers
│
├── 🗂️  Utils/                            # Utility functions & helpers
│   ├── AppLogger.swift                   # Logging with os.Logger
│   ├── PlatformCompat.swift              # iOS-specific compatibility
│   ├── Extensions.swift                  # String, Date, URL extensions
│   └── Constants.swift                   # App-wide constants
│
└── 📂 Resources/                         # App resources (Assets, Fonts, etc.)
    ├── Assets.xcassets                   # Images, colors, app icons
    ├── Fonts/                            # Custom fonts (if any)
    └── Localization/                     # Strings files (i18n)
```

---

## 🔨 Key Components

### **1. Authentication System**

**Location:** `Data/Remote/API/OceanSentinelsAPI.swift` + `ViewModels/AuthViewModel.swift`

**Features:**
- JWT token-based authentication
- Login and registration endpoints
- Biometric auth (Face ID / Touch ID)
- Automatic token refresh
- Secure Keychain storage

**Usage:**
```swift
// In AuthViewModel
@Observable
class AuthViewModel {
    @MainActor
    func login(username: String, password: String) {
        // Calls API, stores token in Keychain
        // Updates @Published state
    }
}
```

### **2. Incident Management**

**Location:** `Data/Repository/IncidentRepositoryImpl.swift` + `ViewModels/IncidentViewModel.swift`

**Features:**
- Create, read, update incidents
- Status transitions (Pending → Verified → In Progress → Resolved)
- Hazard type classification (10+ types)
- Urgency levels (Low, Medium, High, Critical)
- Photo upload to S3

**Usage:**
```swift
// In IncidentViewModel
let incidents = try await repository.fetchIncidents(status: .pending)
try await repository.createIncident(incident, photoData: data)
```

### **3. BLE Mesh Network**

**Location:** `Mesh/BLE/BleMeshManager.swift`

**Features:**
- CBCentralManager for scanning peers
- CBPeripheralManager for broadcasting
- Coded PHY support (long range)
- Automatic message relay
- Offload when internet restored

**Architecture:**
```
┌─────────────┐
│   Device A  │ ──BLE──→ [Mesh Relay] ──BLE──→ Device C (with internet)
│  (Offline)  │                                ↓
└─────────────┘                          Backend API
                                         (sync reports)
```

### **4. Real-Time Notifications**

**Location:** `Data/Service/PushNotificationService.swift`

**Features:**
- APNs registration
- Firebase Cloud Messaging integration
- Custom notification handling
- Silent notifications for background sync

### **5. Analytics Engine**

**Location:** `ViewModels/AnalyticsViewModel.swift` + `Data/Repository/AnalyticsRepositoryImpl.swift`

**Features:**
- Real-time incident statistics
- Trend analysis
- Heatmap data generation
- Response time metrics

### **6. Weather Integration**

**Location:** `Data/Remote/API/WeatherAPI.swift` + `IndianWeatherAPI.swift`

**Features:**
- Global weather (WeatherAPI.com)
- India-specific data (IMD)
- Real-time alerts
- Severity assessment

---

## 🌐 API Integration

### **Base Configuration**

```swift
// In AppConfig.swift
static let apiBaseURL = "https://mesh.gowshik.in/"
```

### **Key Endpoints**

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/auth/login` | POST | User authentication |
| `/auth/register` | POST | User registration |
| `/incidents/` | GET/POST | Incident CRUD |
| `/incidents/{id}` | PUT/DELETE | Update/delete incident |
| `/incidents/{id}/verify` | POST | Verify incident |
| `/analytics/dashboard` | GET | Dashboard statistics |
| `/ws/{user_id}` | WS | Real-time updates |

### **Authentication**

All authenticated endpoints require JWT token in header:

```swift
Authorization: Bearer {jwt_token}
```

The token is automatically managed by `NetworkClient.swift`:

```swift
// Interceptor automatically adds token
var request = URLRequest(url: url)
request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
```

### **Error Handling**

```swift
do {
    let result = try await api.fetchIncidents()
    // Success
} catch let error as NetworkError {
    switch error {
    case .unauthorized:
        // Token expired, refresh
    case .notFound:
        // Resource not found
    case .serverError:
        // 5xx error
    default:
        // Other errors
    }
}
```

---

## 🔗 BLE Mesh Networking

### **Offline Resilience Strategy**

When internet is unavailable, the iOS app:

1. **Detects connectivity loss** via `NetworkConnectivityManager`
2. **Activates BLE mesh mode** in `BleMeshManager`
3. **Advertises as CBPeripheral** with app-specific service UUID
4. **Scans for nearby CBCentrals** (other devices, peers)
5. **Relays messages** between peers until internet-connected peer found
6. **Syncs to backend** when internet restored

### **Architecture**

```swift
// BleMeshManager coordinates BLE state machine
class BleMeshManager: NSObject, CBCentralManagerDelegate, CBPeripheralManagerDelegate {
    
    // Scanning/advertising state
    func startScanning()      // Discover mesh peers
    func startAdvertising()   // Broadcast identity
    func relayMessage(_:)     // Forward message to next peer
    
    // Peripheral delegates handle connection lifecycle
}
```

### **Message Flow**

```
Device A (no internet)
    ↓
[Create Incident Report]
    ↓
Try remote sync → ❌ No Internet
    ↓
Save locally + start BLE scan
    ↓
Find Device B (peer, also offline)
    ↓
Send via BLE → Device B forwards to Device C
    ↓
Device C (has internet)
    ↓
Relay to backend
    ↓
Once Device A online: pull from DB and sync
```

### **Background Mode**

Configured in `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
    <string>bluetooth-peripheral</string>
    <string>location</string>
    <string>remote-notification</string>
</array>
```

Managed by `MeshBackgroundService.swift` using `BGTaskScheduler`.

---

## 🏗️ Building & Running

### **Build for Simulator**

```bash
# In Xcode
Command + B  # Build
Command + R  # Run (current simulator)
```

Or via CLI:

```bash
xcodebuild -scheme OceanSentinels -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15'
```

### **Build for Device**

1. Connect iPhone via USB
2. Select device in Xcode: `OceanSentinels` → Device
3. **⌘R** to build and run
4. Trust developer certificate on device: Settings → General → Device Management

### **Build Release**

```bash
xcodebuild -scheme OceanSentinels -configuration Release -destination generic/platform=iOS
```

### **Set Active Scheme**

Xcode should detect `OceanSentinels` automatically. If not:

```
Xcode → Product → Scheme → OceanSentinels
```

### **Troubleshooting Build**

- **Clean build folder:** `⌘⇧K`
- **Delete derived data:** `~/Library/Developer/Xcode/DerivedData/`
- **Reset package cache:** File → Packages → Reset Package Caches

---

## 🧪 Testing

### **Unit Tests**

Testing coverage for ViewModels and Repositories:

```bash
# In Xcode
⌘U  # Run tests
```

### **Manual Testing**

**Authentication Flow:**
1. Launch app → Splash screen
2. Tap "Sign Up" → RegisterView
3. Enter credentials, create account
4. Login with new account
5. Verify JWT stored in Keychain

**Incident Reporting:**
1. Logged in → Home screen
2. Tap "Report Incident" button
3. Select hazard type, location, urgency
4. Capture photo (simulator: use mock)
5. Submit → Verify incident appears in list

**BLE Mesh (Simulator Limitation):**
- True BLE mesh testing requires 2+ physical devices
- Simulator shows mock mesh state
- Test with real devices for production validation

**Role-Based Navigation:**
1. Create users with different roles
2. Login as each role
3. Verify dashboard shows role-specific screens

### **Test Data**

Test credentials (from backend):

```
Username: admin
Password: admin123
Role: admin
```

Additional test users can be created via Admin console.

---

## 📦 Deployment

### **App Store Submission**

1. **Create App ID in Apple Developer**
   - App Name: Ocean Sentinels
   - Bundle ID: com.oceansentinels.app
   - SKU: OS2024

2. **Create Certificates & Provisioning Profiles**
   - Development certificate (for testing)
   - Distribution certificate (App Store)

3. **Configure in Xcode**
   - Project Settings → Signing & Capabilities
   - Team: Your Apple Developer Team
   - Provisioning Profile: Automatic

4. **Build for Archive**
   ```bash
   Product → Archive
   ```

5. **Upload to App Store Connect**
   - Select archive in Organizer
   - Click "Distribute App"
   - Follow App Store Connect flow

6. **Complete App Store Metadata**
   - Screenshots (6 per version)
   - Description
   - Keywords
   - Category: Utilities / Reference
   - Support URL
   - Privacy Policy

### **TestFlight Distribution**

For beta testing:

```
Organizer → Select Archive → Distribute App → TestFlight
```

Then invite testers via TestFlight app.

### **Environment Configuration**

For production deployment, update `AppConfig.swift`:

```swift
static let apiBaseURL: String = {
    #if DEBUG
    return "https://dev-api.oceansentinels.com/"
    #else
    return "https://api.oceansentinels.com/"  // Production
    #endif
}()
```

---

## 🐛 Troubleshooting

### **Build Issues**

| Issue | Solution |
|-------|----------|
| **"OceanSentinelsApp: No such module"** | Ensure all files from `OceanSentinels/` folder added to project |
| **Xcode can't find Info.plist** | Build Settings → INFOPLIST_FILE = `OceanSentinels/Info.plist` |
| **Swift version mismatch** | Update Xcode to 15.0+ |
| **Package resolution fails** | File → Packages → Reset Package Caches |
| **"Entitlements not found"** | Verify `OceanSentinels.entitlements` in Build Settings |

### **Runtime Issues**

| Issue | Solution |
|-------|----------|
| **App crashes on launch** | Check console: Device → Logs (Xcode) |
| **"Unauthorized" on API calls** | JWT token expired; logout and login again |
| **BLE fails on simulator** | BLE only works on physical devices |
| **Photos not loading** | Check camera permissions: Settings → Privacy → Camera |
| **Mapbox blank/white** | Verify `MAPBOX_ACCESS_TOKEN` in Info.plist |
| **"Codable" decode error** | Check API response structure matches DTO models |

### **Networking Issues**

| Issue | Solution |
|-------|----------|
| **"Cannot reach server"** | Verify backend running at `apiBaseURL` |
| **Timeout errors** | Increase timeout in `NetworkClient.swift` (default 30s) |
| **Certificate validation fails** | For dev: temporarily disable in `NetworkClient` (**NOT for production!**) |
| **CORS errors** | Backend should have CORS enabled for `https://localhost` |

### **Permission Issues**

| Issue | Solution |
|-------|----------|
| **Camera not working** | Grant permission: Settings → Privacy → Camera |
| **Location not found** | Grant permission: Settings → Privacy → Location |
| **Bluetooth fails** | Grant permission: Settings → Privacy → Bluetooth |
| **Photos can't be selected** | Grant permission: Settings → Privacy → Photos |

---

## 💻 Development Workflow

### **Adding a New Feature**

1. **Create ViewModel** (Presentation layer)
   ```swift
   @Observable
   @MainActor
   class NewFeatureViewModel {
       // State
       var items: [Item] = []
       
       // Actions
       func fetchItems() async { }
   }
   ```

2. **Create Repository Protocol** (Domain layer)
   ```swift
   protocol NewItemRepository {
       func fetchItems() async throws -> [Item]
   }
   ```

3. **Implement Repository** (Data layer)
   ```swift
   final class NewItemRepositoryImpl: NewItemRepository {
       func fetchItems() async throws -> [Item] {
           let dtos = try await api.fetchItems()
           return dtos.map { $0.toDomain() }
       }
   }
   ```

4. **Add API Endpoint** (Data layer)
   ```swift
   // In OceanSentinelsAPI
   func fetchItems() async throws -> [ItemDTO]
   ```

5. **Create SwiftUI View** (Presentation layer)
   ```swift
   struct NewFeatureView: View {
       @State var viewModel = NewFeatureViewModel()
       
       var body: some View {
           List(viewModel.items) { item in
               ItemRow(item: item)
           }
       }
   }
   ```

6. **Update Navigation** (if new screen)
   ```swift
   // In AppRoute
   case newFeature(id: String)
   ```

### **Code Standards**

- **Swift Naming:** Follows Swift API Design Guidelines
- **Folder Structure:** Mirror Domain/Data/Presentation organization
- **Type Safety:** Leverage Swift's strong type system
- **Error Handling:** Use `Result<T, Error>` or `async throws`
- **Concurrency:** Use `async/await`, avoid `DispatchQueue`
- **Documentation:** Doc comments for public APIs (`/// Description`)

### **Git Workflow**

```bash
# Create feature branch
git checkout -b feature/incident-map-filter

# Make changes, commit
git add .
git commit -m "fix: add map filtering by hazard type"

# Push to GitHub
git push origin feature/incident-map-filter

# Create Pull Request on GitHub
```

### **Code Review**

Before merging:
- ✅ Peer review (2+ reviewers)
- ✅ All tests pass
- ✅ No console warnings
- ✅ Architecture patterns followed
- ✅ Documentation updated

---

## 📚 Related Documentation

### **Within This Project**

- [CONVERSION_PLAN.md](CONVERSION_PLAN.md) - Detailed Android → iOS mapping
- [tasks/todo.md](tasks/todo.md) - Development TODOs
- [tasks/lessons.md](tasks/lessons.md) - Lessons learned during conversion
- [README.md](README.md) - Original iOS setup guide
- [Package.swift](Package.swift) - Swift Package configuration

### **Parent Project Docs**

- [Ocean-Hazard/COMPREHENSIVE_README.md](../COMPREHENSIVE_README.md) - Full project overview
- [Ocean-Hazard/context.txt](../context.txt) - Project memory/reference
- [Ocean-Hazard/docs/](../docs/) - Deployment, testing, architecture guides

### **Android Reference**

- [Ocean-Hazard/android_app/README.md](../android_app/README.md) - Android app docs
- [Ocean-Hazard/android_app/BLE_MESH_INTEGRATION.md](../android_app/BLE_MESH_INTEGRATION.md) - BLE mesh design
- [Ocean-Hazard/android_app/AUDIT_REPORT.md](../android_app/AUDIT_REPORT.md) - Code audit

### **External References**

- [Apple SwiftUI Documentation](https://developer.apple.com/xcode/swiftui/)
- [Swift Concurrency (async/await)](https://developer.apple.com/videos/play/wwdc2021/10132/)
- [CoreBluetooth Framework](https://developer.apple.com/documentation/corebluetooth)
- [SwiftData Documentation](https://developer.apple.com/xcode/swiftdata/)
- [URLSession Documentation](https://developer.apple.com/documentation/foundation/urlsession)
- [Mapbox Maps SDK for iOS](https://docs.mapbox.com/ios/)

---

## 📞 Support & Resources

### **Team**

- **Project Lead:** Gowshik S
- **Backend Server:** mesh.gowshik.in
- **Figma Design:** [Ocean Sentinels Design](https://www.figma.com/design/DEwUbt4grKJtDaB0OBRp1v/Ocean-Sentinels)

### **Communication**

- **Issues:** GitHub Issues on this repository
- **Discussions:** GitHub Discussions
- **Quick Help:** README and documentation files

### **Getting Help**

1. **Check existing documentation** first (this README, CONVERSION_PLAN.md)
2. **Search GitHub issues** for similar problems
3. **Check Stack Overflow** for Swift/SwiftUI questions
4. **File GitHub issue** with:
   - Steps to reproduce
   - Error messages/logs
   - Device/iOS version
   - Xcode version

---

## 📄 License

This project is licensed under the same license as Ocean-Hazard parent project. See [LICENSE](../LICENSE) in the root directory.

---

## ✅ Current Status (March 2026)

| Component | Status | Notes |
|-----------|--------|-------|
| Project Setup | ✅ Complete | Xcode project structure ready |
| Architecture | ✅ Complete | Clean Architecture implemented |
| Authentication | ✅ Complete | JWT + Biometric ready |
| Incident Management | ✅ Complete | Full CRUD implemented |
| BLE Mesh Networking | ✅ Complete | CoreBluetooth integration done |
| Mapping | 🟡 In Progress | Mapbox SDK integrated, UI pending |
| Notifications | 🟡 In Progress | APNs setup ready, Firebase pending |
| Weather Integration | 🟡 In Progress | API endpoints configured, UI pending |
| Analytics | 🟡 In Progress | Data layer complete, Charts pending |
| UI Screens | 🟡 In Progress | 60% of screens implemented |
| Testing | 🟡 Started | Basic unit tests in place |
| App Store | ❌ Not Ready | Metadata & screenshots needed |

---

**Last Updated:** March 19, 2026  
**Swift Version:** 5.9+  
**iOS Deployment Target:** 17.0+  
**Xcode Version:** 15.0+
