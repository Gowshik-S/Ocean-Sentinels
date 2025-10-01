#!/usr/bin/env python3
"""
Add Admin User to Database
Creates a proper admin account for accessing the analytics and admin features
"""

import requests
import json

def check_backend_running():
    """Check if the backend server is running"""
    try:
        response = requests.get("http://127.0.0.1:9000/health", timeout=5)
        return response.status_code == 200
    except:
        return False

def register_admin_user():
    """Register a proper admin user"""
    admin_data = {
        "username": "oceanadmin",
        "email": "admin@oceanguard.gov.in",
        "password": "admin",
        "first_name": "Ocean",
        "last_name": "Administrator",
        "phone": "1800-123-4567",
        "location": "New Delhi - Ministry of Earth Sciences"
    }
    
    try:
        response = requests.post(
            "http://127.0.0.1:9000/api/auth/register",
            json=admin_data,
            timeout=10
        )
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Admin user created successfully!")
            print(f"📋 User ID: {result.get('id')}")
            print(f"👤 Username: {admin_data['username']}")
            print(f"🔑 Password: {admin_data['password']}")
            print(f"📧 Email: {admin_data['email']}")
            
            # Test login immediately
            test_admin_login(admin_data['username'], admin_data['password'])
            
            return result
        else:
            print(f"❌ Admin user creation failed: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Error creating admin user: {e}")
        return None

def test_admin_login(username, password):
    """Test login for the admin user"""
    try:
        response = requests.post(
            "http://127.0.0.1:9000/api/auth/login",
            data={
                "username": username,
                "password": password
            },
            timeout=10
        )
        
        if response.status_code == 200:
            login_data = response.json()
            print(f"✅ Admin login test successful!")
            print(f"🎫 Token type: {login_data.get('token_type')}")
            print(f"👤 User: {login_data['user']['first_name']} {login_data['user']['last_name']}")
            print(f"🎭 Role: {login_data['user']['role']}")
            return login_data
        else:
            print(f"❌ Admin login test failed: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Error testing admin login: {e}")
        return None

def test_analytics_access(token):
    """Test access to analytics endpoints with admin token"""
    try:
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        print(f"\n🔬 Testing Analytics Access...")
        
        # Test dashboard endpoint
        response = requests.get(
            "http://127.0.0.1:9000/api/analytics/dashboard",
            headers=headers,
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Analytics dashboard accessible!")
            print(f"📊 Total incidents: {data.get('total_incidents')}")
            print(f"🔥 Active incidents: {data.get('active_incidents')}")
            print(f"✅ Resolved incidents: {data.get('resolved_incidents')}")
            return True
        else:
            print(f"❌ Analytics access failed: {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error testing analytics access: {e}")
        return False

if __name__ == "__main__":
    print("🌊 Ocean Hazard - Admin User Setup")
    print("=" * 50)
    
    if not check_backend_running():
        print("❌ Backend server is not running!")
        print("   Please start the backend with: python start_ocean_hazard.py")
    else:
        print("✅ Backend server is running")
        
        admin_result = register_admin_user()
        
        if admin_result:
            print("\n" + "=" * 50)
            print("🎉 ADMIN ACCOUNT READY!")
            print("=" * 50)
            print("🌐 Analytics Page: http://localhost:8080/pages/analytics.html")
            print("🔑 Admin Login:")
            print("   Username: oceanadmin")
            print("   Password: Ocean@Admin2025")
            print("\n💡 Use these credentials to access admin features!")
        else:
            print("\n❌ Failed to create admin account")