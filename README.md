<p align="center">
  <img src="assets/images/gov_of_india.png" alt="Ocean Sentinels" width="120"/>
</p>

<h1 align="center">Ocean Sentinels</h1>

<p align="center">
  <strong>Open-Source Coastal Safety Infrastructure for Communities Worldwide</strong>
</p>

<p align="center">
  Real-time maritime hazard reporting · BLE mesh networking · Offline-first disaster resilience
</p>

<p align="center">
  <a href="https://sih.gowshik.in"><img src="https://img.shields.io/badge/Web%20App-Live-0ea5e9?style=for-the-badge&logo=googlechrome&logoColor=white" alt="Web App"/></a>&nbsp;
  <a href="https://ocean-sentinels.s3.ap-south-1.amazonaws.com/Ocean-Sentinels.V1.1.apk"><img src="https://img.shields.io/badge/Android-Download%20APK-34a853?style=for-the-badge&logo=android&logoColor=white" alt="Android APK"/></a>&nbsp;
  <img src="https://img.shields.io/badge/iOS-Coming%20Soon-999?style=for-the-badge&logo=apple&logoColor=white" alt="iOS"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Python-3.11-3776AB?logo=python&logoColor=white" alt="Python"/>
  <img src="https://img.shields.io/badge/FastAPI-0.100+-009688?logo=fastapi&logoColor=white" alt="FastAPI"/>
  <img src="https://img.shields.io/badge/Kotlin-2.0-7F52FF?logo=kotlin&logoColor=white" alt="Kotlin"/>
  <img src="https://img.shields.io/badge/Jetpack%20Compose-Material3-4285F4?logo=jetpackcompose&logoColor=white" alt="Compose"/>
  <img src="https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white" alt="Swift"/>
  <img src="https://img.shields.io/badge/SwiftUI-iOS%2017+-000?logo=apple&logoColor=white" alt="SwiftUI"/>
  <img src="https://img.shields.io/badge/BLE%20Mesh-Custom%20Protocol-blue" alt="BLE Mesh"/>
  <img src="https://img.shields.io/badge/License-Apache%202.0-blue" alt="License"/>
</p>

---

## Table of Contents

