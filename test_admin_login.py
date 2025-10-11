#!/usr/bin/env python3
"""
Test Admin Login
Tests the existing admin user credentials
"""

import requests
import json

def test_existing_admin_login():
    """Test login with existing admin credentials"""
    test_credentials = [
        {"username": "OceanAdmin", "password": "admin"},  # Our newly created admin
        {"username": "oceanadmin", "password": "admin"},
        {"username": "oceanadmin", "password": "Ocean@Admin2025"},
        {"username": "demo_admin", "password": "admin123"},
        {"username": "admin", "password": "admin"}
    ]
    
    print("🔐 Testing admin credentials (including new OceanAdmin)...")
    
    for creds in test_credentials:
        print(f"\n🧪 Testing: {creds['username']} / {creds['password']}")
        
        try:
            response = requests.post(
                "http://127.0.0.1:9000/api/auth/login",
                data=creds,
                timeout=10
            )
            
            if response.status_code == 200:
                login_data = response.json()
                print(f"✅ LOGIN SUCCESS!")
                print(f"👤 User: {login_data['user']['first_name']} {login_data['user']['last_name']}")
                print(f"🎭 Role: {login_data['user']['role']}")
                print(f"🎫 Token: {login_data['access_token'][:50]}...")
                
                # Test analytics access
                test_analytics_access(login_data['access_token'])
                return creds
            else:
                print(f"❌ Login failed: {response.status_code}")
                
        except Exception as e:
            print(f"❌ Error: {e}")
    
    return None

def test_analytics_access(token):
    """Test analytics endpoint access"""
    try:
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        response = requests.get(
            "http://127.0.0.1:9000/api/analytics/dashboard",
            headers=headers,
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Analytics accessible!")
            print(f"📊 Total incidents: {data.get('total_incidents', 0)}")
            print(f"🔥 Active incidents: {data.get('active_incidents', 0)}")
            print(f"✅ Resolved incidents: {data.get('resolved_incidents', 0)}")
        else:
            print(f"❌ Analytics access failed: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Analytics test error: {e}")

if __name__ == "__main__":
    print("🌊 Ocean Guard - Admin Login Test")
    print("=" * 50)
    
    working_creds = test_existing_admin_login()
    
    if working_creds:
        print("\n" + "=" * 50)
        print("🎉 WORKING ADMIN CREDENTIALS FOUND!")
        print("=" * 50)
        print(f"👤 Username: {working_creds['username']}")
        print(f"🔑 Password: {working_creds['password']}")
        print("🌐 Analytics URL: http://localhost:3000/pages/analytics.html")
        print("\n💡 Use these credentials to login!")
    else:
        print("\n❌ No working admin credentials found")