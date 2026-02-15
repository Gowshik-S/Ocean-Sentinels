# BLE Mesh Networking Integration

## Overview

The Ocean-Hazard Android app now includes a **BLE Mesh Network** layer that enables offline hazard reporting. When users lack internet connectivity, reports are relayed via Bluetooth Low Energy (BLE) mesh to nearby devices until one with internet access uploads the report to the server.

## Architecture

### Delivery Fallback Chain

```
Internet API → BLE PHY Coded (Long Range ~400m) → BLE Standard (1M ~100m) → Local Queue
```

1. **Internet** — Report goes directly to the Ocean Sentinels server via REST API
2. **BLE PHY Coded** — If no internet, broadcasts to nearby devices using Long Range PHY (S=8 coding, 125kbps, ~400m range). Requires Android 8.0+ and device hardware support.
3. **BLE Standard** — Falls back to standard BLE 1M PHY (~100m range) if Coded PHY unsupported
4. **Local Queue** — If no peers available, stored in Room DB and auto-flushed when internet or peers appear

### Recursive Relay

If User A has no internet, the report goes to User B via mesh. If User B also lacks internet, B relays to User C, and so on recursively until a device with internet uploads it. The message includes a **TTL of 7 hops** to prevent infinite relay and a **relay path** to prevent loops.

### Anti-Spam / Deduplication

Each message has a **deterministic unique ID** generated via:
```
SHA-256(deviceMAC | timestamp | hazardType | latitude | longitude | description) → first 32 hex chars
```
This ensures:
- Same report from same device produces the same ID
- Relaying devices can detect and reject duplicates
- In-memory set (max 10,000 IDs) + DB-level unique constraint for dedup

## File Structure

### New Files Created

| File | Purpose |
|------|---------|
| `mesh/model/MeshMessage.kt` | Core message data class with unique ID generation, TTL, relay path, JSON serialization |
| `mesh/model/MeshPeer.kt` | BLE peer representation + `MeshNetworkStatus` status class |
| `mesh/ble/BleMeshManager.kt` | Core BLE manager: dual advertising (Coded + legacy), GATT server/client, scanning, connection management |
| `mesh/service/MeshForegroundService.kt` | Android foreground service for background BLE mesh, internet monitoring, queue processing |
| `mesh/repository/MeshMessageRepository.kt` | Repository with Internet→Mesh→Queue fallback delivery strategy |
| `data/local/database/entity/MeshMessageEntity.kt` | Room entity for persistent mesh message queue with priority ordering |
| `data/local/database/dao/MeshMessageDao.kt` | Comprehensive DAO with priority-ordered queries, dedup, expiry management |
| `presentation/viewmodel/MeshViewModel.kt` | ViewModel for mesh UI state management |
| `presentation/ui/screens/mesh/MeshNetworkScreen.kt` | Full Compose UI: status banner, tabbed message views, hazard report form, peer info |
| `di/MeshModule.kt` | Hilt DI module providing `BleMeshManager` and `MeshMessageRepository` |

### Modified Files

| File | Changes |
|------|---------|
| `OceanSentinelsDatabase.kt` | Added `MeshMessageEntity` to entities, bumped version to 3, added `meshMessageDao()` |
| `DatabaseModule.kt` | Added `provideMeshMessageDao()` |
| `Screen.kt` | Added `MeshNetwork` route |
| `OceanNavHost.kt` | Added MeshNetworkScreen composable route + import |
| `BottomNavBar.kt` | Added "Mesh" tab with `Hub` icon, `onNavigateToMesh` parameter |
| `HomeScreen.kt` | Added `onNavigateToMesh` parameter, passed to bottom nav bar |
| `AndroidManifest.xml` | Added BLE permissions, foreground service permissions, service declaration, BLE feature |
| `OceanSentinelsApp.kt` | Added mesh notification channel (`ocean_mesh_service`) |

## BLE Implementation Details

### UUIDs
- **Service UUID**: `A1C3E5F7-2B4D-6E8F-9A0B-1C2D3E4F5A6B`
- **Characteristic UUID**: `B2D4F608-3C5E-7F90-AB1C-2D3E4F5061C7`

