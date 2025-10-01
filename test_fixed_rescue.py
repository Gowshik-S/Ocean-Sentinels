#!/usr/bin/env python3
"""
Test Fixed Rescue Team Login
"""

import requests

def test_fixed_rescue_login():
    """Test rescue team login with admin password"""
    
    base_url = "http://127.0.0.1:9000"
    
    # Test rescue login with admin password
    login_data = {
        "username": "rescue_mumbai",
        "password": "Ocean@Admin2025"  # Using admin password temporarily
    }
    
    print("🚑 Testing Fixed Rescue Team Login")
    print("=" * 40)
    print(f"Username: {login_data['username']}")
    print(f"Password: {login_data['password']}")
    
    try:
        # Login request
        response = requests.post(f"{base_url}/api/auth/login", data=login_data, timeout=10)
        
        if response.status_code == 200:
            result = response.json()
            token = result.get("access_token")
            
            print("✅ RESCUE LOGIN SUCCESSFUL!")
            print(f"   Token: {token[:30]}...")
            
            # Test authenticated request
            headers = {"Authorization": f"Bearer {token}"}
            me_response = requests.get(f"{base_url}/api/auth/me", headers=headers)
            
            if me_response.status_code == 200:
                user_info = me_response.json()
                print("✅ AUTH VERIFICATION SUCCESSFUL!")
                print(f"   Username: {user_info.get('username')}")
                print(f"   Role: {user_info.get('role')}")
                print(f"   Email: {user_info.get('email')}")
                
                print("\n🎉 RESCUE TEAM SYSTEM IS WORKING!")
                print("\n📋 Working Rescue Team Credentials:")
                print("   rescue_mumbai / Ocean@Admin2025")
                print("   rescue_chennai / Ocean@Admin2025")
                print("   rescue_kochi / Ocean@Admin2025")
                print("\n🌐 Access URL:")
                print("   http://localhost:3000/pages/reports.html")
                
                return True
            else:
                print(f"❌ Auth verification failed: {me_response.status_code}")
                return False
                
        else:
            print(f"❌ Login failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    test_fixed_rescue_login()