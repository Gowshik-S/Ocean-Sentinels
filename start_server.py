"""
Simple FastAPI server startup script
"""
import uvicorn
from fastapi import FastAPI, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# Pydantic models
class LoginRequest(BaseModel):
    username: str
    password: str

# Create FastAPI application
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

@app.get("/")
async def root():
    return {
        "message": "Ocean Hazard API - Coastal Safety Network",
        "version": "1.0.0",
        "status": "operational"
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "Ocean Hazard API"
    }

@app.post("/api/auth/login")
async def login(login_data: LoginRequest):
    """Simple login endpoint"""
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
                "role": "public",
                "first_name": "Test",
                "last_name": "User"
            }
        }
    else:
        raise HTTPException(status_code=401, detail="Invalid credentials")

@app.get("/api/incidents/")
async def get_incidents():
    """Simple incidents endpoint"""
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
        "size": 10
    }

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8002)
