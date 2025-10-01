#!/usr/bin/env python3
"""
Test AWS RDS Database Connection
Run this script to test your database connection
"""

import asyncio
import sys
import os
from dotenv import load_dotenv

# Add backend to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend'))

async def test_database_connection():
    """Test the database connection"""
    try:
        # Load environment variables
        load_dotenv("backend/env.local")
        
        from app.database.database import engine
        from sqlalchemy import text
        
        print("🔌 Testing database connection...")
        print(f"Database URL: {os.getenv('DATABASE_URL', 'Not set')}")
        
        # Test connection
        async with engine.begin() as conn:
            result = await conn.execute(text('SELECT 1 as test'))
            test_value = result.scalar()
            
            if test_value == 1:
                print("✅ Database connection successful!")
                return True
            else:
                print("❌ Database connection test failed")
                return False
                
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        print("\n🔧 Troubleshooting:")
        print("1. Check your DATABASE_URL in backend/env.local")
        print("2. Verify your AWS RDS instance is running")
        print("3. Check security group rules")
        print("4. Ensure database credentials are correct")
        return False

async def create_database_tables():
    """Create database tables"""
    try:
        from app.database.database import engine, Base
        
        print("\n📊 Creating database tables...")
        
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        
        print("✅ Database tables created successfully!")
        return True
        
    except Exception as e:
        print(f"❌ Error creating tables: {e}")
        return False

async def test_database_operations():
    """Test basic database operations"""
    try:
        from app.database.database import AsyncSessionLocal
        from app.models.user import User
        from app.models.incident import Incident
        
        print("\n🧪 Testing database operations...")
        
        async with AsyncSessionLocal() as session:
            # Test user creation
            test_user = User(
                username="test_user",
                email="test@example.com",
                first_name="Test",
                last_name="User",
                role="public"
            )
            session.add(test_user)
            await session.commit()
            
            # Test user retrieval
            user = await session.get(User, test_user.id)
            if user:
                print("✅ User creation and retrieval successful!")
                
                # Clean up test user
                await session.delete(user)
                await session.commit()
                print("✅ Test cleanup successful!")
                return True
            else:
                print("❌ User retrieval failed")
                return False
                
    except Exception as e:
        print(f"❌ Database operations test failed: {e}")
        return False

async def main():
    """Main test function"""
    print("🌊 Ocean Hazard - Database Connection Test")
    print("=" * 50)
    
    # Test 1: Connection
    connection_ok = await test_database_connection()
    
    if not connection_ok:
        print("\n❌ Cannot proceed without database connection")
        return
    
    # Test 2: Create tables
    tables_ok = await create_database_tables()
    
    if not tables_ok:
        print("\n❌ Cannot proceed without database tables")
        return
    
    # Test 3: Database operations
    operations_ok = await test_database_operations()
    
    if operations_ok:
        print("\n🎉 All database tests passed!")
        print("✅ Your database is ready for the Ocean Hazard application")
    else:
        print("\n❌ Some database tests failed")
        print("🔧 Please check your database configuration")

if __name__ == "__main__":
    asyncio.run(main())
