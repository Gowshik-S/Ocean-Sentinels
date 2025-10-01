# 🌊 Ocean Hazard POST Commands Documentation

## 📋 Available POST Endpoints

The Ocean Hazard API provides **7 POST endpoints** for various operations:

---

## 🔐 **Authentication Endpoints**

### 1. **POST /api/auth/login** (Form Data)
**Purpose**: User login with form data  
**Content-Type**: `application/x-www-form-urlencoded`

```bash
curl -X POST http://127.0.0.1:8002/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin"
```

**Response**:
```json
{
  "access_token": "fake-jwt-token-1-admin",
  "token_type": "bearer",
  "user": {
    "id": 1,
    "username": "admin",
    "role": "admin",
    "first_name": "Admin",
    "last_name": "User",
    "full_name": "Admin User",
    "email": "admin@oceanguard.gov.in",
    "is_active": true
  }
}
```

### 2. **POST /api/auth/login-json** (JSON Data)
**Purpose**: User login with JSON data  
**Content-Type**: `application/json`

```bash
curl -X POST http://127.0.0.1:8002/api/auth/login-json \
  -H "Content-Type: application/json" \
  -d '{"username": "user", "password": "user"}'
```

**Response**:
```json
{
  "access_token": "fake-jwt-token-user",
  "token_type": "bearer",
  "user": {
    "id": 2,
    "username": "user",
    "role": "citizen",
    "first_name": "Test",
    "last_name": "User"
  }
}
```

### 3. **POST /api/auth/register** (JSON Registration)
**Purpose**: Register new user with JSON data  
**Content-Type**: `application/json`

```bash
curl -X POST http://127.0.0.1:8002/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "newuser",
    "email": "newuser@example.com",
    "password": "securepass123",
    "first_name": "New",
    "last_name": "User"
  }'
```

**Response**:
```json
{
  "message": "User registered successfully",
  "user": {
    "id": 3,
    "username": "newuser",
    "email": "newuser@example.com",
    "first_name": "New",
    "last_name": "User",
    "full_name": "New User",
    "role": "citizen"
  }
}
```

### 4. **POST /api/auth/register-form** (Form Registration)
**Purpose**: Register new user with form data  
**Content-Type**: `application/x-www-form-urlencoded`

```bash
curl -X POST http://127.0.0.1:8002/api/auth/register-form \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=formuser&email=form@example.com&password=pass123&first_name=Form&last_name=User"
```

---

## 📋 **Incident Management**

### 5. **POST /api/incidents/** (Create Incident)
**Purpose**: Create new incident report  
**Content-Type**: `application/json`  
**Authentication**: Required (Bearer token)

```bash
curl -X POST http://127.0.0.1:8002/api/incidents/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <user_token>" \
  -d '{
    "hazard_type": "HIGH_WAVES",
    "location": "Marina Beach, Chennai",
    "latitude": 13.0475,
    "longitude": 80.2824,
    "description": "Extremely high waves observed. Dangerous for swimmers.",
    "urgency": "HIGH",
    "contact_info": "+91 9876543210"
  }'
```

**Response**:
```json
{
  "id": 4,
  "message": "Incident reported successfully",
  "reference_id": "OG-20250929220630-00000004",
  "status": "pending"
}
```

**Incident Data Fields**:
- `hazard_type`: HIGH_WAVES, TSUNAMI, DEBRIS, FLOODING, etc.
- `location`: Text description of location
- `latitude`: GPS latitude coordinate
- `longitude`: GPS longitude coordinate
- `description`: Detailed description of the incident
- `urgency`: LOW, MEDIUM, HIGH
- `contact_info`: Contact details of reporter

---

## 👨‍💼 **Admin-Only Endpoints**

### 6. **POST /api/admin/teams/** (Add Rescue Team)
**Purpose**: Add new rescue team (Admin only)  
**Content-Type**: `application/json`  
**Authentication**: Required (Admin Bearer token)

