#!/usr/bin/env python3
"""
Test Server for Ocean Hazard
Simple server to test database connection and API
"""

import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import sys
import os
from dotenv import load_dotenv

# Add backend to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend'))

# Load environment variables
load_dotenv("backend/env.local")

# Create FastAPI app
app = FastAPI(title="Ocean Hazard Test API")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:5500", "http://localhost:5500"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "Ocean Hazard Test API is running!"}

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "service": "Ocean Hazard Test API",
        "database": "SQLite"
    }

@app.post("/api/auth/login")
async def login(login_data: dict):
    """Simple login endpoint"""
    username = login_data.get("username")
    password = login_data.get("password")
    
    if username == "admin" and password == "admin":
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
    elif username == "user" and password == "user":
        return {
            "access_token": "fake-jwt-token-user",
            "token_type": "bearer",
            "user": {
                "id": 2,
                "username": "user",
                "role": "public",
                "first_name": "Test",
                "last_name": "User"
            }
        }
    else:
        return {"error": "Invalid credentials"}

@app.get("/api/incidents/")
async def get_incidents():
    """Simple incidents endpoint"""
    return {
        "incidents": [
            {
                "id": 1,
                "title": "High Waves Alert",
                "description": "Dangerous waves detected",
                "status": "active",
                "location": "Beach Area 1"
            }
        ],
        "total": 1,
        "page": 1,
        "size": 10
    }

if __name__ == "__main__":
    print("🌊 Starting Ocean Hazard Test Server...")
    print("=" * 50)
    print(f"Database URL: {os.getenv('DATABASE_URL', 'Not set')}")
    print(f"Server will run on: http://127.0.0.1:8002")
    print("=" * 50)
    
    uvicorn.run(app, host="127.0.0.1", port=8002, reload=True)
