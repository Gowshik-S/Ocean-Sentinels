import asyncio
import asyncpg

async def check_current_users():
    connection_string = "postgresql://admindb:Gowshik$123$@ocean-guard-db.cvy6sm28q2bl.ap-south-1.rds.amazonaws.com:5432/disaster_management"
    
    try:
        conn = await asyncpg.connect(connection_string)
        print("🔌 Connected to database")
        
        # Get all users with all details
        users = await conn.fetch(
            "SELECT id, username, email, first_name, last_name, role, is_active FROM users ORDER BY id"
        )
        
        print(f"\n📊 TOTAL USERS IN DATABASE: {len(users)}")
        print("=" * 80)
        
        for user in users:
            print(f"ID: {user['id']}")
            print(f"Username: {user['username']}")
            print(f"Email: {user['email']}")
            print(f"Name: {user['first_name']} {user['last_name']}")
            print(f"Role: {user['role']}")
            print(f"Active: {user['is_active']}")
            print("-" * 40)
        
        # Get count by role
        role_counts = await conn.fetch(
            "SELECT role, COUNT(*) as count FROM users GROUP BY role"
        )
        
        print("\n📈 USERS BY ROLE:")
        for role in role_counts:
            print(f"   {role['role']}: {role['count']} users")
        
        await conn.close()
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    asyncio.run(check_current_users())