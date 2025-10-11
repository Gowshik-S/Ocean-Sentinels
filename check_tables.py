"""
Check what tables exist in the AWS RDS database
"""
import asyncio
import sys
import os

# Add backend to path so we can import the app modules
sys.path.append(os.path.join(os.path.dirname(__file__), 'backend'))

async def check_tables():
    try:
        from app.database.database import engine
        from sqlalchemy import text
        
        print("🔍 Checking tables in AWS RDS database...")
        
        async with engine.begin() as conn:
            # Get list of tables
            result = await conn.execute(text("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public'
                ORDER BY table_name;
            """))
            
            tables = result.fetchall()
            
            if tables:
                print(f"✅ Found {len(tables)} tables:")
                for table in tables:
                    print(f"   📋 {table[0]}")
                    
                    # Get column info for each table
                    col_result = await conn.execute(text(f"""
                        SELECT column_name, data_type, is_nullable
                        FROM information_schema.columns 
                        WHERE table_name = '{table[0]}' AND table_schema = 'public'
                        ORDER BY ordinal_position;
                    """))
                    
                    columns = col_result.fetchall()
                    for col in columns:
                        nullable = "NULL" if col[2] == "YES" else "NOT NULL"
                        print(f"      - {col[0]} ({col[1]}) {nullable}")
                    print()
            else:
                print("❌ No tables found in the database")
                print("💡 You may need to start the backend to create tables automatically")
                
        return len(tables) if tables else 0
            
    except Exception as e:
        print(f"❌ Failed to check tables: {e}")
        return -1

if __name__ == "__main__":
    result = asyncio.run(check_tables())
    print(f"🎯 Total tables: {result}")