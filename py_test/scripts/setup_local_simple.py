#!/usr/bin/env python3
"""
Simple Local Database Setup for Ocean Hazard
This script creates a local SQLite database for easy development
"""

import sqlite3
import os
import sys
from pathlib import Path

def create_sqlite_database():
    """Create SQLite database for local development"""
    print("🗄️ Creating local SQLite database...")
    
    # Create database directory
    db_dir = Path("backend/database")
    db_dir.mkdir(exist_ok=True)
    
    # Database file path
    db_path = db_dir / "ocean_hazard.db"
    
    try:
        # Create SQLite database
        conn = sqlite3.connect(str(db_path))
        cursor = conn.cursor()
        
        # Create basic tables
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE NOT NULL,
                email TEXT UNIQUE NOT NULL,
                first_name TEXT,
                last_name TEXT,
                role TEXT DEFAULT 'public',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_login TIMESTAMP
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS incidents (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                description TEXT,
                hazard_type TEXT NOT NULL,
                severity TEXT NOT NULL,
                latitude REAL NOT NULL,
                longitude REAL NOT NULL,
                status TEXT DEFAULT 'reported',
                reporter_id INTEGER,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (reporter_id) REFERENCES users (id)
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS analytics (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                metric_name TEXT NOT NULL,
                metric_value REAL NOT NULL,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # Insert sample data
        cursor.execute('''
            INSERT OR IGNORE INTO users (username, email, first_name, last_name, role)
            VALUES ('admin', 'admin@oceanhazard.com', 'Admin', 'User', 'admin')
        ''')
        
        cursor.execute('''
            INSERT OR IGNORE INTO users (username, email, first_name, last_name, role)
            VALUES ('user', 'user@oceanhazard.com', 'Test', 'User', 'public')
        ''')
        
        conn.commit()
        conn.close()
        
        print(f"✅ SQLite database created: {db_path}")
        return str(db_path)
        
    except Exception as e:
        print(f"❌ Error creating SQLite database: {e}")
        return None

def update_env_for_sqlite():
    """Update environment file for SQLite"""
    env_file = "backend/env.local"
    
    # SQLite database URL
    sqlite_url = "sqlite+aiosqlite:///backend/database/ocean_hazard.db"
    
    # Read current env file
    if os.path.exists(env_file):
        with open(env_file, 'r') as f:
            content = f.read()
    else:
        content = ""
    
    # Update DATABASE_URL to use SQLite
    lines = content.split('\n')
    updated = False
    
    for i, line in enumerate(lines):
        if line.startswith("DATABASE_URL="):
            lines[i] = f"DATABASE_URL={sqlite_url}"
            updated = True
            break
    
    if not updated:
        lines.insert(1, f"DATABASE_URL={sqlite_url}")
    
    # Write updated content
    with open(env_file, 'w') as f:
        f.write('\n'.join(lines))
    
    print(f"✅ Updated {env_file} for SQLite")
    print(f"📝 Database URL: {sqlite_url}")

def test_sqlite_connection():
    """Test SQLite database connection"""
    print("\n🧪 Testing SQLite database connection...")
    
    db_path = "backend/database/ocean_hazard.db"
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Test query
        cursor.execute("SELECT COUNT(*) FROM users")
        user_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM incidents")
        incident_count = cursor.fetchone()[0]
        
        conn.close()
        
        print(f"✅ SQLite connection successful!")
        print(f"📊 Users: {user_count}, Incidents: {incident_count}")
        return True
        
    except Exception as e:
        print(f"❌ SQLite connection failed: {e}")
        return False

def main():
    """Main setup function"""
    print("🌊 Ocean Hazard - Local SQLite Database Setup")
    print("=" * 50)
    
    # Create SQLite database
    db_path = create_sqlite_database()
    
    if db_path:
        # Update environment file
        update_env_for_sqlite()
        
        # Test connection
        if test_sqlite_connection():
            print("\n🎉 Local SQLite database setup complete!")
            print("\n📋 Next steps:")
            print("1. Install aiosqlite: pip install aiosqlite")
            print("2. Run: python test_db_connection.py")
            print("3. Start your application with: python start_server.py")
        else:
            print("\n❌ Database setup incomplete.")
    else:
        print("\n❌ Failed to create SQLite database")

if __name__ == "__main__":
    main()