- [The Problem](#the-problem)
- [What Ocean Sentinels Does](#what-ocean-sentinels-does)
- [Architecture](#architecture)
- [BLE Mesh Network — Offline Disaster Resilience](#ble-mesh-network--offline-disaster-resilience)
- [Platform Overview](#platform-overview)
- [Role-Based Access Control](#role-based-access-control)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Backend API](#backend-api)
- [Database Schema](#database-schema)
- [Getting Started](#getting-started)
- [Environment Variables](#environment-variables)
- [Contributing](#contributing)
- [License](#license)

---

## The Problem

Coastal communities face a critical safety gap. When cyclones, tsunamis, or severe weather hit, the very infrastructure needed to report hazards and coordinate rescue — cell towers, internet, power grids — is the first to go down. Fishermen at sea, coastal villages, and port workers are left disconnected at the exact moment they need help most.

Existing emergency systems require internet connectivity. They fail precisely when they're needed most.

---

## What Ocean Sentinels Does

Ocean Sentinels is a **full-stack coastal safety platform** that keeps communities connected even when disasters destroy telecommunications infrastructure. It combines a traditional web-and-mobile hazard reporting system with a **custom Bluetooth Low Energy (BLE) mesh network** that lets devices relay emergency reports to each other — phone to phone — until one with internet access can upload the report to authorities.

**Core capabilities:**

- **Real-time incident reporting** — GPS-located hazard reports with photo evidence across 10 hazard types
- **BLE mesh relay network** — Offline hazard report propagation between Android devices using Coded PHY (~400m range)
- **Role-based response coordination** — Dedicated consoles for citizens, coastal authorities, rescue teams, and administrators
- **Live situational awareness** — Interactive Mapbox maps, WebSocket-driven real-time dashboards, and analytics
- **Weather integration** — Live weather data and alerts from WeatherAPI.com + India Meteorological Department
- **Cross-platform** — Web app, native Android (Kotlin/Compose), and iOS (Swift/SwiftUI, in development)

---

## Architecture

```
┌──────────────────┐  ┌─────────────────────┐  ┌──────────────────┐
│   WEB FRONTEND   │  │    ANDROID APP      │  │     iOS APP      │
│                  │  │                     │  │                  │
│  Vanilla JS/ES6+ │  │  Kotlin / Compose   │  │  Swift / SwiftUI │
│  Mapbox GL JS    │  │  Hilt DI / Room DB  │  │  SwiftData       │
│  WebSocket       │  │  BLE Mesh Layer     │  │  CoreBluetooth   │
│  11 Pages        │  │  20+ Screens        │  │  20+ Screens     │
└────────┬─────────┘  └─────┬──────┬────────┘  └────────┬─────────┘
         │                  │      │                     │
    HTTPS + WSS        HTTPS + FCM │ BLE Radio      HTTPS + APNS
         │                  │      │ (Coded PHY)         │
         └──────────┬───────┘      │                     │
                    ▼              ▼                     │
┌───────────────────────────────────────────────────────────────────┐
│                     FASTAPI BACKEND                               │
│              Python 3.11 · SQLAlchemy 2.0 · Async I/O             │
│                                                                   │
│  ┌────────┐ ┌───────────┐ ┌─────────┐ ┌───────────┐ ┌─────────┐ │
│  │  Auth  │ │ Incidents │ │  Users  │ │ WebSocket │ │Analytics│ │
│  │  JWT + │ │ CRUD +    │ │ RBAC    │ │ Role-     │ │ Metrics │ │
│  │ bcrypt │ │ Mesh      │ │ 4 Roles │ │ Filtered  │ │ + Stats │ │
│  │        │ │ Dedup     │ │         │ │ Broadcast │ │         │ │
│  └────────┘ └───────────┘ └─────────┘ └───────────┘ └─────────┘ │
└────┬────────────┬────────────┬────────────┬───────────────┬───────┘
     ▼            ▼            ▼            ▼               ▼
┌──────────┐ ┌────────┐ ┌─────────┐ ┌──────────┐ ┌─────────────────┐
│PostgreSQL│ │ Redis  │ │ AWS S3  │ │  Mapbox  │ │  Weather APIs   │
│ Primary  │ │ Cache  │ │ Photos  │ │  Maps +  │ │ WeatherAPI.com  │
│ Database │ │        │ │ & Media │ │ Geocode  │ │ India IMD       │
└──────────┘ └────────┘ └─────────┘ └──────────┘ └─────────────────┘
```

### Data Flow

```
REST API      [Client] ──HTTPS──▶ [FastAPI] ──async──▶ [PostgreSQL / Redis / S3]
Real-Time     [Client] ───WSS───▶ [ConnectionManager] ──broadcast──▶ [Clients by Role]
Push          [Backend] ──FCM──▶ [Firebase] ──push──▶ [Android/iOS Device]
Offline Mesh  [Device] ───BLE───▶ [Peer] ───BLE───▶ ... ──HTTPS──▶ [Backend] (dedup)
```

---

## BLE Mesh Network — Offline Disaster Resilience

This is the core innovation. When internet connectivity fails, Ocean Sentinels doesn't stop working — it switches to a **device-to-device BLE mesh relay** that propagates hazard reports across nearby phones until one can reach the server.

```
                         NO INTERNET ZONE                          │ INTERNET
                                                                   │
┌──────────┐        ┌──────────┐        ┌──────────┐        ┌─────┴────┐
│ Device A │──BLE──▶│ Device B │──BLE──▶│ Device C │──BLE──▶│ Device D │──HTTPS──▶ Backend
│          │        │          │        │          │        │          │
│ Creates  │        │ Receives │        │ Relays   │        │ Has WiFi │
│ Report   │        │ + Relays │        │ + Dedup  │        │ Uploads  │
│ (Room DB)│        │ (SHA-256)│        │ (72h TTL)│        │ (Dedup)  │
└──────────┘        └──────────┘        └──────────┘        └──────────┘
   ~400m               ~400m               ~400m
   Coded PHY           Coded PHY           Coded PHY
```

### How It Works

1. **Device Identity** — Each device generates a persistent UUID stored in `EncryptedSharedPreferences` (Android masks BLE MAC addresses)
2. **GATT Server + Scanner** — `MeshForegroundService` (START_STICKY) runs a BLE GATT server and scanner simultaneously
3. **Message Propagation** — Messages flood the mesh with SHA-256–based deduplication (10K LRU cache, 72-hour TTL)
4. **Dual PHY** — Attempts BLE Coded PHY (S=8, ~400m range) first, falls back to 1M PHY for older hardware
5. **Fragment Assembly** — Messages exceeding 469 bytes are fragmented, transmitted, and reassembled at the receiver
6. **Auto-Flush** — `NetworkConnectivityManager` monitors connectivity; when internet returns, all queued messages are uploaded to the backend
7. **Server-Side Dedup** — The backend's `mesh_message_id` unique constraint prevents duplicate incident creation across relay paths

### Mesh Protocol Specifications

| Parameter | Value |
|---|---|
| Max Simultaneous Peers | 7 |
| BLE Fragment Size | 469 bytes |
| Max Packet Size | 512 bytes |
| PHY Strategy | Coded PHY (long range) → 1M fallback |
| Dedup Cache | 10,000 message IDs (LRU) |
| Message Expiry | 72 hours |
| Peer Stale Timeout | 180 seconds |
| Queue Check Interval | 30 seconds |
| Relay Batch Size | 25 messages/cycle |
| Relay Interval | 15 seconds |
| Service Type | Foreground (START_STICKY, auto-restart) |

---

## Platform Overview

### Web Application — [sih.gowshik.in](https://sih.gowshik.in)

11 HTML pages with role-based navigation, interactive Mapbox maps, real-time WebSocket updates, and full incident lifecycle management.

| Console | Purpose |
|---|---|
| **Public Dashboard** | Report hazards, view own reports, public analytics |
| **Authority Console** | Verify incidents, coordinate response, authority analytics |
| **Rescue Console** | View assigned incidents, update deployment status |
| **Admin Dashboard** | User management, system control, all incident actions |

### Android Application — [Download APK](https://ocean-sentinels.s3.ap-south-1.amazonaws.com/Ocean-Sentinels.V1.1.apk)

Native Kotlin app with Jetpack Compose, 20+ screens, clean architecture (Domain → Data → Presentation), and the full BLE mesh networking stack.

| Property | Value |
|---|---|
| Package | `com.oceansentinels.app` |
| Min SDK | 24 (Android 7.0) |
| Target SDK | 34 (Android 14) |
| Architecture | MVVM + Clean Architecture |
| DI | Hilt |
| Local DB | Room |
| Network | Retrofit + OkHttp |
| Maps | Mapbox SDK |
| Push | Firebase Cloud Messaging |

### iOS Application — *In Development*

SwiftUI app with near feature parity to Android, including CoreBluetooth mesh networking, SwiftData persistence, and async/await concurrency.

---

## Role-Based Access Control

Ocean Sentinels implements four distinct user roles, each with dedicated UI consoles and API-level permission enforcement:

| Role | Capabilities |
|---|---|
| **Public** | Report incidents, view own reports, access public analytics |
| **Authority** | All public features + verify incidents, deploy response teams, authority analytics |
| **Rescue Team** | All public features + view assigned incidents, update deployment status, resolve incidents |
| **Admin** | Full system access — user CRUD, create authority/rescue accounts, all incident actions, system configuration |

---

## Tech Stack

| Layer | Technologies |
|---|---|
| **Backend** | Python 3.11, FastAPI, SQLAlchemy 2.0 (async), asyncpg, PostgreSQL, Redis, JWT (python-jose), bcrypt (passlib) |
| **Web Frontend** | Vanilla JavaScript ES6+, Mapbox GL JS, CSS3, WebSocket API |
| **Android** | Kotlin 2.0, Jetpack Compose (Material3), Hilt, Room, Retrofit, OkHttp, Firebase, Mapbox SDK |
| **iOS** | Swift 5.9, SwiftUI, SwiftData, URLSession, CoreBluetooth, MapboxMaps (SPM) |
| **BLE Mesh** | Custom GATT protocol, Coded PHY (S=8), SHA-256 dedup, LRU cache, foreground service |
| **Infrastructure** | PostgreSQL, Redis, AWS S3, Firebase Cloud Messaging |
| **Maps** | Mapbox GL JS (web), Mapbox SDK (Android), MapboxMaps (iOS) |
| **Weather** | WeatherAPI.com, India Meteorological Department API |

---

## Project Structure

```
Ocean-Hazard/
├── backend/                            # FastAPI async backend
│   └── app/
│       ├── core/                       # Config (Settings), security (JWT + bcrypt)
│       ├── database/                   # AsyncSession factory, AWS S3 config
│       ├── models/                     # SQLAlchemy ORM — User, Incident, Analytics
│       ├── routers/                    # API endpoints
│       │   ├── auth.py                 # Register, login, JWT flow
│       │   ├── incidents.py            # CRUD + mesh dedup + status workflow
│       │   ├── users.py               # User management (admin)
│       │   ├── analytics.py            # Dashboard stats, timeline, distribution
│       │   └── websocket.py            # Real-time ConnectionManager
│       ├── schemas/                    # Pydantic validation models
│       └── main.py                     # App entry point, lifespan, CORS, auto-migration
│
├── frontend/                           # Web application
│   ├── pages/                          # 11 HTML pages (role-based consoles)
│   ├── scripts/                        # 13+ JS modules (API client, auth, dashboards)
│   └── styles/                         # CSS stylesheets
│
├── android_app/                        # Native Android (Kotlin)
│   └── app/src/main/.../oceansentinels/app/
│       ├── data/                       # Room DB, Retrofit API, DTOs, repositories
│       ├── di/                         # Hilt modules (Database, Network, Mesh, Location)
│       ├── domain/                     # Business models + repository interfaces
│       ├── mesh/                       # ★ BLE Mesh Networking
│       │   ├── ble/                    # BleMeshManager, DeviceIdentifier
│       │   ├── model/                  # MeshMessage, MeshPeer, MeshTransport
│       │   ├── network/               # NetworkConnectivityManager
│       │   ├── repository/            # MeshMessageRepository (dedup + queue)
│       │   └── service/               # MeshForegroundService (START_STICKY)
│       └── presentation/              # 20+ Compose screens, 7 ViewModels, navigation
│
├── IOS/                                # Native iOS (Swift/SwiftUI)
│   └── OceanSentinels/
│       ├── Domain/                     # Models + repository protocols
│       ├── Data/                       # NetworkClient, SwiftData, DTOs
│       ├── DI/                         # Manual DependencyContainer
│       ├── Mesh/                       # CoreBluetooth mesh (mirroring Android)
│       └── Presentation/              # SwiftUI screens, ViewModels, navigation
│
└── docs/                               # Deployment guides, testing checklists, architecture
```

---

## Backend API

### Endpoints

| Method | Endpoint | Description | Auth |
|---|---|---|---|
| `POST` | `/api/auth/register` | Create account (public role enforced) | No |
| `POST` | `/api/auth/login` | Authenticate, returns JWT + user | No |
| `GET` | `/api/auth/me` | Current user profile | Bearer |
| `POST` | `/api/incidents/` | Create hazard report | Bearer |
| `GET` | `/api/incidents/` | List incidents (paginated, role-filtered) | Bearer |
| `GET` | `/api/incidents/{id}` | Incident details | Bearer |
| `PUT` | `/api/incidents/{id}/verify` | Mark verified | Authority/Admin |
| `PUT` | `/api/incidents/{id}/deploy` | Start response | Admin/Rescue |
| `PUT` | `/api/incidents/{id}/resolve` | Close incident | Role-gated |
| `PUT` | `/api/incidents/{id}/assign` | Assign to rescue team | Admin |
| `POST` | `/api/incidents/mesh/check` | Bulk mesh dedup check (max 100) | Bearer |
| `GET` | `/api/analytics/dashboard` | Dashboard metrics | Bearer |
| `GET` | `/api/analytics/public/dashboard` | Public statistics | No |
| `GET` | `/api/analytics/incidents/timeline` | Time series (1–365 days) | Bearer |
| `GET` | `/api/analytics/incidents/distribution` | Distribution by type/status/region | Bearer |
| `POST` | `/api/users/create` | Create user with any role | Admin |
| `GET` | `/api/users/` | List all users | Admin/Authority |
| `WS` | `/api/ws/incidents` | Real-time updates (role-filtered broadcast) | Bearer |
| `GET` | `/health` | Health check | No |

### Hazard Types

`HIGH_WAVES` · `STRONG_CURRENTS` · `FLOODING` · `TSUNAMI` · `LOST_VESSEL` · `DEBRIS` · `EROSION` · `STORM` · `OIL_SPILL` · `OTHER`

### Incident Lifecycle

```
PENDING ──▶ VERIFIED ──▶ IN_PROGRESS ──▶ RESOLVED
   │                                         ▲
   └──────── FALSE_ALARM                     │
                                   (or direct resolve)
```

---

## Database Schema

### Users

| Column | Type | Notes |
|---|---|---|
| `id` | `INTEGER PK` | Auto-increment |
| `username` | `VARCHAR(50) UNIQUE` | |
| `email` | `VARCHAR(100) UNIQUE` | |
| `hashed_password` | `VARCHAR(255)` | bcrypt |
| `role` | `ENUM` | public, admin, authority, rescue_team |
| `first_name`, `last_name` | `VARCHAR(50)` | |
| `phone`, `location` | `VARCHAR` | Optional |
| `is_active`, `is_verified` | `BOOLEAN` | |
| `created_at`, `updated_at`, `last_login` | `TIMESTAMPTZ` | |

### Incidents

| Column | Type | Notes |
|---|---|---|
| `id` | `INTEGER PK` | |
| `reference_id` | `VARCHAR(50) UNIQUE` | Format: `OG-{timestamp}-{random}` |
| `hazard_type` | `ENUM` | 10 types |
| `location` | `VARCHAR(255)` | Human-readable |
| `latitude`, `longitude` | `FLOAT` | GPS coordinates |
| `description` | `TEXT` | |
| `urgency` | `ENUM` | LOW, MEDIUM, HIGH, CRITICAL |
| `status` | `ENUM` | PENDING → VERIFIED → IN_PROGRESS → RESOLVED |
| `mesh_message_id` | `VARCHAR(128) UNIQUE` | BLE dedup key |
| `reporter_id` | `FK → users` | |
| `verified_by_id`, `assigned_to_id` | `FK → users` | Nullable |
| `photo_url` | `VARCHAR(500)` | S3 URL |

---

## Getting Started

### Prerequisites

- Python 3.11+
- PostgreSQL 14+ (or SQLite for local dev)
- Android Studio Hedgehog+ with JDK 17 (for Android)
- Xcode 15+ (for iOS)

### Backend

```bash
cd backend
python -m venv venv && source venv/bin/activate  # or venv\Scripts\activate on Windows
pip install -r requirements.txt
# Set DATABASE_URL, SECRET_KEY in .env
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

API docs at `http://localhost:8000/api/docs`

### Web Frontend

```bash
cd frontend
# Serve with any static server:
python -m http.server 5500
# Update API_BASE_URL in scripts/api-client.js
```

### Android

```bash
cd android_app
# Open in Android Studio → configure local.properties with MAPBOX_ACCESS_TOKEN
./gradlew assembleDebug
```

> BLE mesh requires a physical device with Bluetooth LE support.

---

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `DATABASE_URL` | Yes | PostgreSQL connection string |
| `SECRET_KEY` | Yes | JWT signing secret |
| `MAPBOX_ACCESS_TOKEN` | Yes | Mapbox maps token |
| `AWS_ACCESS_KEY_ID` | Optional | S3 photo uploads |
| `AWS_SECRET_ACCESS_KEY` | Optional | S3 photo uploads |
| `AWS_S3_BUCKET` | Optional | S3 bucket name |
| `REDIS_URL` | Optional | Cache layer |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS` | Optional | Email notifications |

---

## Contributing

Contributions are welcome. Whether it's improving the mesh protocol, adding new hazard types, translating the UI, or hardening the backend — every contribution helps protect coastal communities.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/mesh-improvements`)
3. Commit your changes (`git commit -m 'Improve BLE relay batching'`)
4. Push to the branch (`git push origin feature/mesh-improvements`)
5. Open a Pull Request

See [`docs/`](docs/) for architecture guides, testing checklists, and deployment documentation.

---

## License

This project is licensed under the [Apache License 2.0](LICENSE) — you are free to use, modify, and distribute this software. See [LICENSE](LICENSE) for the full terms.

Copyright © 2026 Gowshik S. Built for coastal communities worldwide under India's Ministry of Earth Sciences initiative.

---

<p align="center">
  <strong>Web</strong>: <a href="https://sih.gowshik.in">sih.gowshik.in</a> · 
  <strong>Android</strong>: <a href="https://ocean-sentinels.s3.ap-south-1.amazonaws.com/Ocean-Sentinels.V1.1.apk">Download APK v1.1</a>
</p>
