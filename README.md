# Ocean Sentinels - A Coastal Safety Network

A full-stack coastal safety and hazard reporting platform built for coastal communities worldwide. The system enables real-time maritime incident reporting, response coordination, and offline BLE mesh networking for areas with limited or no connectivity — keeping communities connected when disasters take down 
the infrastructure.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Backend API](#backend-api)
- [Frontend Web App](#frontend-web-app)
- [Android App](#android-app)
- [BLE Mesh Network](#ble-mesh-network)
- [Getting Started](#getting-started)
- [Deployment](#deployment)
- [Configuration](#configuration)
- [API Reference](#api-reference)
- [License](#license)

---

## Overview

Ocean Sentinels provides a unified platform for coastal hazard reporting across worldwide. It supports four user roles -- Public citizens, Authorities, Rescue Teams, and Administrators -- each with dedicated consoles and workflows.

**Core capabilities:**

- Real-time incident reporting with GPS coordinates and photo evidence
- Live interactive map (Mapbox) with incident markers and monitoring zones
- Role-based dashboards for incident verification, response deployment, and analytics
- BLE mesh networking for offline hazard report relay between Android devices
- Weather integration (WeatherAPI + Indian Weather API) with live alerts
- WebSocket-based real-time notifications
- Firebase Cloud Messaging for push notifications

---

## Architecture

### High-Level System Overview

```
  +----------------------+                   +---------------------------+
  |    WEB FRONTEND      |                   |       ANDROID APP         |
  |                      |                   |                           |
  |  Vanilla JS (ES6+)  |                   |  Kotlin, Jetpack Compose  |
  |  Mapbox GL JS        |                   |  Hilt DI, Room Database   |
  |  WebSocket Client    |                   |  Retrofit, OkHttp         |
  |  JWT Auth Manager    |                   |  Mapbox Maps SDK          |
  |  8 Role-Based Pages  |                   |  Firebase Cloud Messaging |
  |                      |                   |  BLE Mesh Networking      |
  |                      |                   |  20+ Compose Screens      |
  +-----------+----------+                   +-----+-----------+---------+
              |                                    |          |
       HTTPS + WebSocket                    HTTPS + FCM    BLE Radio
              |                                    |    (Coded PHY / 1M)
              +-------------------+----------------+          |
                                  |                           |
                                  v                           |
  +---------------------------------------------------------------+
  |                  FASTAPI BACKEND SERVER                        |
  |                  Python 3.11+ / SQLAlchemy 2.0 / Async I/O    |
  |                                                               |
  |  +--------+  +-----------+  +---------+  +-----------------+  |
  |  | Auth   |  | Incidents |  | Users   |  | WebSocket       |  |
  |  | (JWT,  |  | (CRUD,    |  | (RBAC,  |  | (Role-Filtered  |  |
  |  | bcrypt)|  |  Mesh     |  |  4      |  |  Real-Time      |  |
  |  |        |  |  Dedup)   |  |  Roles) |  |  Broadcasts)    |  |
  |  +--------+  +-----------+  +---------+  +-----------------+  |
  |  +-----------+  +---------+  +---------------------------+    |
  |  | Analytics |  | Config  |  | Health Check (/health)    |    |
  |  | (Metrics, |  | (Mapbox |  |                           |    |
  |  |  Stats)   |  |  Token) |  |                           |    |
  |  +-----------+  +---------+  +---------------------------+    |
  |                                                               |
  +---------------------------------------------------------------+
        |          |          |          |              |
        v          v          v          v              v
  +----------+ +------+ +-------+ +--------+ +---------------+
  |PostgreSQL| |Redis | |AWS S3 | |Mapbox  | |Weather APIs   |
  |          | |      | |       | |        | |               |
  | Primary  | |Cache | |Photo  | |Map     | |WeatherAPI.com |
  | Database | |  and | |  and  | |Tiles,  | |India IMD      |
  |          | |State | |Media  | |Geocode | |               |
  +----------+ +------+ +-------+ +--------+ +---------------+
```

### BLE Mesh Relay Network (Offline Mode)

When devices lose internet connectivity, the Android app forms an ad-hoc
BLE mesh network to relay hazard reports until a connected device is reached.

```
  +------------------+                +------------------+
  |  Offline Device  | ----BLE------> |   Relay Peer     | ----BLE----->  ...
  |                  |                |                  |
  |  Creates Report  |                |  Receives Msg    |
  |  Stores in Room  |                |  SHA-256 Dedup   |
  |  Broadcasts via  |                |  Checks 72h      |
  |  BLE GATT Server |                |  Expiry Window   |
  +------------------+                +--------+---------+
                                               |
                                   +-----------+-----------+
                                   |                       |
                              No Internet             Has Internet
                                   |                       |
                                   v                       v
                          +----------------+    +--------------------+
                          | Continue Relay |    | Upload to Backend  |
                          | to Next Peers  |    | (Server Dedup via  |
                          | (Append to     |    |  mesh_message_id)  |
                          |  Relay Path)   |    |                    |
                          +----------------+    +--------------------+

  Mesh Specifications:
  +------------------------+--------------------------+
  | Parameter              | Value                    |
  +------------------------+--------------------------+
  | Max Connections        | 7 simultaneous peers     |
  | Fragment Size          | 469 bytes                |
  | Max Packet Size        | 512 bytes                |
  | Dedup Cache            | 10,000 message IDs (LRU) |
  | Message Expiry         | 72 hours (time-based)    |
  | Peer Stale Timeout     | 180 seconds              |
  | Scan Restart Interval  | 30 seconds               |
  | PHY Strategy           | Coded PHY (long range),  |
  |                        | 1M PHY fallback          |
  +------------------------+--------------------------+
```

### Data Flow Summary

```
  REST API:
    [Client] --HTTPS--> [FastAPI] --async--> [PostgreSQL]
                             |------async--> [Redis Cache]
                             |------async--> [AWS S3 Storage]

  Real-Time Updates:
    [Client] ---WSS---> [WebSocket Manager] --broadcast--> [Clients by Role]

  Push Notifications:
    [Backend Event] --FCM--> [Firebase] --push--> [Android Device]

  Offline Mesh:
    [Device] ---BLE---> [Peer] ---BLE---> ... --HTTPS--> [Backend API]
                                                           |
                                                    (Dedup by mesh_message_id)
```

### Authentication and Role-Based Access

```
  +------------------------------------------------------------------+
  |                     AUTHENTICATION FLOW                           |
  |                                                                   |
  |  [Client]                                                         |
  |     |                                                             |
  |     +-- POST /api/auth/login ----> [Auth Router]                  |
  |                                        |                          |
  |                                  Verify bcrypt hash               |
  |                                        |                          |
  |                                  Generate JWT                     |
  |                                  (sub, role, exp)                 |
  |                                        |                          |
  |     <-- Token + User Object -----------+                          |
  |     |                                                             |
  |     +-- Authorization: Bearer <token> --> [Protected Endpoints]   |
  |                                                                   |
  +------------------------------------------------------------------+

  Role Permissions:
  +-------------+-----------------------------------------------------+
  | Role        | Access                                              |
  +-------------+-----------------------------------------------------+
  | Public      | Report incidents, view own reports, public stats    |
  +-------------+-----------------------------------------------------+
  | Authority   | All incidents, verify reports, deploy response      |
  +-------------+-----------------------------------------------------+
  | Rescue Team | All incidents, deploy response, resolve incidents   |
  +-------------+-----------------------------------------------------+
  | Admin       | Full access, user management, all incident actions  |
  +-------------+-----------------------------------------------------+
```

---

## Project Structure

```
Ocean-Hazard/
|-- backend/                        # FastAPI backend server
|   |-- app/
|   |   |-- core/                   # Config, settings
|   |   |-- database/               # SQLAlchemy engine, session, Base
|   |   |-- models/                 # ORM models (User, Incident, Analytics)
|   |   |-- routers/                # API route handlers
|   |   |   |-- auth.py             # Authentication (JWT)
|   |   |   |-- incidents.py        # Incident CRUD + mesh dedup
|   |   |   |-- users.py            # User management
|   |   |   |-- analytics.py        # Dashboard analytics
|   |   |   |-- websocket.py        # Real-time notifications
|   |   |-- schemas/                # Pydantic request/response models
|   |   |-- main.py                 # FastAPI app entry point
|   |-- scripts/                    # Migration and deployment scripts
|   |-- requirements.txt
|
|-- frontend/                       # Static web frontend
|   |-- index.html                  # Landing page
|   |-- pages/                      # HTML pages
|   |   |-- index.html              # Live map dashboard
|   |   |-- reports.html            # Incident reports
|   |   |-- my-reports.html         # User's own reports
|   |   |-- analytics.html          # Analytics dashboard
|   |   |-- admin-dashboard.html    # Admin panel
|   |   |-- authority-console.html  # Authority console
|   |   |-- rescue-console.html     # Rescue team console
|   |   |-- terms.html              # Terms and conditions
|   |-- scripts/                    # JavaScript modules
|   |   |-- api-client.js           # Backend API client (JWT auth)
|   |   |-- script.js               # Main app logic + Mapbox
|   |   |-- navigation-manager.js   # Role-based navigation
|   |   |-- analytics.js            # Analytics charts
|   |   |-- reports-dashboard.js    # Reports page logic
|   |-- styles/                     # CSS stylesheets
|   |-- assets/                     # Images and static files
|   |-- vercel.json                 # Vercel deployment config
|
|-- android_app/                    # Native Android application
|   |-- app/src/main/java/com/oceansentinels/app/
|   |   |-- data/                   # Repositories, DTOs, Room DB, API
|   |   |-- di/                     # Hilt dependency injection modules
|   |   |-- domain/                 # Domain models and repository interfaces
|   |   |-- mesh/                   # BLE mesh networking layer
|   |   |   |-- ble/                # BleMeshManager, DeviceIdentifier
|   |   |   |-- model/              # MeshMessage, MeshPeer
|   |   |   |-- repository/         # MeshMessageRepository
|   |   |   |-- service/            # MeshForegroundService
|   |   |-- presentation/           # UI layer
|   |   |   |-- ui/screens/         # Compose screens (20+ screens)
|   |   |   |-- ui/theme/           # Material3 theming
|   |   |   |-- ui/components/      # Reusable UI components
|   |   |   |-- viewmodel/          # ViewModels (7 total)
|   |   |   |-- navigation/         # NavHost and Screen routes
|   |   |-- OceanSentinelsApp.kt    # Application class
|
|-- docs/                           # Project documentation
|-- Procfile                        # Render deployment
|-- railway.json                    # Railway deployment
|-- requirements.txt                # Root Python dependencies
```

---

## Backend API

**Stack:** Python 3.11+, FastAPI, SQLAlchemy 2.0 (async), PostgreSQL (asyncpg), JWT authentication

### Key Features

- Async database operations with SQLAlchemy + asyncpg
- JWT-based authentication with role-based access control
- Automatic table creation and column migration on startup
- Mesh message deduplication (prevents duplicate incidents from BLE relay)
- WebSocket endpoint for real-time incident updates
- Health check endpoint at `/health`
- API documentation at `/api/docs` (Swagger) and `/api/redoc`

### API Endpoints

| Method | Endpoint                      | Description                         | Auth Required |
|--------|-------------------------------|-------------------------------------|---------------|
| POST   | `/api/auth/login`             | User login, returns JWT             | No            |
| POST   | `/api/auth/register`          | Register new user                   | No            |
| GET    | `/api/auth/me`                | Get current user profile            | Yes           |
| GET    | `/api/incidents/`             | List incidents (paginated, filtered)| Yes           |
| POST   | `/api/incidents/`             | Create incident report              | Yes           |
| GET    | `/api/incidents/{id}`         | Get incident details                | Yes           |
| PUT    | `/api/incidents/{id}/verify`  | Verify incident (Authority/Admin)   | Yes (Role)    |
| PUT    | `/api/incidents/{id}/deploy`  | Deploy response (Admin/Rescue)      | Yes (Role)    |
| PUT    | `/api/incidents/{id}/resolve` | Resolve incident                    | Yes (Role)    |
| PUT    | `/api/incidents/{id}/assign`  | Assign to rescue team               | Yes (Role)    |
| GET    | `/api/incidents/assigned/me`  | My assigned incidents               | Yes           |
| GET    | `/api/analytics/dashboard`    | Dashboard statistics                | Yes           |
| GET    | `/api/users/`                 | List users (Admin)                  | Yes (Admin)   |
| WS     | `/api/ws/`                    | WebSocket for live updates          | Yes           |
| GET    | `/health`                     | Health check                        | No            |

### Database Models

- **User** -- id, username, email, password hash, role (public/admin/authority/rescue_team), location, timestamps
- **Incident** -- id, reference_id, hazard_type, location, lat/lng, description, urgency, status, mesh_message_id, reporter/verifier/assignee foreign keys, timestamps
- **AnalyticsSnapshot** -- periodic aggregated statistics
- **UserVisit / WebsiteStats** -- visitor analytics

---

## Frontend Web App

**Stack:** Vanilla JavaScript (ES6+), Mapbox GL JS, CSS3, Font Awesome 6, JWT auth

### Pages

| Page                    | Description                                          |
|-------------------------|------------------------------------------------------|
| Live Map (index.html)   | Interactive Mapbox map with incident markers          |
| Reports                 | Incident list with filtering and status management    |
| My Reports              | User's own submitted incident reports                 |
| Analytics               | Charts and statistics dashboard                       |
| Admin Dashboard         | User management, system overview                      |
| Authority Console       | Incident verification and response coordination       |
| Rescue Console          | Assigned incidents and deployment tracking             |

### Features

- Role-based navigation (different menus per user role)
- Real-time location detection with 50km monitoring radius visualization
- Responsive design for desktop, tablet, and mobile
- JWT token management with auto-refresh

---

## Android App

**Stack:** Kotlin, Jetpack Compose, Material3, Hilt, Room, Retrofit, Mapbox SDK, Firebase

| Property       | Value                     |
|----------------|---------------------------|
| Package        | `com.oceansentinels.app`  |
| Min SDK        | 24 (Android 7.0)          |
| Target SDK     | 34 (Android 14)           |
| Version        | 1.0.0                     |

### Screens (20+)

Splash, Login, Register, Home, Map, Report Incident, My Reports, Incident Detail, Incidents Dashboard, Analytics, Weather, Admin Console, Admin Dashboard, User Management, Create Rescue Team, Create Authority, Rescue Console, Authority Console, Profile, Settings, Terms and Conditions, Mesh Network

### Key Features

- Compose-based UI with light/dark theme support
- Hilt dependency injection across all layers
- Room database for local caching
- Retrofit + OkHttp for API communication
- Google Play Services for GPS location
- Mapbox Maps SDK for interactive mapping
- Firebase Cloud Messaging for push notifications
- Core Library Desugaring for java.time support on API 24-25

---

## BLE Mesh Network

The Android app includes a Bluetooth Low Energy mesh networking layer for offline hazard report relay. When a device has no internet connectivity, it can broadcast hazard reports over BLE to nearby devices. Those devices relay the message further until one with internet access uploads it to the backend.

### How It Works

1. Each device generates a persistent unique ID (stored in SharedPreferences) since Android 6+ masks real MAC addresses.
2. The MeshForegroundService runs a BLE GATT server and scanner simultaneously.
3. Messages are broadcast with TTL-based flooding and SHA-256 message ID deduplication.
4. Dual PHY strategy: attempts BLE Coded PHY (long range, ~400m) first, falls back to standard 1M PHY.
5. When a device with internet receives a relayed message, it uploads the incident to the backend.
6. The backend deduplicates using the `mesh_message_id` field to prevent duplicate incident creation.

### Mesh Specifications

| Parameter              | Value                    |
|------------------------|--------------------------|
| Max Connections        | 7 simultaneous           |
| Fragment Size          | 469 bytes                |
| Max Packet Size        | 512 bytes                |
| Scan Restart Interval  | 30 seconds               |
| Peer Stale Timeout     | 180 seconds              |
| Dedup Cache Size       | 10,000 message IDs       |

---

## Getting Started

### Prerequisites

- Python 3.11+
- PostgreSQL 14+ (or SQLite for local development)
- Node.js (optional, for frontend tooling)
- Android Studio Hedgehog+ (for Android development)
- JDK 17

### Backend Setup

```bash
cd Ocean-Hazard/backend

# Create virtual environment
python -m venv venv
source venv/bin/activate      # Linux/macOS
venv\Scripts\activate         # Windows

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your DATABASE_URL, SECRET_KEY, etc.

# Run the server
uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

The server will:
- Create all database tables on startup
- Run auto-migrations for any missing columns
- Serve API docs at http://127.0.0.1:8000/api/docs

### Frontend Setup

```bash
cd Ocean-Hazard/frontend

# Option 1: Open directly
# Open pages/index.html in a browser

# Option 2: Use a local server (recommended)
# VS Code: Install "Live Server" extension, right-click index.html -> Open with Live Server
# Python: python -m http.server 5500
# Node: npx serve .
```

Update the API base URL in `scripts/api-client.js` if your backend runs on a different address.

### Android Setup

```bash
cd Ocean-Hazard/android_app

# Open in Android Studio
# File -> Open -> select the android_app directory

# Configure local.properties
# MAPBOX_ACCESS_TOKEN=your_mapbox_token
# API_BASE_URL=https://your-backend-url.com/api

# Build and run on device/emulator
./gradlew assembleDebug
```

BLE mesh features require a physical device with Bluetooth LE support.

---

## Deployment

### Backend (Render)

The backend deploys to Render using the Procfile:

```
web: uvicorn backend.app.main:app --host 0.0.0.0 --port $PORT
```

Required environment variables: `DATABASE_URL`, `SECRET_KEY`, `MAPBOX_ACCESS_TOKEN`

### Backend (Railway)

Railway deployment is configured via `railway.json`. Set the same environment variables in the Railway dashboard.

### Frontend (Vercel)

The frontend deploys to Vercel with the included `vercel.json` configuration. Point it at the `frontend/` directory.

---

## Configuration

### Environment Variables

| Variable                      | Description                           | Default                          |
|-------------------------------|---------------------------------------|----------------------------------|
| `DATABASE_URL`                | PostgreSQL connection string          | SQLite fallback                  |
| `SECRET_KEY`                  | JWT signing secret                    | (must be set in production)      |
| `ALGORITHM`                   | JWT algorithm                         | HS256                            |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Token expiry                          | 30                               |
| `HOST`                        | Server bind address                   | 0.0.0.0                          |
| `PORT`                        | Server port                           | 8000                             |
| `DEBUG`                       | Enable debug mode                     | True                             |
| `MAPBOX_ACCESS_TOKEN`         | Mapbox public token                   | (required for maps)              |
| `AWS_ACCESS_KEY_ID`           | AWS credentials (optional)            | --                               |
| `AWS_SECRET_ACCESS_KEY`       | AWS credentials (optional)            | --                               |
| `AWS_S3_BUCKET`               | S3 bucket for file storage            | ocean-hazard-storage             |
| `REDIS_URL`                   | Redis connection (optional)           | redis://localhost:6379           |

### Android Build Config

Set in `android_app/local.properties`:

```properties
MAPBOX_ACCESS_TOKEN=pk.your_token_here
API_BASE_URL=https://your-backend-url.com/api
```

---

## License

This project is developed for public safety and disaster management under India's Ministry of Earth Sciences initiative.

---

Version 1.0.0 | Last Updated: February 2026 | Status: Active Development
