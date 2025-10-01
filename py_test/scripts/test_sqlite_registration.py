#!/usr/bin/env python3
"""
SQLite Database Test - Direct Registration
Tests user registration directly with the database
"""

import sqlite3
import hashlib
import requests
from datetime import datetime

# Database functions (same as in server)
DB_PATH = "backend/database/ocean_hazard.db"

def hash_password(password: str) -> str:
    """Simple password hashing"""
    return hashlib.sha256(password.encode()).hexdigest()

def add_user_to_db():
    """Test adding a user directly to the database"""
    print("🧪 Testing Direct Database User Registration")
    print("=" * 50)
    
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        # Test user data
        username = f"testuser_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        email = f"{username}@example.com"
        password = "testpass123"
        hashed_pw = hash_password(password)
        
        print(f"Creating user: {username}")
        print(f"Email: {email}")
        
        # Insert user
        cursor.execute('''
            INSERT INTO users (username, email, hashed_password, first_name, last_name, phone, location, role, is_active)
            VALUES (?, ?, ?, ?, ?, ?, ?, 'PUBLIC', 1)
        ''', (username, email, hashed_pw, "Test", "User", "1234567890", "test-location"))
        
        user_id = cursor.lastrowid
        conn.commit()
        
        print(f"✅ User created successfully with ID: {user_id}")
        
        # Verify user was created
        cursor.execute('SELECT id, username, email, first_name, last_name, created_at FROM users WHERE id = ?', (user_id,))
        user_data = cursor.fetchone()
        
        if user_data:
            print(f"✅ User verified in database:")
            print(f"   ID: {user_data[0]}")
            print(f"   Username: {user_data[1]}")
            print(f"   Email: {user_data[2]}")
            print(f"   Name: {user_data[3]} {user_data[4]}")
            print(f"   Created: {user_data[5]}")
        
        # Count total users
        cursor.execute('SELECT COUNT(*) FROM users')
        total_users = cursor.fetchone()[0]
        print(f"\n📊 Total users in database: {total_users}")
        
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Database test failed: {e}")
        return False

def test_server_registration():
    """Test server registration if it's running"""
    print("\n🌐 Testing Server Registration")
    print("=" * 35)
    
    test_user = {
        "username": f"servertest_{datetime.now().strftime('%H%M%S')}",
        "email": f"servertest_{datetime.now().strftime('%H%M%S')}@example.com",
        "password": "testpass123",
        "first_name": "Server",
        "last_name": "Test"
    }
    
    # Try different ports
    ports = [8004, 8003, 8002]
    
    for port in ports:
        try:
            print(f"Trying port {port}...")
            response = requests.post(
                f"http://127.0.0.1:{port}/api/auth/register",
                json=test_user,
                timeout=3
            )
            
            print(f"✅ Server responded on port {port}")
            print(f"Status: {response.status_code}")
            print(f"Response: {response.text[:100]}...")
            
            if response.status_code == 200:
                print("✅ Registration successful via server!")
                return True
            else:
                print(f"❌ Registration failed: {response.text}")
                
        except requests.exceptions.ConnectionError:
            print(f"❌ No server running on port {port}")
        except Exception as e:
            print(f"❌ Error testing port {port}: {e}")
    
    return False

def check_final_user_count():
    """Check final user count"""
    print("\n📊 Final Database Status")
    print("=" * 25)
    
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('SELECT COUNT(*) FROM users')
        total_users = cursor.fetchone()[0]
        
        cursor.execute('SELECT username, email, created_at FROM users ORDER BY created_at DESC LIMIT 3')
        recent_users = cursor.fetchall()
        
        print(f"Total users: {total_users}")
        print("Recent users:")
        for user in recent_users:
            print(f"  - {user[0]} ({user[1]}) - {user[2]}")
        
        conn.close()
        
    except Exception as e:
        print(f"Error checking database: {e}")

if __name__ == "__main__":
    print("🔍 SQLite Database Registration Test")
    print("="*60)
    
    # Test 1: Direct database insertion
    db_success = add_user_to_db()
    
    # Test 2: Server registration (if server is running)
    server_success = test_server_registration()
    
    # Test 3: Final status
    check_final_user_count()
    
    # Summary
    print("\n🎯 Test Summary")
    print("="*15)
    print(f"Direct DB Registration: {'✅ Success' if db_success else '❌ Failed'}")
    print(f"Server Registration: {'✅ Success' if server_success else '❌ Failed/No Server'}")
    
    if db_success:
        print("\n✅ SQLite database is working correctly!")
        print("You can now register users and they will be saved to the database.")
    else:
        print("\n❌ There are issues with the SQLite database setup.")