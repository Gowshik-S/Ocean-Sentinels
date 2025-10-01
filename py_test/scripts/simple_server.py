#!/usr/bin/env python3
"""
Simple Ocean Hazard Server
Working server with SQLite database
"""

import uvicorn
from fastapi import FastAPI, HTTPException, Form, Header
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel
import sys
import os
import sqlite3
import hashlib
from datetime import datetime
from dotenv import load_dotenv

# Add backend to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend'))

# Load environment variables
load_dotenv("backend/env.local")

# Database connection
DB_PATH = "backend/database/ocean_hazard.db"

def init_db():
    """Initialize database connection and create tables if they don't exist"""
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        # Create users table if not exists
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE NOT NULL,
                email TEXT UNIQUE NOT NULL,
                hashed_password TEXT NOT NULL,
                first_name TEXT,
                last_name TEXT,
                phone TEXT,
                location TEXT,
                role TEXT DEFAULT 'PUBLIC',
                is_active BOOLEAN DEFAULT 1,
                is_verified BOOLEAN DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP,
                last_login TIMESTAMP
            )
        ''')
        
        # Create incidents table if not exists
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS incidents (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                reference_id TEXT UNIQUE NOT NULL,
                hazard_type TEXT NOT NULL,
                location TEXT NOT NULL,
                latitude REAL,
                longitude REAL,
                description TEXT,
                urgency TEXT DEFAULT 'LOW',
                status TEXT DEFAULT 'PENDING',
                contact_info TEXT,
                photo_url TEXT,
                reporter_id INTEGER,
                verified_by_id INTEGER,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP,
                verified_at TIMESTAMP,
                resolved_at TIMESTAMP,
                FOREIGN KEY (reporter_id) REFERENCES users (id),
                FOREIGN KEY (verified_by_id) REFERENCES users (id)
            )
        ''')
        
        conn.commit()
        conn.close()
        print("✅ Database initialized successfully")
        return True
    except Exception as e:
        print(f"❌ Database initialization error: {e}")
        return False

def get_db_connection():
    """Get database connection"""
    return sqlite3.connect(DB_PATH)

def hash_password(password: str) -> str:
    """Simple password hashing"""
    return hashlib.sha256(password.encode()).hexdigest()

def create_user_in_db(username: str, email: str, password: str, first_name: str, last_name: str, phone: str = None, location: str = None):
    """Create a new user in the database - ENHANCED VERSION"""
    try:
        print(f"🔄 Creating user in database: {username}")
        conn = get_db_connection()
        cursor = conn.cursor()
        
        hashed_pw = hash_password(password)
        
        cursor.execute('''
            INSERT INTO users (username, email, hashed_password, first_name, last_name, phone, location, role, is_active, is_verified)
            VALUES (?, ?, ?, ?, ?, ?, ?, 'PUBLIC', 1, 0)
        ''', (username, email, hashed_pw, first_name, last_name, phone, location))
        
        user_id = cursor.lastrowid
        
        # CRITICAL: Ensure commit happens
        conn.commit()
        print(f"✅ User committed to database with ID: {user_id}")
        
        # Verify user was actually saved
        cursor.execute('SELECT COUNT(*) FROM users WHERE id = ?', (user_id,))
        if cursor.fetchone()[0] == 1:
            print(f"✅ User verification successful: {user_id}")
        else:
            print(f"❌ User verification failed: {user_id}")
        
        conn.close()
        
        return user_id
    except sqlite3.IntegrityError as e:
        print(f"❌ Database integrity error: {e}")
        if "username" in str(e):
            raise HTTPException(status_code=400, detail="Username already exists")
        elif "email" in str(e):
            raise HTTPException(status_code=400, detail="Email already exists")
        else:
            raise HTTPException(status_code=400, detail="User creation failed")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

