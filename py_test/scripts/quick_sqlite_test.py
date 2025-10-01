#!/usr/bin/env python3
"""
Quick SQLite Test - Verify Database Registration
"""

import sqlite3
import requests
import time

def test_with_running_server():
    print("🧪 Testing SQLite Registration with Running Server")
    print("=" * 55)
    
    # Step 1: Check current user count
    try:
        conn = sqlite3.connect('backend/database/ocean_hazard.db')
        cursor = conn.cursor()
        cursor.execute('SELECT COUNT(*) FROM users')
        users_before = cursor.fetchone()[0]
        print(f"📊 Users before registration: {users_before}")
        conn.close()
    except Exception as e:
        print(f"❌ Database check failed: {e}")
        return
    
    # Step 2: Try registration on different ports
    test_user = {
        "username": f"quicktest_{int(time.time())}",
        "email": f"quicktest_{int(time.time())}@example.com",
        "password": "testpass123",
        "first_name": "Quick",
        "last_name": "Test"
    }
    
    registration_success = False
    
    for port in [8004, 8003, 8002]:
        try:
            print(f"🌐 Trying registration on port {port}...")
            response = requests.post(
                f"http://127.0.0.1:{port}/api/auth/register",
                json=test_user,
                timeout=2
            )
            
            if response.status_code == 200:
                print(f"✅ Registration successful on port {port}!")
                print(f"Response: {response.json()}")
                registration_success = True
                break
            else:
                print(f"❌ Registration failed on port {port}: {response.status_code}")
                
        except requests.exceptions.ConnectionError:
            print(f"❌ No server on port {port}")
        except Exception as e:
            print(f"❌ Error on port {port}: {e}")
    
    # Step 3: Check if user was actually saved to database
    time.sleep(1)  # Give database time to update
    
    try:
        conn = sqlite3.connect('backend/database/ocean_hazard.db')
        cursor = conn.cursor()
        
        cursor.execute('SELECT COUNT(*) FROM users')
        users_after = cursor.fetchone()[0]
        
        cursor.execute('SELECT username, email, created_at FROM users ORDER BY created_at DESC LIMIT 3')
        recent_users = cursor.fetchall()
        
        print(f"\n📊 Database Status After Registration:")
        print(f"Users before: {users_before}")
        print(f"Users after: {users_after}")
        print(f"Users added: {users_after - users_before}")
        
        print(f"\n📋 Most recent users:")
        for user in recent_users:
            print(f"  - {user[0]} ({user[1]}) - {user[2]}")
        
        conn.close()
        
        # Verify success
        if registration_success and users_after > users_before:
            print(f"\n🎉 SUCCESS! Registration worked and user was saved to database!")
            return True
        elif registration_success:
            print(f"\n⚠️  Registration succeeded but user not found in database (using in-memory storage)")
            return False
        else:
            print(f"\n❌ Registration failed - no server responding")
            return False
            
    except Exception as e:
        print(f"❌ Final database check failed: {e}")
        return False

if __name__ == "__main__":
    success = test_with_running_server()
    
    print(f"\n🎯 Final Result: {'✅ SQLite integration working!' if success else '❌ Still using in-memory storage'}")