#!/usr/bin/env python3
"""
Database Connection Test
Tests the Ocean Hazard database connection and shows database information
"""

import asyncio
import sqlite3
import os
import sys
from pathlib import Path

def test_sqlite_connection():
    """Test direct SQLite connection"""
    print("🔍 Testing Direct SQLite Connection...")
    print("=" * 50)
    
    # Get database path
    db_path = "F:\\SEN PRJ\\Ocean-Hazard\\backend\\database\\ocean_hazard.db"
    
    try:
        # Check if file exists
        if not os.path.exists(db_path):
            print(f"❌ Database file not found at: {db_path}")
            return False
            
        print(f"✅ Database file found at: {db_path}")
        print(f"📁 File size: {os.path.getsize(db_path)} bytes")
        
        # Connect to database
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Get database info
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = cursor.fetchall()
        
        print(f"📊 Tables in database: {len(tables)}")
        for table in tables:
            print(f"   📋 Table: {table[0]}")
            
            # Get row count for each table
            try:
                cursor.execute(f"SELECT COUNT(*) FROM {table[0]}")
                count = cursor.fetchone()[0]
                print(f"      📈 Rows: {count}")
            except Exception as e:
                print(f"      ❌ Error counting rows: {e}")
        
        # Test users table specifically
        try:
            cursor.execute("SELECT id, username, role FROM users LIMIT 5")
            users = cursor.fetchall()
            print(f"\n👥 Sample users:")
            for user in users:
                print(f"   🔹 ID: {user[0]}, Username: {user[1]}, Role: {user[2]}")
        except Exception as e:
            print(f"\n❌ Error reading users table: {e}")
            
        # Test incidents table
        try:
            cursor.execute("SELECT id, title, status FROM incidents LIMIT 5")
            incidents = cursor.fetchall()
            print(f"\n📋 Sample incidents:")
            for incident in incidents:
                print(f"   🔹 ID: {incident[0]}, Title: {incident[1]}, Status: {incident[2]}")
        except Exception as e:
            print(f"\n❌ Error reading incidents table: {e}")
        
        conn.close()
        print("\n✅ Direct SQLite connection test completed successfully!")
        return True
        
    except Exception as e:
        print(f"❌ Error testing SQLite connection: {e}")
        return False

async def test_async_connection():
    """Test async SQLite connection like the app uses"""
    print("\n🔍 Testing Async SQLite Connection (like the app)...")
    print("=" * 50)
    
    try:
        # Add backend to path
        sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend'))
        
        from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
        from sqlalchemy import text
        
        # Create async engine with the same configuration as the app
        database_url = "sqlite+aiosqlite:///backend/database/ocean_hazard.db"
        print(f"🔗 Database URL: {database_url}")
        
        engine = create_async_engine(
            database_url,
            echo=True,  # Enable SQL logging
            future=True
        )
        
        # Create session
        AsyncSessionLocal = async_sessionmaker(
            engine,
            class_=AsyncSession,
            expire_on_commit=False
        )
        
        async with AsyncSessionLocal() as session:
            # Test basic query
            result = await session.execute(text("SELECT 1 as test"))
            test_result = result.fetchone()
            print(f"✅ Basic query test: {test_result}")
            
            # Test table existence
            result = await session.execute(text("SELECT name FROM sqlite_master WHERE type='table'"))
            tables = result.fetchall()
            print(f"📊 Tables found via async: {[table[0] for table in tables]}")
            
        await engine.dispose()
        print("✅ Async SQLite connection test completed successfully!")
        return True
        
    except Exception as e:
        print(f"❌ Error testing async connection: {e}")
        import traceback
        traceback.print_exc()
        return False

def check_environment_config():
    """Check environment configuration"""
    print("\n🔍 Checking Environment Configuration...")
    print("=" * 50)
    
    # Check env files
    env_files = [
        "backend/env.local",
        "backend/env.example"
    ]
    
    for env_file in env_files:
        if os.path.exists(env_file):
            print(f"✅ Found: {env_file}")
            try:
                with open(env_file, 'r') as f:
                    lines = f.readlines()
                    for line in lines:
                        if 'DATABASE_URL' in line and not line.strip().startswith('#'):
                            print(f"   🔗 {line.strip()}")
            except Exception as e:
                print(f"   ❌ Error reading {env_file}: {e}")
        else:
            print(f"❌ Missing: {env_file}")

def main():
    """Main test function"""
    print("🌊 Ocean Hazard Database Connection Test")
    print("=" * 60)
    
    # Check environment config
    check_environment_config()
    
    # Test direct SQLite connection
    sqlite_success = test_sqlite_connection()
    
    # Test async connection
    async_success = asyncio.run(test_async_connection())
    
    # Summary
    print("\n📋 Test Summary:")
    print("=" * 30)
    print(f"Direct SQLite Connection: {'✅ PASS' if sqlite_success else '❌ FAIL'}")
    print(f"Async SQLite Connection:  {'✅ PASS' if async_success else '❌ FAIL'}")
    
    if sqlite_success and async_success:
        print("\n🎉 All database tests passed! Database is working correctly.")
    else:
        print("\n⚠️ Some tests failed. Check the error messages above.")

if __name__ == "__main__":
    main()