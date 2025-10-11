"""
Check enum values in the database
"""
import asyncio
import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), 'backend'))

async def check_enums():
    try:
        from app.database.database import engine
        from sqlalchemy import text
        
        print("🔍 Checking enum values...")
        
        async with engine.begin() as conn:
            # Check user role enum values
            result = await conn.execute(text("""
                SELECT enumlabel FROM pg_enum 
                WHERE enumtypid = (SELECT oid FROM pg_type WHERE typname = 'userrole')
                ORDER BY enumlabel
            """))
            
            roles = result.fetchall()
            print("📋 Valid user roles:")
            for role in roles:
                print(f"   - {role[0]}")
                
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    asyncio.run(check_enums())