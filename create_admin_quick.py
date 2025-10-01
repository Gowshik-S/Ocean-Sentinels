#!/usr/bin/env python3
"""
Quick Admin User Creator for Ocean Guard
Creates admin user directly via API call
"""

import requests
import json
import sys

def create_admin_user():
    # Admin user credentials
    admin_data = {
        "username": "oceanadmin",
        "email": "admin@oceanguard.gov.in",
        "password": "Ocean@Admin2025",
        "full_name": "Ocean Guard Administrator",
        "role": "ADMIN"
    }
    
    print("🌊 Ocean Guard Admin User Creator")
    print("=" * 50)
    
    # Check if server is running
    try:
        response = requests.get("http://localhost:8000/health", timeout=5)
        print("✅ Backend server is accessible")
    except:
        print("❌ Backend server is not running!")
        print("   Please start the server first:")
        print("   cd backend && python -m uvicorn app.main:app --reload")
        return False
    
    # Create admin user
    try:
        print("📝 Creating admin user account...")
        response = requests.post(
            "http://localhost:8000/api/auth/register",
            json=admin_data,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            print("✅ Admin user created successfully!")
            print(f"   Username: {admin_data['username']}")
            print(f"   Password: {admin_data['password']}")
            print("   Role: ADMIN")
            return True
        else:
            print(f"❌ Failed to create admin user: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error creating admin user: {e}")
        return False

def test_admin_login():
    """Test admin login"""
    print("\n🔐 Testing admin login...")
    
    login_data = {
        "username": "oceanadmin",
        "password": "Ocean@Admin2025"
    }
    
    try:
        response = requests.post(
            "http://localhost:8000/api/auth/login",
            data=login_data,  # Note: FastAPI expects form data for login
            headers={"Content-Type": "application/x-www-form-urlencoded"}
        )
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Admin login successful!")
            print(f"   Access token: {result.get('access_token', 'N/A')[:50]}...")
            return True
        else:
            print(f"❌ Admin login failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error testing admin login: {e}")
        return False

if __name__ == "__main__":
    print("Starting admin user creation process...\n")
    
    # Create admin user
    if create_admin_user():
        # Test login
        if test_admin_login():
            print("\n🎉 SUCCESS! Admin user is ready!")
            print("\n📋 ADMIN CREDENTIALS:")
            print("   Username: oceanadmin")
            print("   Password: Ocean@Admin2025")
            print("   URL: http://localhost:3000/pages/analytics.html")
        else:
            print("\n⚠️  Admin user created but login test failed")
    else:
        print("\n❌ Failed to create admin user")
        
    print("\nDone!")