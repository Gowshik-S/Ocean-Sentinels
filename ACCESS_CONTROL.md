# 🔐 Ocean Hazard Access Control Matrix

## Role-Based Access Control (RBAC) Implementation

### 👥 User Roles

| Role | Description | Access Level |
|------|-------------|--------------|
| **Public** | Citizens and general public | Limited access to own reports |
| **Rescue Team** | Emergency response teams | Access to incidents and reports |
| **Authority** | Government officials | Full administrative access |
| **Admin** | System administrators | Complete system access |

### 📄 Page Access Control

#### 🏠 **Home Page (index.html)**
- **Access**: Public (no login required)
- **Features**: 
  - View live map
  - Submit incident reports
  - Access login/registration

#### 📊 **Analytics Page (analytics.html)**
- **Access**: **Any logged-in user** (Public, Rescue Team, Authority, Admin)
- **Features**:
  - View dashboard metrics
  - Access timeline data
  - Geographic distribution
  - Response efficiency metrics

#### 📋 **My Reports Page (my-reports.html)**
- **Access**: **Public users** and **Rescue Teams**
- **Features**:
  - View own submitted reports
  - Track report status
  - View report history
  - Submit new reports

#### 🚨 **Incident Reports Page (reports.html)**
- **Access**: **Admin** and **Rescue Teams** only
- **Features**:
  - View all incident reports
  - Verify incidents
  - Deploy responses
  - Resolve incidents
  - Manage incident workflow

### 🔧 Backend API Access Control

#### **Authentication Endpoints**
- `POST /api/auth/register` - Public access
- `POST /api/auth/login` - Public access
- `GET /api/auth/me` - Authenticated users only
- `POST /api/auth/logout` - Authenticated users only

#### **Incident Endpoints**
- `POST /api/incidents/` - Authenticated users only
- `GET /api/incidents/` - 
  - **Public**: Own incidents only
  - **Rescue Team/Admin/Authority**: All incidents with filters
- `GET /api/incidents/{id}` - 
  - **Public**: Own incidents only
  - **Rescue Team/Admin/Authority**: Any incident
- `PUT /api/incidents/{id}/verify` - **Rescue Team/Admin/Authority** only
- `PUT /api/incidents/{id}/deploy` - **Rescue Team/Admin/Authority** only
- `PUT /api/incidents/{id}/resolve` - **Rescue Team/Admin/Authority** only

#### **Analytics Endpoints**
- `GET /api/analytics/dashboard` - **Any authenticated user**
- `GET /api/analytics/incidents/timeline` - **Any authenticated user**
- `GET /api/analytics/incidents/distribution` - **Any authenticated user**
- `GET /api/analytics/geographic` - **Any authenticated user**

#### **User Management Endpoints**
- `GET /api/users/me` - Authenticated users only
- `PUT /api/users/me` - Authenticated users only
- `GET /api/users/` - **Rescue Team/Admin/Authority** only
- `GET /api/users/{id}` - **Rescue Team/Admin/Authority** only
- `PUT /api/users/{id}/activate` - **Admin** only

### 🎯 Navigation Menu by Role

#### **Public Users**
```
Home | Analytics | My Reports | About Us
```

#### **Rescue Teams**
```
Home | Analytics | Incident Reports | My Reports | About Us
```

#### **Authority/Admin**
```
Home | Analytics | Incident Reports | My Reports | About Us
```

### 🚦 Access Flow

1. **Unauthenticated Users**:
   - Can access home page
   - Redirected to login for protected pages

2. **Public Users**:
   - Can access Analytics and My Reports
   - Cannot access Incident Reports page
   - Can submit new incident reports

3. **Rescue Teams**:
   - Can access all pages except user management
   - Can verify, deploy, and resolve incidents
   - Can view all incident reports

4. **Authority/Admin**:
   - Full access to all features
   - Can manage users and system settings
   - Complete administrative control

### 🔒 Security Features

- **JWT Token Authentication**: Secure token-based authentication
- **Role-based Authorization**: Granular permission system
- **Session Management**: Secure session handling
- **CORS Protection**: Cross-origin request security
- **Input Validation**: Server-side validation for all inputs
- **SQL Injection Prevention**: Parameterized queries
- **XSS Protection**: Content sanitization

### 📱 Frontend Implementation

The access control is implemented in `scripts/script.js` with the following functions:

- `checkPageAccess()`: Validates page access based on user role
- `updateNavigationForUser()`: Updates navigation menu based on role
- `checkLoginState()`: Manages user session and UI state

### 🛡️ Backend Implementation

Access control is enforced in the FastAPI routers:

- **Authentication Middleware**: JWT token validation
- **Role-based Decorators**: Permission checking
- **Database-level Security**: Row-level access control
- **API Rate Limiting**: Request throttling (configurable)

---

**Last Updated**: January 27, 2025  
**Version**: 1.0.0  
**Status**: Production Ready


