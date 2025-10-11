import asyncio
import asyncpg

async def fix_admin_user_role():
    connection_string = "postgresql://admindb:Gowshik$123$@ocean-guard-db.cvy6sm28q2bl.ap-south-1.rds.amazonaws.com:5432/disaster_management"
    
    try:
        conn = await asyncpg.connect(connection_string)
        print("🔌 Connected to database")
        
        # Check current OceanAdmin user
        current_user = await conn.fetchrow(
            "SELECT id, username, role FROM users WHERE username = 'OceanAdmin'"
        )
        
        if current_user:
            print(f"Current OceanAdmin user: Role = {current_user['role']}")
            
            # Update role to lowercase to match backend enum
            await conn.execute(
                "UPDATE users SET role = 'admin' WHERE username = 'OceanAdmin'"
            )
            
            # Verify update
            updated_user = await conn.fetchrow(
                "SELECT id, username, role FROM users WHERE username = 'OceanAdmin'"
            )
            
            print(f"✅ Updated OceanAdmin user: Role = {updated_user['role']}")
        else:
            print("❌ OceanAdmin user not found")
        
        await conn.close()
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    asyncio.run(fix_admin_user_role())