```bash
curl -X POST http://127.0.0.1:8002/api/admin/teams/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <admin_token>" \
  -d '{
    "id": 1,
    "name": "Chennai Coast Guard Team Alpha",
    "type": "marine_rescue",
    "location": "Chennai Port",
    "contact_number": "+91 44-25361234",
    "email": "alpha@chennaicoastguard.gov.in",
    "leader": "Captain Rajesh Kumar",
    "members_count": 12,
    "equipment": ["rescue_boats", "diving_gear", "medical_kit"],
    "status": "active"
  }'
```

**Response**:
```json
{
  "message": "Rescue team added successfully",
  "team_id": 1
}
```

### 7. **POST /api/admin/authorities/** (Add Authority)
**Purpose**: Add new authority (Admin only)  
**Content-Type**: `application/json`  
**Authentication**: Required (Admin Bearer token)

```bash
curl -X POST http://127.0.0.1:8002/api/admin/authorities/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <admin_token>" \
  -d '{
    "id": 2,
    "name": "Dr. Priya Sharma",
    "position": "Regional Director",
    "email": "priya.sharma@tamilnadu.gov.in",
    "phone": "+91 44-28411234",
    "department": "Tamil Nadu State Disaster Management Authority",
    "level": "state",
    "jurisdiction": "Tamil Nadu coastal disaster management",
    "status": "active"
  }'
```

**Response**:
```json
{
  "message": "Authority added successfully",
  "authority_id": 2
}
```

---

## 🔧 **Authentication Flow**

### Getting Admin Token:
1. POST to `/api/auth/login` with `username=admin&password=admin`
2. Extract `access_token` from response
3. Use as `Authorization: Bearer <token>` in subsequent requests

### Getting User Token:
1. POST to `/api/auth/login-json` with `{"username": "user", "password": "user"}`
2. Extract `access_token` from response
3. Use for creating incidents and accessing user endpoints

---

## 📊 **Request/Response Examples**

### JavaScript Fetch Examples:

```javascript
// Login
const loginResponse = await fetch('http://127.0.0.1:8002/api/auth/login-json', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ username: 'admin', password: 'admin' })
});

// Create Incident
const incidentResponse = await fetch('http://127.0.0.1:8002/api/incidents/', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  },
  body: JSON.stringify({
    hazard_type: 'TSUNAMI',
    location: 'Pondicherry Beach',
    latitude: 11.9139,
    longitude: 79.8145,
    description: 'Unusual wave patterns observed',
    urgency: 'HIGH',
    contact_info: '+91 9876543210'
  })
});
```

### Python Requests Examples:

```python
import requests

# Login
response = requests.post('http://127.0.0.1:8002/api/auth/login-json', 
                        json={'username': 'admin', 'password': 'admin'})
token = response.json()['access_token']

# Create Incident
incident_data = {
    'hazard_type': 'HIGH_WAVES',
    'location': 'Marina Beach, Chennai',
    'latitude': 13.0475,
    'longitude': 80.2824,
    'description': 'High waves dangerous for swimmers',
    'urgency': 'HIGH',
    'contact_info': '+91 9876543210'
}

response = requests.post('http://127.0.0.1:8002/api/incidents/',
                        json=incident_data,
                        headers={'Authorization': f'Bearer {token}'})
```

---

## ❌ **Error Responses**

### 401 Unauthorized:
```json
{
  "detail": "Invalid credentials"
}
```

### 403 Forbidden:
```json
{
  "detail": "Access denied: Admin privileges required"
}
```

### 400 Bad Request:
```json
{
  "detail": "All fields are required"
}
```

---

## 📋 **Summary**

| Endpoint | Method | Purpose | Auth Required | Role |
|----------|---------|---------|---------------|------|
| `/api/auth/login` | POST | Login (Form) | No | Any |
| `/api/auth/login-json` | POST | Login (JSON) | No | Any |
| `/api/auth/register` | POST | Register (JSON) | No | - |
| `/api/auth/register-form` | POST | Register (Form) | No | - |
| `/api/incidents/` | POST | Create Incident | Yes | User/Admin |
| `/api/admin/teams/` | POST | Add Rescue Team | Yes | Admin |
| `/api/admin/authorities/` | POST | Add Authority | Yes | Admin |

**Total POST Endpoints: 7**  
**Authentication Endpoints: 4**  
**Incident Management: 1**  
**Admin Management: 2**