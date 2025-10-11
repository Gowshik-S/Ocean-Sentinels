import asyncio
import asyncpg

async def check_table_structure():
    connection_string = "postgresql://admindb:Gowshik$123$@ocean-guard-db.cvy6sm28q2bl.ap-south-1.rds.amazonaws.com:5432/disaster_management"
    
    try:
        conn = await asyncpg.connect(connection_string)
        print("🔌 Connected to database")
        
        # Get table structure
        query = """
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_name = 'users'
        ORDER BY ordinal_position
        """
        
        columns = await conn.fetch(query)
        print("\n📋 Users table structure:")
        for col in columns:
            print(f"   {col['column_name']}: {col['data_type']} {'(nullable)' if col['is_nullable'] == 'YES' else '(not null)'}")
        
        await conn.close()
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    asyncio.run(check_table_structure())