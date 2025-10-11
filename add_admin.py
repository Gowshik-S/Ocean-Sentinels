"""
Create admin user directly in AWS RDS database
Username: OceanAdmin, Password: admin, Email: admin@vi.com
"""
import asyncio
import sys
import os
from datetime import datetime

# Add backend to path
sys.path.append(os.path.join(os.path.dirname(__file__), 'backend'))

async def create_admin():
    try:
        from app.database.database import engine
        from app.core.security import get_password_hash
        from sqlalchemy import text
        
        print("🔍 Creating admin user in AWS RDS...")
        
        # Hash the password 'admin'
        hashed_password = get_password_hash("admin")
        
        async with engine.begin() as conn:
            # Check if user exists
            check = await conn.execute(text("SELECT username FROM users WHERE username = 'OceanAdmin'"))
            if check.fetchone():
                print("⚠️ OceanAdmin already exists")
                return False
            
            # Insert admin user
            await conn.execute(text("""
                INSERT INTO users (username, email, hashed_password, first_name, last_name, 
                                   role, is_active, is_verified, created_at, updated_at) 
                VALUES ('OceanAdmin', 'admin@vi.com', :pwd, 'Ocean', 'Admin', 
                        'admin', true, true, :now, :now)
            """), {'pwd': hashed_password, 'now': datetime.utcnow()})
            
            print("✅ Admin user created!")
            print("   Username: OceanAdmin")
            print("   Password: admin") 
            print("   Email: admin@vi.com")
            return True
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    asyncio.run(create_admin())