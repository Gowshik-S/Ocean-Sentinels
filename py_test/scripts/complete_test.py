#!/usr/bin/env python3
"""
Complete SQLite & Reports Test
Tests both user registration and reports functionality
"""

import requests
import sqlite3
import json
from datetime import datetime

def test_user_registration():
    """Test user registration with the fixed server"""
    print("🧪 Testing User Registration")
    print("=" * 35)
    
    # Get current user count
    conn = sqlite3.connect('backend/database/ocean_hazard.db')
    cursor = conn.cursor()
    cursor.execute('SELECT COUNT(*) FROM users')
    users_before = cursor.fetchone()[0]
    print(f"📊 Users before registration: {users_before}")
    conn.close()
    
    # Test user data
    test_user = {
        "username": f"testuser_{datetime.now().strftime('%H%M%S')}",
        "email": f"testuser_{datetime.now().strftime('%H%M%S')}@example.com",
        "password": "testpass123",
        "first_name": "Test",
        "last_name": "User"
    }
    
    print(f"🔄 Registering user: {test_user['username']}")
    
    try:
        response = requests.post(
            "http://127.0.0.1:8004/api/auth/register",
            json=test_user,
            timeout=5
        )
        
        print(f"📤 Registration response: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Registration successful!")
            print(f"   User ID: {result['user']['id']}")
            print(f"   Username: {result['user']['username']}")
            
            # Check database
            conn = sqlite3.connect('backend/database/ocean_hazard.db')
            cursor = conn.cursor()
            cursor.execute('SELECT COUNT(*) FROM users')
            users_after = cursor.fetchone()[0]
            
            cursor.execute('SELECT username, email, created_at FROM users ORDER BY created_at DESC LIMIT 1')
            latest_user = cursor.fetchone()
            conn.close()
            
            print(f"📊 Users after registration: {users_after}")
            print(f"📋 Latest user: {latest_user[0]} ({latest_user[1]}) - {latest_user[2]}")
            
            if users_after > users_before:
                print(f"🎉 SUCCESS: User was saved to database!")
                return True
            else:
                print(f"❌ FAILED: User not saved to database")
                return False
        else:
            print(f"❌ Registration failed: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Registration test error: {e}")
        return False

def test_reports_functionality():
    """Test reports functionality for citizens"""
    print(f"\n📋 Testing Reports Functionality")
    print("=" * 35)
    
    try:
        # Test without authentication (should get default user reports)
        print(f"🔄 Getting my reports (citizen)...")
        response = requests.get("http://127.0.0.1:8004/api/my-reports/", timeout=5)
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ My reports response successful!")
            print(f"   Total reports: {result['total']}")
            print(f"   Source: {result.get('source', 'unknown')}")
            
            if result['total'] > 0:
                print(f"   Sample report: {result['incidents'][0]['hazard_type']} at {result['incidents'][0]['location']}")
            
            return True
        else:
            print(f"❌ My reports failed: {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Reports test error: {e}")
        return False

def test_database_status():
    """Check current database status"""
    print(f"\n📊 Database Status Check")
    print("=" * 25)
    
    try:
        conn = sqlite3.connect('backend/database/ocean_hazard.db')
        cursor = conn.cursor()
        
        # Users count
        cursor.execute('SELECT COUNT(*) FROM users')
        user_count = cursor.fetchone()[0]
        
        # Incidents count
        cursor.execute('SELECT COUNT(*) FROM incidents')
        incident_count = cursor.fetchone()[0]
        
        # Recent users
        cursor.execute('SELECT username, email, created_at FROM users ORDER BY created_at DESC LIMIT 3')
        recent_users = cursor.fetchall()
        
        print(f"👥 Total users: {user_count}")
        print(f"📋 Total incidents: {incident_count}")
        print(f"📅 Recent users:")
        for user in recent_users:
            print(f"   - {user[0]} ({user[1]}) - {user[2]}")
        
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Database status error: {e}")
        return False

if __name__ == "__main__":
    print("🔍 Complete SQLite & Reports Test")
    print("=" * 50)
    
    # Test 1: Database status
    db_status = test_database_status()
    
    # Test 2: User registration
    registration_success = test_user_registration()
    
    # Test 3: Reports functionality
    reports_success = test_reports_functionality()
    
    # Final summary
    print(f"\n🎯 Test Results Summary")
    print("=" * 25)
    print(f"Database Status: {'✅ Working' if db_status else '❌ Failed'}")
    print(f"User Registration: {'✅ Working' if registration_success else '❌ Failed'}")
    print(f"Reports Access: {'✅ Working' if reports_success else '❌ Failed'}")
    
    if registration_success and reports_success:
        print(f"\n🎉 ALL TESTS PASSED!")
        print(f"✅ SQLite registration is working")
        print(f"✅ Reports page is working for citizens")
        print(f"✅ Server: http://127.0.0.1:8004")
    else:
        print(f"\n⚠️  Some tests failed - check the issues above")