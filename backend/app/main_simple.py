"""
Ocean Hazard FastAPI Backend - Simple Version
Main application entry point without database dependency
"""

from fastapi import FastAPI, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from contextlib import asynccontextmanager
from typing import Optional
import uvicorn
import os
import hashlib
import secrets as _secrets
from dotenv import load_dotenv

# Load environment variables
load_dotenv(".env")

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events"""
    # Startup
    print("Starting Ocean Hazard Backend...")
    print("Ocean Hazard Backend is ready!")
    
    yield
    
    # Shutdown
    print("Shutting down Ocean Hazard Backend...")

# Create FastAPI application
app = FastAPI(
    title="Ocean Hazard API",
    description="Coastal Safety Network API for India's Ministry of Earth Sciences",
    version="1.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    lifespan=lifespan
)

# CORS middleware - Allow all origins for development/deployment compatibility
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Root endpoint
@app.get("/")
async def root():
    return {
        "message": "Ocean Hazard API - Coastal Safety Network",
        "version": "1.0.0",
        "status": "operational",
        "government": "Ministry of Earth Sciences, Government of India"
    }

# Health check endpoint
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "Ocean Hazard API",
        "timestamp": "2025-01-27T10:30:00Z"
    }

# Demo credentials from environment variables
DEMO_ADMIN_USER = os.environ.get("DEMO_ADMIN_USER", "admin")
DEMO_ADMIN_PASS = os.environ.get("DEMO_ADMIN_PASS", "")
DEMO_USER_USER = os.environ.get("DEMO_USER_USER", "user")
DEMO_USER_PASS = os.environ.get("DEMO_USER_PASS", "")

def _generate_token(role: str) -> str:
    return hashlib.sha256(f"{_secrets.token_hex(16)}-{role}".encode()).hexdigest()

# In-memory user store for simple registration (no database)
_registered_users = {}

# Pydantic model for registration request body
class SimpleUserCreate(BaseModel):
    username: str
    email: str
    password: str
    first_name: str
    last_name: str
    phone: Optional[str] = None
    location: Optional[str] = None
    role: Optional[str] = "public"

# Simple authentication endpoint
@app.post("/api/auth/login")
async def login(username: str = Form(...), password: str = Form(...)):
    """Simple login endpoint — accepts form data (OAuth2 password flow compatible)"""
    # First check in-memory registered users
    username = username.strip()
    if username in _registered_users:
        stored = _registered_users[username]
        stored_hash = hashlib.sha256(stored["password"].encode()).hexdigest()
        input_hash = hashlib.sha256(password.encode()).hexdigest()
        if stored_hash == input_hash:
            return {
                "access_token": _generate_token(stored.get("role", "public")),
                "token_type": "bearer",
                "user": {
                    "id": stored.get("id", 100),
                    "username": username,
                    "email": stored.get("email", username),
                    "role": stored.get("role", "public"),
                    "first_name": stored.get("first_name", "User"),
                    "last_name": stored.get("last_name", ""),
                    "is_active": True,
                    "is_verified": False
                }
            }
        else:
            raise HTTPException(status_code=401, detail="Incorrect username or password")

    # Then check demo credentials from env vars
    if not DEMO_ADMIN_PASS and not DEMO_USER_PASS:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    if username == DEMO_ADMIN_USER and password == DEMO_ADMIN_PASS:
        return {
            "access_token": _generate_token("admin"),
            "token_type": "bearer",
            "user": {
                "id": 1,
                "username": DEMO_ADMIN_USER,
                "role": "admin",
                "first_name": "Admin",
                "last_name": "User"
            }
        }
    elif username == DEMO_USER_USER and password == DEMO_USER_PASS:
        return {
            "access_token": _generate_token("user"),
            "token_type": "bearer",
            "user": {
                "id": 2,
                "username": DEMO_USER_USER,
                "role": "public",
                "first_name": "Test",
                "last_name": "User"
            }
        }
    else:
        raise HTTPException(status_code=401, detail="Incorrect username or password")

# Simple registration endpoint
@app.post("/api/auth/register")
async def register(user_data: SimpleUserCreate):
    """Simple registration endpoint — stores users in memory (no database)"""
    username = user_data.username.strip()
    email = user_data.email.strip()

    # Check if username already exists
    if username in _registered_users:
        raise HTTPException(status_code=400, detail="Username already registered")

    # Check if email already exists
    for stored_user in _registered_users.values():
        if stored_user.get("email") == email:
            raise HTTPException(status_code=400, detail="Email already registered")

    # Validate password
    if len(user_data.password) < 6:
        raise HTTPException(status_code=422, detail="Password must be at least 6 characters long")

    # Store user
    user_id = len(_registered_users) + 100
    _registered_users[username] = {
        "id": user_id,
        "username": username,
        "email": email,
        "password": user_data.password,
        "first_name": user_data.first_name,
        "last_name": user_data.last_name,
        "phone": user_data.phone,
        "location": user_data.location,
        "role": "public",  # Always public for self-registration
        "is_active": True,
        "is_verified": False,
    }

    print(f"User registered: {username} ({email})")
    return {
        "id": user_id,
        "username": username,
        "email": email,
        "first_name": user_data.first_name,
        "last_name": user_data.last_name,
        "phone": user_data.phone,
        "location": user_data.location,
        "role": "public",
        "is_active": True,
        "is_verified": False,
    }

# Simple logout endpoint
@app.post("/api/auth/logout")
async def logout():
    """Logout endpoint — client should discard token"""
    return {"message": "Successfully logged out"}

# Simple incidents endpoint
@app.get("/api/incidents/")
async def get_incidents():
    """Simple incidents endpoint for testing"""
    return {
        "incidents": [
            {
                "id": 1,
                "reference_id": "OG-20250127-001",
                "hazard_type": "high-waves",
                "location": "Marina Beach, Chennai",
                "status": "pending",
                "created_at": "2025-01-27T10:30:00Z"
            }
        ],
        "total": 1,
        "page": 1,
        "size": 10,
        "has_next": False,
        "has_prev": False
    }

if __name__ == "__main__":
    uvicorn.run(
        "app.main_simple:app",
        host="127.0.0.1",
        port=8000,
        reload=True
    )