def get_user_by_credentials(username: str, password: str):
    """Get user by username and password"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        hashed_pw = hash_password(password)
        
        cursor.execute('''
            SELECT id, username, email, first_name, last_name, role, is_active, created_at
            FROM users 
            WHERE username = ? AND hashed_password = ? AND is_active = 1
        ''', (username, hashed_pw))
        
        user_data = cursor.fetchone()
        conn.close()
        
        if user_data:
            return {
                "id": user_data[0],
                "username": user_data[1],
                "email": user_data[2],
                "first_name": user_data[3],
                "last_name": user_data[4],
                "full_name": f"{user_data[3]} {user_data[4]}",
                "role": user_data[5].lower(),
                "is_active": bool(user_data[6]),
                "created_at": user_data[7]
            }
        return None
    except Exception as e:
        print(f"Login error: {e}")
        return None

def get_all_users_from_db():
    """Get all users from database"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT id, username, email, first_name, last_name, role, is_active, created_at
            FROM users 
            WHERE is_active = 1
            ORDER BY created_at DESC
        ''')
        
        users = []
        for row in cursor.fetchall():
            users.append({
                "id": row[0],
                "username": row[1],
                "email": row[2],
                "first_name": row[3],
                "last_name": row[4],
                "full_name": f"{row[3]} {row[4]}",
                "role": row[5].lower(),
                "is_active": bool(row[6]),
                "created_at": row[7]
            })
        
        conn.close()
        return users
    except Exception as e:
        print(f"Get users error: {e}")
        return []

def get_incidents_from_db():
    """Get all incidents from database"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT id, reference_id, hazard_type, location, latitude, longitude, 
                   description, urgency, status, contact_info, photo_url, 
                   reporter_id, created_at, updated_at
            FROM incidents 
            ORDER BY created_at DESC
        ''')
        
        incidents = []
        for row in cursor.fetchall():
            incidents.append({
                "id": row[0],
                "reference_id": row[1],
                "hazard_type": row[2],
                "location": row[3],
                "latitude": row[4],
                "longitude": row[5],
                "description": row[6],
                "urgency": row[7],
                "status": row[8],
                "contact_info": row[9],
                "photo_url": row[10],
                "reporter_id": row[11],
                "created_at": row[12],
                "updated_at": row[13]
            })
        
        conn.close()
        return incidents
    except Exception as e:
        print(f"Get incidents error: {e}")
        return []

