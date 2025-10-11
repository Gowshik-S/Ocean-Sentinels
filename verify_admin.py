import asyncio
import asyncpg

async def verify_admin_user():
    connection_string = "postgresql://admindb:Gowshik$123$@ocean-guard-db.cvy6sm28q2bl.ap-south-1.rds.amazonaws.com:5432/disaster_management"
    
    try:
        conn = await asyncpg.connect(connection_string)
        print("🔌 Connected to database")
        
        # Check if admin user exists
        query = """
        SELECT id, username, email, first_name, last_name, role, is_active, is_verified, created_at
        FROM users
        WHERE username = 'OceanAdmin'
        """
        
        user = await conn.fetchrow(query)
        
        if user:
            print("\n✅ Admin user found:")
            print(f"   ID: {user['id']}")
            print(f"   Username: {user['username']}")
            print(f"   Email: {user['email']}")
            print(f"   Name: {user['first_name']} {user['last_name']}")
            print(f"   Role: {user['role']}")
            print(f"   Active: {user['is_active']}")
            print(f"   Verified: {user['is_verified']}")
            print(f"   Created: {user['created_at']}")
        else:
            print("❌ Admin user not found")
            
        # Also show all users count
        count_query = "SELECT COUNT(*) as total FROM users"
        count_result = await conn.fetchrow(count_query)
        print(f"\n📊 Total users in database: {count_result['total']}")
        
        await conn.close()
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    asyncio.run(verify_admin_user())