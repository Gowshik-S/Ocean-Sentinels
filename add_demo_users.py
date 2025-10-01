#!/usr/bin/env python3
"""
Add Demo Users to Database via API
Creates test admin and citizen accounts using the API endpoints.
These can be deleted after development is complete.
"""

import requests
import json
from datetime import datetime

def check_backend_running():
    """Check if the backend server is running"""
    try:
        response = requests.get("http://127.0.0.1:9000/health", timeout=5)
        return response.status_code == 200
    except:
        return False

def register_user(user_data):
    """Register a user via API"""
    try:
        response = requests.post(
            "http://127.0.0.1:9000/api/auth/register",
            json=user_data,
            timeout=10
        )
        
        if response.status_code == 200:
            return response.json()
        else:
            print(f"❌ Registration failed for {user_data['username']}: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Error registering {user_data['username']}: {str(e)}")
        return None

def login_user(username, password):
    """Test login for a user"""
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
            return response.json()
        else:
            print(f"❌ Login failed for {username}: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Error logging in {username}: {str(e)}")
        return None

def add_demo_users():
    """Add demo users to the database via API"""
    print("🌊 Adding Demo Users to Ocean Hazard Database")
    print("=" * 50)
    
    # Check if backend is running
    if not check_backend_running():
        print("❌ Backend server is not running!")
        print("   Please start the backend with: python start_ocean_hazard.py")
        return []
    
    print("✅ Backend server is running")
    
    # Demo users to create
    demo_users = [
        {
            "username": "demo_citizen",
            "email": "citizen@oceanguard.demo",
            "password": "citizen123",
            "first_name": "Demo",
            "last_name": "Citizen",
            "phone": "9876543210",
            "location": "Mumbai Coast"
        },
        {
            "username": "demo_admin",
            "email": "admin@oceanguard.demo", 
            "password": "admin123",
            "first_name": "Demo",
            "last_name": "Administrator",
            "phone": "9876543211",
            "location": "Coast Guard HQ"
        },
        {
            "username": "demo_rescue",
            "email": "rescue@oceanguard.demo",
            "password": "rescue123", 
            "first_name": "Demo",
            "last_name": "Rescue Team",
            "phone": "9876543212",
            "location": "Chennai Rescue Station"
        },
        {
            "username": "demo_authority",
            "email": "authority@oceanguard.demo",
            "password": "authority123",
            "first_name": "Demo", 
            "last_name": "Authority",
            "phone": "9876543213",
            "location": "Coastal Authority Office"
        }
    ]
    
    created_users = []
    
    print("\n🔄 Creating demo users...")
    
    for user_data in demo_users:
        print(f"\n👤 Creating {user_data['username']}...")
        
        # Try to register the user
        result = register_user(user_data)
        
        if result:
            print(f"✅ Created user: {user_data['username']} (ID: {result.get('id', 'N/A')})")
            created_users.append(user_data)
            
            # Test login immediately
            print(f"🔐 Testing login for {user_data['username']}...")
            login_result = login_user(user_data['username'], user_data['password'])
            
            if login_result:
                print(f"✅ Login successful for {user_data['username']}")
            else:
                print(f"⚠️  Login test failed for {user_data['username']}")
        else:
            print(f"❌ Failed to create {user_data['username']}")
    
    print("\n" + "=" * 50)
    print("🎉 Demo User Creation Complete!")
    print("\n📋 CREATED USERS & LOGIN CREDENTIALS:")
    print("-" * 40)
    
    for user_data in created_users:
        print(f"👤 {user_data['username']} / {user_data['password']}")
        print(f"   📧 {user_data['email']}")
        print(f"   📍 {user_data['location']}")
        print()
    
    print(f"📊 Total users created: {len(created_users)}")
    print("\n💡 USAGE NOTES:")
    print("- These users can now login through the web interface")
    print("- demo_citizen: Regular user access")
    print("- demo_admin/demo_rescue/demo_authority: Administrative access")
    print("\n🗑️  To remove these demo users later, use: python remove_demo_users.py")
    
    return created_users

def list_users_info():
    """Display information about demo users"""
    print("\n📋 DEMO USER INFORMATION:")
    print("-" * 30)
    print("👤 demo_citizen / citizen123")
    print("   📧 citizen@oceanguard.demo")
    print("   🎯 Role: Public user")
    print("   📍 Mumbai Coast")
    print()
    print("👤 demo_admin / admin123")
    print("   📧 admin@oceanguard.demo") 
    print("   🎯 Role: Administrator")
    print("   � Coast Guard HQ")
    print()
    print("👤 demo_rescue / rescue123")
    print("   📧 rescue@oceanguard.demo")
    print("   🎯 Role: Rescue Team")
    print("   � Chennai Rescue Station")
    print()
    print("👤 demo_authority / authority123")
    print("   📧 authority@oceanguard.demo")
    print("   🎯 Role: Authority")
    print("   📍 Coastal Authority Office")

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Add demo users to Ocean Hazard database")
    parser.add_argument("--info", action="store_true", help="Show demo user information")
    args = parser.parse_args()
    
    if args.info:
        list_users_info()
    else:
        add_demo_users()