def get_user_incidents_from_db(user_id: int):
    """Get incidents for a specific user from database"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT id, reference_id, hazard_type, location, latitude, longitude, 
                   description, urgency, status, contact_info, photo_url, 
                   reporter_id, created_at, updated_at
            FROM incidents 
            WHERE reporter_id = ?
            ORDER BY created_at DESC
        ''', (user_id,))
        
        incidents = []
        for row in cursor.fetchall():
            incidents.append({
                "id": row[0],
                "reference_id": row[1],
                "hazard_type": row[2],
                "location": row[3],
                "latitude": row[4],
                "longitude": row[5],
                "description": row[6],
                "urgency": row[7],
                "status": row[8],
                "contact_info": row[9],
                "photo_url": row[10],
                "reporter_id": row[11],
                "created_at": row[12],
                "updated_at": row[13]
            })
        
        conn.close()
        return incidents
    except Exception as e:
        print(f"Get user incidents error: {e}")
        return []

# Initialize database on startup
init_db()

# In-memory user storage (keeping for backward compatibility with existing login logic)
USERS_DB = {
    1: {
        "id": 1,
        "username": "admin",
        "password": "admin",  # In production, this would be hashed
        "email": "admin@oceanguard.gov.in",
        "full_name": "Admin User",
        "first_name": "Admin",
        "last_name": "User",
        "role": "admin",
        "is_active": True,
        "created_at": "2025-09-20T10:00:00"
    },
    2: {
        "id": 2,
        "username": "user",
        "password": "user",
        "email": "user@oceanguard.gov.in",
        "full_name": "Gowshik S",
        "first_name": "Gowshik",
        "last_name": "S",
        "role": "citizen",  # Changed from 'public' to 'citizen'
        "is_active": True,
        "created_at": "2025-09-20T10:00:00"
    }
}

# In-memory reports storage (keyed by user_id)
REPORTS_DB = {}  # Will be populated by user_id

# Counter for generating new user IDs and report IDs
NEXT_USER_ID = 3
NEXT_REPORT_ID = 1

def get_user_from_token(authorization: str):
    """Helper function to get user from authorization token"""
    if not authorization or not authorization.startswith('Bearer '):
        return None
    
    token = authorization.split(' ')[1]
    try:
        # Simple token validation for mock implementation
        if token == 'fake-jwt-token-admin':
            return USERS_DB[1]  # Admin user
        elif token.startswith('fake-jwt-token-'):
            parts = token.replace('fake-jwt-token-', '').split('-')
            if len(parts) >= 2:
                user_id = int(parts[0])
                return USERS_DB.get(user_id)
    except (ValueError, IndexError):
        pass
    
    return None

def initialize_sample_data():
    """Initialize sample reports for existing users"""
    global NEXT_REPORT_ID
    
    # Sample reports for user with ID 2 (Gowshik S)
    REPORTS_DB[2] = [
        {
            "id": NEXT_REPORT_ID,
            "reference_id": f"OG-20250927124500-A{NEXT_REPORT_ID}B{NEXT_REPORT_ID}C{NEXT_REPORT_ID}D{NEXT_REPORT_ID}",
            "hazard_type": "high-waves",
            "location": "Marina Beach, Chennai",
            "latitude": 13.0494,
            "longitude": 80.2833,
            "description": "Observed unusually high waves near the Marina Beach shoreline. Waves are approximately 3-4 meters high and pose a risk to beachgoers. Strong winds and rough sea conditions.",
            "urgency": "high",
            "status": "resolved",
            "contact_info": "+91 9876543210",
            "photo_url": None,
            "created_at": "2025-09-27T12:45:00",
            "updated_at": "2025-09-27T18:30:00",
            "reporter_id": 2,
            "verified_by_id": 5,
            "reporter": {
                "id": 2,
                "full_name": "Gowshik S",
                "username": "user"
            }
        }
    ]
    NEXT_REPORT_ID += 1
    
    # Add more sample reports for user 2
    sample_reports = [
        {
            "hazard_type": "flooding",
            "location": "Panjim, Goa",
            "latitude": 15.4989,
            "longitude": 73.8278,
            "description": "Coastal flooding observed in the low-lying areas of Panjim. Water levels have risen due to high tide combined with recent heavy rainfall. Several streets are inundated.",
            "urgency": "medium",
            "status": "in_progress"
        },
        {
            "hazard_type": "debris",
            "location": "Kochi Beach, Kerala", 
            "latitude": 9.9312,
            "longitude": 76.2673,
            "description": "Large amount of plastic debris and fishing nets washed ashore. The debris is affecting marine life and making the beach unsafe for visitors.",
            "urgency": "low",
            "status": "verified"
        },
        {
            "hazard_type": "lost-vessel",
            "location": "Arabian Sea, 15 km off Mumbai Coast",
            "latitude": 18.9200,
            "longitude": 72.8300,
            "description": "Spotted a small fishing vessel drifting unmanned. The boat appears to be abandoned and poses a navigation hazard. No distress signals observed.",
            "urgency": "medium",
            "status": "pending"
        },
        {
            "hazard_type": "oil-spill",
            "location": "Visakhapatnam Port Area",
            "latitude": 17.6868,
            "longitude": 83.2185,
            "description": "Small oil spill detected near the port area. The spill appears to be from a cargo vessel and is spreading towards the shoreline. Marine life in the area may be at risk.",
            "urgency": "critical",
            "status": "false_alarm"
        }
    ]
    
    for sample in sample_reports:
        report = {
            "id": NEXT_REPORT_ID,
            "reference_id": f"OG-{datetime.now().strftime('%Y%m%d%H%M%S')}-{NEXT_REPORT_ID:08X}",
            "hazard_type": sample["hazard_type"],
            "location": sample["location"],
            "latitude": sample.get("latitude"),
            "longitude": sample.get("longitude"),
            "description": sample["description"],
            "urgency": sample["urgency"],
            "status": sample["status"],
            "contact_info": "+91 9876543210",
            "photo_url": None,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat(),
            "reporter_id": 2,
            "verified_by_id": None,
            "reporter": {
                "id": 2,
                "full_name": "Gowshik S",
                "username": "user"
            }
        }
        REPORTS_DB[2].append(report)
        NEXT_REPORT_ID += 1
    
    # Initialize empty reports for admin user
    REPORTS_DB[1] = []

# Initialize sample data
initialize_sample_data()

# Pydantic models
class LoginRequest(BaseModel):
    username: str
    password: str

class RegisterRequest(BaseModel):
    username: str
    email: str
    password: str
    first_name: str
    last_name: str

# Create FastAPI app
app = FastAPI(
    title="Ocean Hazard API",
    description="Coastal Safety Network API",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:5500", "http://localhost:5500"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files
app.mount("/styles", StaticFiles(directory="styles"), name="styles")
app.mount("/scripts", StaticFiles(directory="scripts"), name="scripts")
app.mount("/assets", StaticFiles(directory="assets"), name="assets")

# Serve HTML pages
@app.get("/pages/{page_name}")
async def serve_page(page_name: str):
    """Serve HTML pages from the pages directory"""
    page_path = f"pages/{page_name}"
    if os.path.exists(page_path) and page_name.endswith('.html'):
        return FileResponse(page_path)
    raise HTTPException(status_code=404, detail="Page not found")

@app.get("/test-login.html")
async def serve_test_login():
    """Serve the test login page"""
    if os.path.exists("test-login.html"):
        return FileResponse("test-login.html")
    raise HTTPException(status_code=404, detail="Test login page not found")

@app.get("/test-register.html")
async def serve_test_register():
    """Serve the test registration page"""
    if os.path.exists("test-register.html"):
        return FileResponse("test-register.html")
    raise HTTPException(status_code=404, detail="Test registration page not found")

@app.get("/test-auth.html")
async def serve_test_auth():
    """Serve the authentication debugging page"""
    if os.path.exists("test-auth.html"):
        return FileResponse("test-auth.html")
    raise HTTPException(status_code=404, detail="Test auth page not found")

@app.get("/")
async def root():
    return {"message": "Ocean Hazard API is running!"}

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "service": "Ocean Hazard API",
        "database": "SQLite"
    }

@app.post("/api/auth/login")
async def login(username: str = Form(...), password: str = Form(...)):
    """Login endpoint - accepts form data"""
    # Find user by username
    user = None
    for user_data in USERS_DB.values():
        if user_data["username"] == username and user_data["password"] == password:
            user = user_data
            break
    
    if user:
        # Create token (in production, use proper JWT)
        token = f"fake-jwt-token-{user['id']}-{user['username']}"
        
        return {
            "access_token": token,
            "token_type": "bearer",
            "user": {
                "id": user["id"],
                "username": user["username"],
                "role": user["role"],
                "first_name": user["first_name"],
                "last_name": user["last_name"],
                "full_name": user["full_name"],
                "email": user["email"],
                "is_active": user["is_active"]
            }
        }
    else:
        raise HTTPException(status_code=401, detail="Invalid credentials")

@app.post("/api/auth/login-json")
async def login_json(login_data: LoginRequest):
    """Login endpoint - accepts JSON data"""
    if login_data.username == "admin" and login_data.password == "admin":
        return {
            "access_token": "fake-jwt-token-admin",
            "token_type": "bearer",
            "user": {
                "id": 1,
                "username": "admin",
                "role": "admin",
                "first_name": "Admin",
                "last_name": "User"
            }
        }
    elif login_data.username == "user" and login_data.password == "user":
        return {
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
    else:
        raise HTTPException(status_code=401, detail="Invalid credentials")

@app.get("/api/auth/me")
async def get_current_user(authorization: str = Header(None)):
    """Get current user endpoint - returns user data based on token"""
    # Mock token validation - extract user info from token
    token = None
    if authorization and authorization.startswith('Bearer '):
        token = authorization.split(' ')[1]
    
    if token:
        # Parse token to get user ID (fake-jwt-token-{user_id}-{username})
        try:
            if token.startswith('fake-jwt-token-'):
                parts = token.replace('fake-jwt-token-', '').split('-')
                if len(parts) >= 2:
                    user_id = int(parts[0])
                    if user_id in USERS_DB:
                        user = USERS_DB[user_id]
                        return {
                            "id": user["id"],
                            "username": user["username"],
                            "email": user["email"],
                            "full_name": user["full_name"],
                            "first_name": user["first_name"],
                            "last_name": user["last_name"],
                            "role": user["role"],
                            "is_active": user["is_active"],
                            "created_at": user["created_at"]
                        }
        except (ValueError, IndexError):
            pass
    
    # Default fallback (for testing without proper auth)
    return {
        "id": 2,
        "username": "user",
        "email": "user@oceanguard.gov.in",
        "full_name": "Gowshik S",
        "first_name": "Gowshik",
        "last_name": "S",
        "role": "citizen",
        "is_active": True,
        "created_at": "2025-09-20T10:00:00"
    }

@app.post("/api/auth/register")
async def register(register_data: RegisterRequest):
    """Registration endpoint - now uses SQLite database"""
    
    # Simple validation
    if not register_data.username or not register_data.email or not register_data.password:
        raise HTTPException(status_code=400, detail="All fields are required")
    
    # Create user in database (this will handle duplicate checks)
    try:
        user_id = create_user_in_db(
            username=register_data.username,
            email=register_data.email,
            password=register_data.password,
            first_name=register_data.first_name,
            last_name=register_data.last_name,
            phone=getattr(register_data, 'phone', None),
            location=getattr(register_data, 'location', None)
        )
        
        # Return success response
        return {
            "message": "User registered successfully",
            "user": {
                "id": user_id,
                "username": register_data.username,
                "email": register_data.email,
                "first_name": register_data.first_name,
                "last_name": register_data.last_name,
                "full_name": f"{register_data.first_name} {register_data.last_name}",
                "role": "citizen",
                "is_active": True
            }
        }
        
    except HTTPException as e:
        # Re-raise HTTP exceptions (like duplicate username/email)
        raise e
    except Exception as e:
        # Handle any other errors
        raise HTTPException(status_code=500, detail=f"Registration failed: {str(e)}")

@app.get("/api/users")
async def get_all_users():
    """Get all users from database - for admin/debugging"""
    try:
        users = get_all_users_from_db()
        return {
            "users": users,
            "total": len(users),
            "message": "Users retrieved from SQLite database"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve users: {str(e)}")

@app.post("/api/auth/register-form")
async def register_form(
    username: str = Form(...),
    email: str = Form(...),
    password: str = Form(...),
    first_name: str = Form(...),
    last_name: str = Form(...)
):
    """Registration endpoint - accepts form data"""
    # Simple validation
    if not username or not email or not password:
        raise HTTPException(status_code=400, detail="All fields are required")
    
    # Check if user already exists (simplified)
    if username in ["admin", "user"]:
        raise HTTPException(status_code=400, detail="Username already exists")
    
    # Return success response
    return {
        "message": "User registered successfully",
        "user": {
            "id": 3,
            "username": username,
            "email": email,
            "first_name": first_name,
            "last_name": last_name,
            "role": "citizen"
        }
    }

@app.get("/api/incidents/")
async def get_incidents(authorization: str = Header(None)):
    """Admin-only incidents endpoint - returns all incidents from DATABASE"""
    # Check for admin authentication
    current_user = get_user_from_token(authorization)
    if not current_user or current_user.get('role') != 'admin':
        raise HTTPException(status_code=403, detail="Access denied: Admin privileges required")
    
    print(f"🔍 Getting all incidents from database...")
    
    # Get incidents from DATABASE instead of memory
    all_incidents = get_incidents_from_db()
    
    # If no incidents from database, fallback to in-memory
    if not all_incidents:
        for user_id, reports in REPORTS_DB.items():
            all_incidents.extend(reports)
        print(f"📋 Using fallback in-memory incidents: {len(all_incidents)} incidents")
    else:
        print(f"✅ Using database incidents: {len(all_incidents)} incidents")
    
    return {
        "incidents": all_incidents,
        "total": len(all_incidents),
        "page": 1,
        "size": len(all_incidents),
        "has_next": False,
        "has_prev": False,
        "source": "database" if all_incidents and len(get_incidents_from_db()) > 0 else "memory"
    }

@app.get("/api/my-reports/")
async def get_my_reports(authorization: str = Header(None)):
    """Citizen endpoint - returns user's own reports from DATABASE"""
    # Get current user from token
    current_user_id = 2  # default
    if authorization and authorization.startswith('Bearer '):
        token = authorization.split(' ')[1]
        try:
            if token.startswith('fake-jwt-token-'):
                parts = token.replace('fake-jwt-token-', '').split('-')
                if len(parts) >= 2:
                    current_user_id = int(parts[0])
        except (ValueError, IndexError):
            pass
    
    print(f"🔍 Getting reports for user ID: {current_user_id}")
    
    # Get reports from DATABASE instead of memory
    user_reports = get_user_incidents_from_db(current_user_id)
    
    # If no reports from database, fallback to in-memory for backward compatibility
    if not user_reports:
        user_reports = REPORTS_DB.get(current_user_id, [])
        print(f"📋 Using fallback in-memory reports: {len(user_reports)} reports")
    else:
        print(f"✅ Using database reports: {len(user_reports)} reports")
    
    return {
        "incidents": user_reports,
        "total": len(user_reports),
        "page": 1,
        "size": len(user_reports),
        "has_next": False,
        "has_prev": False,
        "source": "database" if user_reports and len(get_user_incidents_from_db(current_user_id)) > 0 else "memory"
    }
    return {
        "incidents": [
            {
                "id": 1,
                "reference_id": "OG-20250927124500-A1B2C3D4",
                "hazard_type": "high-waves",
                "location": "Marina Beach, Chennai",
                "latitude": 13.0494,
                "longitude": 80.2833,
                "description": "Observed unusually high waves near the Marina Beach shoreline. Waves are approximately 3-4 meters high and pose a risk to beachgoers. Strong winds and rough sea conditions.",
                "urgency": "high",
                "status": "resolved",
                "contact_info": "+91 9876543210",
                "photo_url": None,
                "created_at": "2025-09-27T12:45:00",
                "updated_at": "2025-09-27T18:30:00",
                "reporter_id": 2,
                "verified_by_id": 5,
                "reporter": {
                    "id": 2,
                    "full_name": "Gowshik S",
                    "username": "user"
                }
            },
            {
                "id": 2,
                "reference_id": "OG-20250926233000-E5F6G7H8",
                "hazard_type": "flooding",
                "location": "Panjim, Goa",
                "latitude": 15.4989,
                "longitude": 73.8278,
                "description": "Coastal flooding observed in the low-lying areas of Panjim. Water levels have risen due to high tide combined with recent heavy rainfall. Several streets are inundated.",
                "urgency": "medium",
                "status": "in_progress",
                "contact_info": "+91 9876543210",
                "photo_url": None,
                "created_at": "2025-09-26T23:30:00",
                "updated_at": "2025-09-27T08:15:00",
                "reporter_id": 2,
                "verified_by_id": 3,
                "reporter": {
                    "id": 2,
                    "full_name": "Gowshik S",
                    "username": "user"
                }
            },
            {
                "id": 3,
                "reference_id": "OG-20250925090000-I9J0K1L2",
                "hazard_type": "debris",
                "location": "Kochi Beach, Kerala",
                "latitude": 9.9312,
                "longitude": 76.2673,
                "description": "Large amount of plastic debris and fishing nets washed ashore. The debris is affecting marine life and making the beach unsafe for visitors.",
                "urgency": "low",
                "status": "verified",
                "contact_info": "+91 9876543210",
                "photo_url": None,
                "created_at": "2025-09-25T09:00:00",
                "updated_at": "2025-09-25T14:22:00",
                "reporter_id": 2,
                "verified_by_id": None,
                "reporter": {
                    "id": 2,
                    "full_name": "Gowshik S",
                    "username": "user"
                }
            },
            {
                "id": 4,
                "reference_id": "OG-20250924163000-M3N4O5P6",
                "hazard_type": "lost-vessel",
                "location": "Arabian Sea, 15 km off Mumbai Coast",
                "latitude": 18.9200,
                "longitude": 72.8300,
                "description": "Spotted a small fishing vessel drifting unmanned. The boat appears to be abandoned and poses a navigation hazard. No distress signals observed.",
                "urgency": "medium",
                "status": "pending",
                "contact_info": "+91 9876543210",
                "photo_url": None,
                "created_at": "2025-09-24T16:30:00",
                "updated_at": "2025-09-24T16:30:00",
                "reporter_id": 2,
                "verified_by_id": None,
                "reporter": {
                    "id": 2,
                    "full_name": "Gowshik S",
                    "username": "user"
                }
            },
            {
                "id": 5,
                "reference_id": "OG-20250923110000-Q7R8S9T0",
                "hazard_type": "oil-spill",
                "location": "Visakhapatnam Port Area",
                "latitude": 17.6868,
                "longitude": 83.2185,
                "description": "Small oil spill detected near the port area. The spill appears to be from a cargo vessel and is spreading towards the shoreline. Marine life in the area may be at risk.",
                "urgency": "critical",
                "status": "false_alarm",
                "contact_info": "+91 9876543210",
                "photo_url": None,
                "created_at": "2025-09-23T11:00:00",
                "updated_at": "2025-09-23T15:45:00",
                "reporter_id": 2,
                "verified_by_id": 4,
                "reporter": {
                    "id": 2,
                    "full_name": "Gowshik S",
                    "username": "user"
                }
            }
        ],
        "total": 5,
        "page": 1,
        "size": 10,
        "has_next": False,
        "has_prev": False
    }

