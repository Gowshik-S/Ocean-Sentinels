"""
Ocean Hazard FastAPI Backend
Main application entry point
"""

from dotenv import load_dotenv
from pathlib import Path
import os

# Load environment variables FIRST before any imports that use them
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager
import uvicorn

from app.database import engine, Base
from app.routers import auth, incidents, users, analytics, websocket
from app.core.config import settings
from sqlalchemy import text

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events"""
    # Startup
    print("🚀 Starting Ocean Hazard Backend...")
    print(f"📊 Settings: HOST={settings.HOST}, PORT={settings.PORT}")
    print(f"🔗 Database URL: {settings.DATABASE_URL[:50]}..." if settings.DATABASE_URL else "❌ No DATABASE_URL")
    
    try:
        # Create database tables
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        print("✅ Database tables created successfully")
        print("🌊 Ocean Hazard Backend is ready!")
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        print("⚠️  Continuing without database (app will have limited functionality)")
    
    yield
    
    # Shutdown
    print("🛑 Shutting down Ocean Hazard Backend...")

# Create FastAPI application
app = FastAPI(
    title="Ocean Hazard API",
    description="Coastal Safety Network API for India's Ministry of Earth Sciences",
    version="1.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    lifespan=lifespan
)

# CORS middleware - Allow all origins temporarily for debugging
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,  # Must be False when using "*"
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(incidents.router, prefix="/api/incidents", tags=["Incidents"])
app.include_router(users.router, prefix="/api/users", tags=["Users"])
app.include_router(analytics.router, prefix="/api/analytics", tags=["Analytics"])
app.include_router(websocket.router, prefix="/api/ws", tags=["WebSocket"])

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
    try:
        # Test database connection
        async with engine.begin() as conn:
            await conn.execute(text("SELECT 1"))
        db_status = "connected"
    except Exception as e:
        print(f"⚠️  Database health check failed: {e}")
        db_status = f"error: {str(e)}"
    
    return {
        "status": "healthy",
        "service": "Ocean Hazard API",
        "database": db_status,
        "host": settings.HOST,
        "port": settings.PORT,
        "timestamp": "2025-10-13T10:30:00Z"
    }

# Mapbox token endpoint
@app.get("/api/config/mapbox-token")
async def get_mapbox_token():
    return {"token": settings.MAPBOX_ACCESS_TOKEN}

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG
    )

