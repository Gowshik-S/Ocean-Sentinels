#!/usr/bin/env python3
"""
Simple Database Test for Ocean Hazard
Test basic database operations without complex relationships
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

async def test_simple_operations():
    """Test simple database operations"""
    try:
        from app.database.database import AsyncSessionLocal
        from app.models.user import User
        from sqlalchemy import text
        
        print("\n🧪 Testing simple database operations...")
        
        async with AsyncSessionLocal() as session:
            # Test simple query
            result = await session.execute(text("SELECT COUNT(*) FROM users"))
            user_count = result.scalar()
            print(f"📊 Total users in database: {user_count}")
            
            # Test user creation (simple)
            test_user = User(
                username="test_user_simple",
                email="test_simple@example.com",
                hashed_password="hashed_password",
                first_name="Test",
                last_name="User"
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
    print("🌊 Ocean Hazard - Simple Database Test")
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
    
    # Test 3: Simple operations
    operations_ok = await test_simple_operations()
    
    if operations_ok:
        print("\n🎉 All database tests passed!")
        print("✅ Your local database is ready for the Ocean Hazard application")
        print("\n🚀 Next steps:")
        print("1. Start your application: python start_server.py")
        print("2. Test the API endpoints")
        print("3. Check the frontend integration")
    else:
        print("\n❌ Some database tests failed")
        print("🔧 Please check your database configuration")

if __name__ == "__main__":
    asyncio.run(main())