@app.post("/api/incidents/")
async def create_incident(incident_data: dict, authorization: str = Header(None)):
    """Create incident endpoint"""
    global NEXT_REPORT_ID
    
    # Get current user from token
    current_user_id = 2  # default
    current_user = USERS_DB[2]  # default
    
    if authorization and authorization.startswith('Bearer '):
        token = authorization.split(' ')[1]
        try:
            if token.startswith('fake-jwt-token-'):
                parts = token.replace('fake-jwt-token-', '').split('-')
                if len(parts) >= 2:
                    user_id = int(parts[0])
                    if user_id in USERS_DB:
                        current_user_id = user_id
                        current_user = USERS_DB[user_id]
        except (ValueError, IndexError):
            pass
    
    # Generate reference ID
    reference_id = f"OG-{datetime.now().strftime('%Y%m%d%H%M%S')}-{NEXT_REPORT_ID:08X}"
    
    # Create new report
    new_report = {
        "id": NEXT_REPORT_ID,
        "reference_id": reference_id,
        "hazard_type": incident_data.get("hazard_type", "other"),
        "location": incident_data.get("location", "Unknown Location"),
        "latitude": incident_data.get("latitude"),
        "longitude": incident_data.get("longitude"),
        "description": incident_data.get("description", "No description provided"),
        "urgency": incident_data.get("urgency", "low"),
        "status": "pending",
        "contact_info": incident_data.get("contact_info"),
        "photo_url": None,
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat(),
        "reporter_id": current_user_id,
        "verified_by_id": None,
        "reporter": {
            "id": current_user["id"],
            "full_name": current_user["full_name"],
            "username": current_user["username"]
        }
    }
    
    # Add to user's reports
    if current_user_id not in REPORTS_DB:
        REPORTS_DB[current_user_id] = []
    REPORTS_DB[current_user_id].append(new_report)
    
    # Increment report ID
    NEXT_REPORT_ID += 1
    
    return {
        "id": new_report["id"],
        "message": "Incident reported successfully",
        "reference_id": reference_id,
        "status": "pending"
    }

