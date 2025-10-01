#!/usr/bin/env python3
"""
Debug database table creation
"""

import asyncio
import sys
import os
from dotenv import load_dotenv

# Add backend to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend'))

async def debug_database():
    """Debug database table creation"""
    try:
        # Load environment variables
        load_dotenv("backend/env.local")
        
        from app.database.database import engine, Base
        from app.models.user import User
        from app.models.incident import Incident
        from app.models.analytics import AnalyticsSnapshot, SystemMetrics
        
        print("🔍 Debugging database table creation...")
        print(f"Database URL: {os.getenv('DATABASE_URL', 'Not set')}")
        
        # Check if models are imported
        print(f"✅ User model: {User}")
        print(f"✅ Incident model: {Incident}")
        print(f"✅ AnalyticsSnapshot model: {AnalyticsSnapshot}")
        print(f"✅ SystemMetrics model: {SystemMetrics}")
        
        # Check Base metadata
        print(f"📊 Tables in metadata: {list(Base.metadata.tables.keys())}")
        
        # Create tables
        print("\n📊 Creating database tables...")
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        
        print("✅ Database tables created successfully!")
        
        # Check if tables exist
        from sqlalchemy import text
        async with engine.begin() as conn:
            result = await conn.execute(text("SELECT name FROM sqlite_master WHERE type='table'"))
            tables = [row[0] for row in result.fetchall()]
            print(f"📋 Tables in database: {tables}")
        
        return True
        
    except Exception as e:
        print(f"❌ Debug failed: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    asyncio.run(debug_database())
