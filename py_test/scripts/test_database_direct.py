#!/usr/bin/env python3
"""
Direct SQLite Database Test & Fix
Tests the actual database operations that the server should be doing
"""

import sqlite3
import hashlib
import json
from datetime import datetime

DB_PATH = "backend/database/ocean_hazard.db"

def hash_password(password: str) -> str:
    """Simple password hashing"""
    return hashlib.sha256(password.encode()).hexdigest()

def test_database_operations():
    """Test all database operations that the server should perform"""
    print("🔧 Testing SQLite Database Operations")
    print("=" * 50)
    
    try:
        # Test 1: Connection
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        print("✅ Database connection successful")
        
        # Test 2: Check current users
        cursor.execute('SELECT COUNT(*) FROM users')
        user_count_before = cursor.fetchone()[0]
        print(f"📊 Current users in database: {user_count_before}")
        
        # Test 3: Try to create a new user
        test_username = f"testuser_{datetime.now().strftime('%H%M%S')}"
        test_email = f"{test_username}@example.com"
        test_password = "testpass123"
        hashed_pw = hash_password(test_password)
        
        print(f"🧪 Creating test user: {test_username}")
        
        cursor.execute('''
            INSERT INTO users (username, email, hashed_password, first_name, last_name, phone, location, role, is_active, is_verified)
            VALUES (?, ?, ?, ?, ?, ?, ?, 'PUBLIC', 1, 0)
        ''', (test_username, test_email, hashed_pw, "Test", "User", "1234567890", "test-location"))
        
        user_id = cursor.lastrowid
        conn.commit()
        print(f"✅ User created successfully with ID: {user_id}")
        
        # Test 4: Verify user was created
        cursor.execute('SELECT COUNT(*) FROM users')
        user_count_after = cursor.fetchone()[0]
        print(f"📊 Users after creation: {user_count_after}")
        
        # Test 5: Retrieve the created user
        cursor.execute('SELECT id, username, email, first_name, last_name, created_at FROM users WHERE id = ?', (user_id,))
        user_data = cursor.fetchone()
        
        if user_data:
            print(f"✅ User retrieval successful:")
            print(f"   ID: {user_data[0]}")
            print(f"   Username: {user_data[1]}")
            print(f"   Email: {user_data[2]}")
            print(f"   Name: {user_data[3]} {user_data[4]}")
            print(f"   Created: {user_data[5]}")
        
        # Test 6: List recent users
        cursor.execute('SELECT username, email, created_at FROM users ORDER BY created_at DESC LIMIT 3')
        recent_users = cursor.fetchall()
        print(f"\n📋 Recent users:")
        for user in recent_users:
            print(f"  - {user[0]} ({user[1]}) - {user[2]}")
        
        conn.close()
        
        if user_count_after > user_count_before:
            print(f"\n🎉 SUCCESS: Database operations are working correctly!")
            return True
        else:
            print(f"\n❌ FAILURE: User was not added to database")
            return False
            
    except Exception as e:
        print(f"❌ Database operation failed: {e}")
        return False

def create_fixed_registration_function():
    """Create a working registration function that definitely saves to database"""
    print(f"\n🔧 Creating Fixed Registration Function")
    print("=" * 40)
    
    def register_user_to_db(username, email, password, first_name, last_name, phone=None, location=None):
        """Fixed registration function that guarantees database save"""
        try:
            # Connect to database
            conn = sqlite3.connect(DB_PATH)
            cursor = conn.cursor()
            
            # Hash password
            hashed_pw = hash_password(password)
            
            # Insert user
            cursor.execute('''
                INSERT INTO users (username, email, hashed_password, first_name, last_name, phone, location, role, is_active, is_verified)
                VALUES (?, ?, ?, ?, ?, ?, ?, 'PUBLIC', 1, 0)
            ''', (username, email, hashed_pw, first_name, last_name, phone, location))
            
            user_id = cursor.lastrowid
            
            # CRITICAL: Commit the transaction
            conn.commit()
            
            # Close connection
            conn.close()
            
            print(f"✅ User '{username}' successfully saved to database with ID: {user_id}")
            return user_id
            
        except sqlite3.IntegrityError as e:
            if "username" in str(e):
                print(f"❌ Username '{username}' already exists")
                return None
            elif "email" in str(e):
                print(f"❌ Email '{email}' already exists")
                return None
            else:
                print(f"❌ Database integrity error: {e}")
                return None
        except Exception as e:
            print(f"❌ Registration failed: {e}")
            return None
    
    # Test the fixed function
    test_user_id = register_user_to_db(
        username=f"fixedtest_{datetime.now().strftime('%H%M%S')}",
        email=f"fixedtest_{datetime.now().strftime('%H%M%S')}@example.com",
        password="testpass123",
        first_name="Fixed",
        last_name="Test",
        phone="1234567890",
        location="test-location"
    )
    
    if test_user_id:
        print(f"🎉 Fixed registration function works! User ID: {test_user_id}")
        return True
    else:
        print(f"❌ Fixed registration function failed")
        return False

if __name__ == "__main__":
    print("🔍 SQLite Database Connection & Registration Test")
    print("=" * 60)
    
    # Test 1: Basic database operations
    db_working = test_database_operations()
    
    # Test 2: Create and test fixed registration
    registration_working = create_fixed_registration_function()
    
    # Summary
    print(f"\n🎯 Test Results:")
    print(f"Database Operations: {'✅ Working' if db_working else '❌ Failed'}")
    print(f"Registration Function: {'✅ Working' if registration_working else '❌ Failed'}")
    
    if db_working and registration_working:
        print(f"\n🎉 SQLite database is working correctly!")
        print(f"The issue is likely in the server code, not the database itself.")
    else:
        print(f"\n❌ There are fundamental database issues that need fixing.")