# Admin endpoints for rescue teams and authorities
@app.get("/api/admin/teams/")
async def get_rescue_teams(authorization: str = Header(None)):
    """Admin endpoint - get all rescue teams"""
    current_user = get_user_from_token(authorization)
    if not current_user or current_user.get('role') != 'admin':
        raise HTTPException(status_code=403, detail="Access denied: Admin privileges required")
    
    # Return mock teams data (in production, this would come from database)
    return {
        "teams": [
            {
                "id": 1,
                "name": "Chennai Marine Rescue Unit",
                "leader": "Captain Rajesh Kumar",
                "email": "cmru@coastguard.gov.in",
                "phone": "+91 9876543210",
                "location": "Chennai Port, Tamil Nadu",
                "type": "coast-guard",
                "status": "active",
                "equipment": "Rescue boats, diving equipment, medical supplies, communication systems",
                "created_at": "2025-09-29T10:00:00"
            }
        ]
    }

@app.post("/api/admin/teams/")
async def add_rescue_team(team_data: dict, authorization: str = Header(None)):
    """Admin endpoint - add new rescue team"""
    current_user = get_user_from_token(authorization)
    if not current_user or current_user.get('role') != 'admin':
        raise HTTPException(status_code=403, detail="Access denied: Admin privileges required")
    
    # In production, save to database
    return {
        "message": "Rescue team added successfully",
        "team_id": team_data.get("id", 1)
    }

