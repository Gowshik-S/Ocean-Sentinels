#!/usr/bin/env python3
"""
Start Ocean Hazard Server with Database
This script starts the FastAPI server with full database integration
"""

import uvicorn
import sys
import os
from dotenv import load_dotenv

# Add backend to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend'))

# Load environment variables
load_dotenv("backend/env.local")

# Import the main FastAPI app
from app.main import app

if __name__ == "__main__":
    print("🌊 Starting Ocean Hazard Server with Database...")
    print("=" * 50)
    print(f"Database URL: {os.getenv('DATABASE_URL', 'Not set')}")
    print(f"Server will run on: http://127.0.0.1:8002")
    print("=" * 50)
    
    # Fix database path for when running from root directory
    os.chdir("backend")
    
    uvicorn.run(
        app, 
        host="127.0.0.1", 
        port=8002,
        reload=False,  # Fixed: disable reload to avoid import issues
        log_level="info"
    )

