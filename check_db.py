"""
Quick script to check if the backend is using AWS RDS or local SQLite
"""
import asyncio
import sys
import os

# Add backend to path so we can import the app modules
sys.path.append(os.path.join(os.path.dirname(__file__), 'backend'))

async def check_database():
    try:
        from app.core.config import settings
        from app.database.database import engine
        from sqlalchemy import text
        
        print("🔍 Checking database configuration...")
        print(f"DATABASE_URL from settings: {settings.DATABASE_URL}")
        print(f"Engine URL: {engine.url}")
        
        # Determine DB type from URL
        url_str = str(engine.url)
        if "postgresql" in url_str:
            print("📋 Configuration: PostgreSQL (AWS RDS)")
        elif "sqlite" in url_str:
            print("📋 Configuration: SQLite (Local)")
        else:
            print(f"📋 Configuration: Unknown DB type - {url_str}")
        
        print("\n🔗 Testing actual connection...")
        
        async with engine.begin() as conn:
            # Try PostgreSQL version check
            try:
                result = await conn.execute(text("SELECT version()"))
                version = await result.scalar()
                if version and "PostgreSQL" in version:
                    print("✅ CONNECTED TO: PostgreSQL (AWS RDS)")
                    print(f"   Version: {version.split()[1]}")
                    
                    # Get database name
                    db_result = await conn.execute(text("SELECT current_database()"))
                    db_name = await db_result.scalar()
                    print(f"   Database: {db_name}")
                    
                    return "postgresql"
            except Exception as e:
                print(f"   PostgreSQL check failed: {e}")
            
            # Try SQLite version check
            try:
                result = await conn.execute(text("SELECT sqlite_version()"))
                version = await result.scalar()
                if version:
                    print("✅ CONNECTED TO: SQLite (Local)")
                    print(f"   Version: {version}")
                    return "sqlite"
            except Exception as e:
                print(f"   SQLite check failed: {e}")
                
            print("❌ Could not determine database type from queries")
            return "unknown"
            
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        print("\nPossible issues:")
        print("- RDS security group not allowing connections (port 5432)")
        print("- Incorrect credentials in env.local")
        print("- RDS instance not running")
        print("- Network connectivity issues")
        return "failed"

if __name__ == "__main__":
    result = asyncio.run(check_database())
    print(f"\n🎯 Result: {result}")