@app.get("/api/admin/authorities/")
async def get_authorities(authorization: str = Header(None)):
    """Admin endpoint - get all authorities"""
    current_user = get_user_from_token(authorization)
    if not current_user or current_user.get('role') != 'admin':
        raise HTTPException(status_code=403, detail="Access denied: Admin privileges required")
    
    # Return mock authorities data
    return {
        "authorities": [
            {
                "id": 1,
                "name": "Dr. Vikram Singh",
                "position": "Director General",
                "email": "dg@coastguard.gov.in",
                "phone": "+91 11-23386100",
                "department": "Indian Coast Guard",
                "level": "national",
                "status": "active",
                "jurisdiction": "National maritime security and rescue operations",
                "created_at": "2025-09-29T10:00:00"
            }
        ]
    }

@app.post("/api/admin/authorities/")
async def add_authority(authority_data: dict, authorization: str = Header(None)):
    """Admin endpoint - add new authority"""
    current_user = get_user_from_token(authorization)
    if not current_user or current_user.get('role') != 'admin':
        raise HTTPException(status_code=403, detail="Access denied: Admin privileges required")
    
    # In production, save to database
    return {
        "message": "Authority added successfully",
        "authority_id": authority_data.get("id", 1)
    }

@app.get("/api/analytics/")
async def get_analytics():
    """Analytics endpoint"""
    return {
        "total_incidents": 15,
        "active_incidents": 3,
        "resolved_incidents": 12,
        "incidents_by_type": {
            "high-waves": 5,
            "flooding": 4,
            "debris": 3,
            "other": 3
        },
        "response_time_avg": 2.5
    }

if __name__ == "__main__":
    print("🌊 Starting Ocean Hazard Simple Server...")
    print("=" * 50)
    print(f"Database URL: {os.getenv('DATABASE_URL', 'Not set')}")
    print(f"Server will run on: http://127.0.0.1:8002")
    print("=" * 50)
    
    uvicorn.run(app, host="127.0.0.1", port=8004, reload=False)
