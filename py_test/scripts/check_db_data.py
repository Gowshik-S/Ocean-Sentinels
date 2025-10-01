#!/usr/bin/env python3
"""
Database Data Checker for Ocean Hazard
Checks if data is visible and accessible in the SQLite database
"""

import sqlite3
import os
from datetime import datetime

def check_database():
    db_path = "backend/database/ocean_hazard.db"
    
    print("🔍 Ocean Hazard Database Data Check")
    print("=" * 50)
    print(f"Database Path: {db_path}")
    print(f"Database Exists: {os.path.exists(db_path)}")
    
    if os.path.exists(db_path):
        file_size = os.path.getsize(db_path)
        print(f"Database Size: {file_size} bytes ({file_size/1024:.2f} KB)")
        modified_time = datetime.fromtimestamp(os.path.getmtime(db_path))
        print(f"Last Modified: {modified_time}")
    
    print("\n📊 Database Contents:")
    print("-" * 30)
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Check tables
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = cursor.fetchall()
        print(f"Tables found: {len(tables)}")
        
        for table in tables:
            table_name = table[0]
            print(f"\n📋 Table: {table_name}")
            
            # Get table schema
            cursor.execute(f"PRAGMA table_info({table_name});")
            columns = cursor.fetchall()
            print(f"  Columns: {[col[1] for col in columns]}")
            
            # Count rows
            cursor.execute(f"SELECT COUNT(*) FROM {table_name};")
            row_count = cursor.fetchone()[0]
            print(f"  Row count: {row_count}")
            
            # Show sample data if exists
            if row_count > 0:
                cursor.execute(f"SELECT * FROM {table_name} LIMIT 3;")
                sample_data = cursor.fetchall()
                print(f"  Sample data (first 3 rows):")
                for i, row in enumerate(sample_data, 1):
                    print(f"    Row {i}: {row}")
            else:
                print("  ⚠️  No data found in this table!")
        
        conn.close()
        
    except sqlite3.Error as e:
        print(f"❌ Database error: {e}")
    except Exception as e:
        print(f"❌ Unexpected error: {e}")

def check_database_locks():
    """Check if database is locked or has access issues"""
    db_path = "backend/database/ocean_hazard.db"
    
    print("\n🔒 Database Lock Check:")
    print("-" * 25)
    
    try:
        # Try to open in exclusive mode briefly
        conn = sqlite3.connect(db_path, timeout=1.0)
        cursor = conn.cursor()
        cursor.execute("BEGIN IMMEDIATE;")
        cursor.execute("ROLLBACK;")
        conn.close()
        print("✅ Database is accessible (no locks detected)")
        
    except sqlite3.OperationalError as e:
        if "locked" in str(e).lower():
            print(f"❌ Database is locked: {e}")
            print("   This might be why you can't see data in SQLite browser!")
        else:
            print(f"❌ Database access error: {e}")
    except Exception as e:
        print(f"❌ Unexpected error during lock check: {e}")

def check_wal_files():
    """Check for WAL (Write-Ahead Logging) files that might affect visibility"""
    db_path = "backend/database/ocean_hazard.db"
    base_path = os.path.dirname(db_path)
    
    print("\n📁 WAL Files Check:")
    print("-" * 20)
    
    wal_file = db_path + "-wal"
    shm_file = db_path + "-shm"
    
    if os.path.exists(wal_file):
        wal_size = os.path.getsize(wal_file)
        print(f"⚠️  WAL file exists: {wal_file} ({wal_size} bytes)")
        if wal_size > 0:
            print("   This might contain uncommitted changes!")
    else:
        print("✅ No WAL file found")
    
    if os.path.exists(shm_file):
        shm_size = os.path.getsize(shm_file)
        print(f"⚠️  SHM file exists: {shm_file} ({shm_size} bytes)")
    else:
        print("✅ No SHM file found")

if __name__ == "__main__":
    check_database()
    check_database_locks()
    check_wal_files()
    
    print("\n💡 Recommendations:")
    print("-" * 18)
    print("1. If WAL files exist, try closing all connections to the database")
    print("2. If database is locked, stop the server and try again")
    print("3. Make sure SQLite browser is using the correct database path")
    print("4. Try refreshing/reopening your SQLite browser")
    print("5. Check if the server is still running and accessing the database")