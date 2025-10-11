import asyncio
import asyncpg
from passlib.context import CryptContext
from datetime import datetime, timezone

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
        
        # Insert admin user with all required fields
        query = """
        INSERT INTO users (username, email, hashed_password, first_name, last_name, role, is_active, is_verified, created_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        RETURNING id, username, email, role
        """
        
        result = await conn.fetchrow(
            query,
            "OceanAdmin",           # username
            "admin@vi.com",         # email
            hashed_password,        # hashed_password
            "Ocean",                # first_name
            "Administrator",        # last_name
            "ADMIN",                # role (correct enum value)
            True,                   # is_active
            True,                   # is_verified
            datetime.now(timezone.utc)  # created_at
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