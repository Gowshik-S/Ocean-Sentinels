"""
Ocean Hazard FastAPI Backend - Simple Version
Main application entry point without database dependency
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
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

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:5500", "http://localhost:5500"],
    allow_credentials=True,
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

# Simple authentication endpoint
@app.post("/api/auth/login")
async def login(username: str, password: str):
    """Simple login endpoint — set DEMO_ADMIN_PASS and DEMO_USER_PASS env vars"""
    if not DEMO_ADMIN_PASS and not DEMO_USER_PASS:
        raise HTTPException(status_code=503, detail="Demo credentials not configured. Set DEMO_ADMIN_PASS / DEMO_USER_PASS env vars.")
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
        raise HTTPException(status_code=401, detail="Invalid credentials")

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


