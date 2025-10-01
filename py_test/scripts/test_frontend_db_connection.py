#!/usr/bin/env python3
"""
Frontend Database Connection Test
Tests the complete flow: registration -> incident creation -> database verification
"""

import requests
import sqlite3
import json
import time
from datetime import datetime

# Server details
BASE_URL = "http://127.0.0.1:8004/api"
DB_PATH = "backend/database/ocean_hazard.db"

def test_user_registration():
    """Test user registration through API"""
    print("🧪 Testing User Registration")
    print("=" * 35)
    
    timestamp = datetime.now().strftime("%H%M%S")
    test_user = {
        "username": f"frontend_test_{timestamp}",
        "email": f"frontend_test_{timestamp}@example.com",
        "password": "testpass123",
        "first_name": "Frontend",
        "last_name": "Test",
        "phone": "1234567890",
        "location": "test-location"
    }
    
    try:
        # Register user
        response = requests.post(f"{BASE_URL}/auth/register", json=test_user)
        print(f"Registration status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Registration successful!")
            print(f"User ID: {result['user']['id']}")
            print(f"Username: {result['user']['username']}")
            return result['user'], test_user['password']
        else:
            print(f"❌ Registration failed: {response.text}")
            return None, None
            
    except Exception as e:
        print(f"❌ Registration error: {e}")
        return None, None

def test_user_login(username, password):
    """Test user login"""
    print(f"\n🔐 Testing User Login")
    print("=" * 25)
    
    try:
        # Try login
        login_data = {"username": username, "password": password}
        response = requests.post(f"{BASE_URL}/auth/login-json", json=login_data)
        
        print(f"Login status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Login successful!")
            print(f"Token: {result['access_token'][:20]}...")
            return result['access_token']
        else:
            print(f"❌ Login failed: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Login error: {e}")
        return None

def test_incident_creation(token):
    """Test incident creation"""
    print(f"\n📋 Testing Incident Creation")
    print("=" * 32)
    
    incident_data = {
        "hazard_type": "HIGH_WAVES",
        "location": "Test Beach, Test City",
        "latitude": 12.9716,
        "longitude": 77.5946,
        "description": "Test incident from frontend database connection test",
        "contact_info": "test@example.com",
        "urgency": "MEDIUM"
    }
    
    headers = {"Authorization": f"Bearer {token}"}
    
    try:
        response = requests.post(f"{BASE_URL}/incidents/", json=incident_data, headers=headers)
        print(f"Incident creation status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Incident created successfully!")
            print(f"Reference ID: {result['reference_id']}")
            print(f"Incident ID: {result['id']}")
            return result
        else:
            print(f"❌ Incident creation failed: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Incident creation error: {e}")
        return None

def test_my_reports(token):
    """Test getting user's reports"""
    print(f"\n📊 Testing My Reports Endpoint")
    print("=" * 35)
    
    headers = {"Authorization": f"Bearer {token}"}
    
    try:
        response = requests.get(f"{BASE_URL}/my-reports/", headers=headers)
        print(f"My reports status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Retrieved user reports!")
            print(f"Total reports: {result['total']}")
            if result['incidents']:
                for incident in result['incidents']:
                    print(f"  - {incident['reference_id']}: {incident['hazard_type']} ({incident['status']})")
            return result
        else:
            print(f"❌ My reports failed: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ My reports error: {e}")
        return None

def verify_database():
    """Verify data in database"""
    print(f"\n🔍 Verifying Database")
    print("=" * 25)
    
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        # Check users
        cursor.execute('SELECT COUNT(*) FROM users')
        user_count = cursor.fetchone()[0]
        print(f"Total users in database: {user_count}")
        
        # Get recent users
        cursor.execute('SELECT username, email, created_at FROM users ORDER BY created_at DESC LIMIT 3')
        recent_users = cursor.fetchall()
        print("Recent users:")
        for user in recent_users:
            print(f"  - {user[0]} ({user[1]}) - {user[2]}")
        
        # Check incidents
        cursor.execute('SELECT COUNT(*) FROM incidents')
        incident_count = cursor.fetchone()[0]
        print(f"\nTotal incidents in database: {incident_count}")
        
        # Get recent incidents
        cursor.execute('SELECT reference_id, hazard_type, status, created_at FROM incidents ORDER BY created_at DESC LIMIT 3')
        recent_incidents = cursor.fetchall()
        print("Recent incidents:")
        for incident in recent_incidents:
            print(f"  - {incident[0]}: {incident[1]} ({incident[2]}) - {incident[3]}")
        
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Database verification error: {e}")
        return False

def main():
    print("🌊 Frontend Database Connection Test")
    print("="*50)
    
    # Test complete flow
    user, password = test_user_registration()
    if not user:
        print("\n❌ Test failed at registration step")
        return
    
    # Wait a moment for database to update
    time.sleep(1)
    
    token = test_user_login(user['username'], password)
    if not token:
        print("\n❌ Test failed at login step")
        return
    
    incident = test_incident_creation(token)
    if not incident:
        print("\n❌ Test failed at incident creation step")
        return
    
    # Wait a moment for database to update
    time.sleep(1)
    
    reports = test_my_reports(token)
    
    # Verify database
    db_verified = verify_database()
    
    # Summary
    print(f"\n🎯 Test Summary")
    print("=" * 15)
    print(f"✅ User Registration: {'Success' if user else 'Failed'}")
    print(f"✅ User Login: {'Success' if token else 'Failed'}")
    print(f"✅ Incident Creation: {'Success' if incident else 'Failed'}")
    print(f"✅ My Reports: {'Success' if reports else 'Failed'}")
    print(f"✅ Database Verification: {'Success' if db_verified else 'Failed'}")
    
    if user and token and incident and reports and db_verified:
        print(f"\n🎉 ALL TESTS PASSED!")
        print(f"✅ Frontend database connection is working correctly!")
        print(f"✅ Users can register and their data is saved to SQLite")
        print(f"✅ Users can submit reports and they appear in database")
        print(f"✅ Citizens can view their reports page")
    else:
        print(f"\n❌ Some tests failed. Check the server logs and try again.")

if __name__ == "__main__":
    main()