### Dual Advertising
1. **Coded PHY** — Extended, non-legacy, non-scannable connectable advertising using `AdvertisingSetCallback`. Uses S=8 coding for maximum range.
2. **Legacy 1M PHY** — Standard BLE advertising for backward compatibility with older devices.

### Scanning
- Uses `setLegacy(false)` + `PHY_LE_ALL_SUPPORTED` to discover both Coded and standard advertisements
- 30-second scan restart interval
- 180-second peer stale timeout

### Connection Management
- Max 7 concurrent connections (BLE spec limit)
- PHY upgrade negotiation via `setPreferredPhy(PHY_LE_CODED, PHY_LE_CODED, PHY_OPTION_S8)`
- Auto-reconnection on disconnect

### Message Protocol
- Messages serialized as compact JSON
- Transmitted via GATT characteristic writes
- Chunking support for messages exceeding MTU (20 bytes default, negotiate up to 512)

## Database Schema

### `mesh_messages` Table (v3)

| Column | Type | Notes |
|--------|------|-------|
| `local_id` | INTEGER | Primary key, auto-generated |
| `message_id` | TEXT | Unique deterministic SHA-256 ID |
| `origin_device_mac` | TEXT | Indexed |
| `origin_device_fingerprint` | TEXT | MAC + Android ID |
| `hazard_type` | TEXT | Matches `HazardType` enum values |
| `location` | TEXT | Free-text location |
| `latitude` / `longitude` | REAL | Nullable GPS coordinates |
| `description` | TEXT | Hazard description |
| `urgency` | TEXT | low/medium/high/critical |
| `status` | TEXT | pending/sending/relayed/delivered/failed |
| `ttl` | INTEGER | Remaining hops (default 7) |
| `hop_count` | INTEGER | Hops taken so far |
| `relay_path` | TEXT | Comma-separated MAC addresses |
| `retry_count` | INTEGER | Delivery attempts |
| `max_retries` | INTEGER | Default 10 |
| `expires_at` | TEXT | 24-hour expiry |
| `is_own_message` | INTEGER | 1 if originated from this device |
| `has_been_relayed` | INTEGER | 1 if relayed to other peers |
| `transport_used` | TEXT | internet/ble_coded/ble_standard/local_queue |

### Priority Ordering
Messages are processed in priority order: `critical → high → medium → low`

### Limits
- Max 500 messages in local DB (FIFO trimming)
- 24-hour message expiry
- 10 retry attempts before marking as failed

## UI Features

The Mesh Network screen (`/mesh_network` route) includes:

1. **Status Banner** — Shows mesh active/inactive, PHY type (Coded/Standard), peer count, message stats
2. **Permission Request** — BLE permission grant flow (Android 12+ granular permissions)
3. **Quick Report Form** — Hazard type dropdown, urgency, lat/lng, description with "Send via Mesh" button
4. **Tabbed Message View**:
   - **Queue** — Pending messages awaiting delivery
   - **Delivered** — Successfully uploaded to server
   - **Relayed** — Messages forwarded from other users
   - **Peers** — Connected BLE devices info
5. **Send State Banner** — Shows transport used (Internet/BLE Coded/BLE Standard/Local Queue)
6. **Auto-flush** — When internet becomes available, all queued messages are automatically sent to server

## Permissions

### Added to AndroidManifest.xml
```xml
<!-- BLE Mesh (Android 12+) -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- BLE Mesh (Legacy, Android 11 and below) -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />

<!-- Foreground Service -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE" />

<!-- Feature declaration (not required) -->
<uses-feature android:name="android.hardware.bluetooth_le" android:required="false" />
```

## Design Decisions

1. **Custom BLE Mesh** (BitChat-inspired) over Bridgefy SDK — avoids commercial dependency, full control
2. **Dual Advertising** — Coded PHY for range + Legacy for compatibility 
3. **Room DB** over in-memory — persistence across app restarts, crash resilience
4. **Deterministic IDs** — SHA-256 prevents spam without requiring centralized dedup
5. **Foreground Service** — Required for background BLE operations on Android 8+
6. **Priority Queue** — Critical hazards processed before lower-urgency items
