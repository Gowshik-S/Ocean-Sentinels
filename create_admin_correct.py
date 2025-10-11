import asyncio
import asyncpg
from passlib.context import CryptContext
from datetime import datetime

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

async def create_admin_user():
    # Database connection parameters
    connection_string = "postgresql://admindb:Gowshik$123$@ocean-guard-db.cvy6sm28q2bl.ap-south-1.rds.amazonaws.com:5432/disaster_management"
    
    try:
        # Connect to database
        print("🔌 Connecting to AWS RDS...")
        conn = await asyncpg.connect(connection_string)
        print("✅ Connected successfully!")
        
        # Hash the password
        hashed_password = pwd_context.hash("admin")
        print("🔐 Password hashed successfully")
        
        # Insert admin user with correct enum value
        query = """
        INSERT INTO users (username, email, password_hash, role, created_at, is_active)
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING id, username, email, role
        """
        
        result = await conn.fetchrow(
            query,
            "OceanAdmin",
            "admin@vi.com",
            hashed_password,
            "ADMIN",  # Using uppercase ADMIN as per enum values
            datetime.utcnow(),
            True
        )
        
        print("✅ Admin user created successfully!")
        print(f"   ID: {result['id']}")
        print(f"   Username: {result['username']}")
        print(f"   Email: {result['email']}")
        print(f"   Role: {result['role']}")
        
        await conn.close()
        print("🔐 Database connection closed")
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    asyncio.run(create_admin_user())