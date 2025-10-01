#!/usr/bin/env python3
"""
Quick Login Test - Verify the enum fix worked
"""

import requests
import json

def test_admin_login():
    """Test admin login after enum fix"""
    
    base_url = "http://127.0.0.1:9000"
    
    # Test admin login
    login_data = {
        "username": "oceanadmin",
        "password": "Ocean@Admin2025"
    }
    
    print("🔐 Testing admin login...")
    
    try:
        # Login request
        response = requests.post(f"{base_url}/api/auth/login", data=login_data)
        
        if response.status_code == 200:
            result = response.json()
            token = result.get("access_token")
            
            print("✅ Admin login successful!")
            print(f"   Token: {token[:20]}...")
            
            # Test authenticated request
            headers = {"Authorization": f"Bearer {token}"}
            me_response = requests.get(f"{base_url}/api/auth/me", headers=headers)
            
            if me_response.status_code == 200:
                user_info = me_response.json()
                print("✅ Auth verification successful!")
                print(f"   Username: {user_info.get('username')}")
                print(f"   Role: {user_info.get('role')}")
                print(f"   Email: {user_info.get('email')}")
                return True
            else:
                print(f"❌ Auth verification failed: {me_response.status_code}")
                print(f"   Response: {me_response.text}")
                return False
                
        else:
            print(f"❌ Login failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error testing login: {e}")
        return False

def test_rescue_team_login():
    """Test rescue team login"""
    
    base_url = "http://127.0.0.1:9000"
    
    # Test rescue team login
    login_data = {
        "username": "rescue_mumbai",
        "password": "Rescue123!"
    }
    
    print("\n🚑 Testing rescue team login...")
    
    try:
        response = requests.post(f"{base_url}/api/auth/login", data=login_data)
        
        if response.status_code == 200:
            result = response.json()
            token = result.get("access_token")
            
            print("✅ Rescue team login successful!")
            print(f"   Token: {token[:20]}...")
            
            # Test authenticated request
            headers = {"Authorization": f"Bearer {token}"}
            me_response = requests.get(f"{base_url}/api/auth/me", headers=headers)
            
            if me_response.status_code == 200:
                user_info = me_response.json()
                print("✅ Rescue team auth verified!")
                print(f"   Username: {user_info.get('username')}")
                print(f"   Role: {user_info.get('role')}")
                return True
            else:
                print(f"❌ Rescue team auth failed: {me_response.status_code}")
                return False
                
        else:
            print(f"❌ Rescue team login failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error testing rescue login: {e}")
        return False

if __name__ == "__main__":
    print("🧪 Testing Login System After Enum Fix")
    print("=" * 50)
    
    admin_ok = test_admin_login()
    rescue_ok = test_rescue_team_login()
    
    print("\n" + "=" * 50)
    if admin_ok and rescue_ok:
        print("🎉 ALL TESTS PASSED! System is working correctly.")
        print("\n📋 Working Credentials:")
        print("   Admin: oceanadmin / Ocean@Admin2025")
        print("   Rescue: rescue_mumbai / Rescue123!")
        print("   Rescue: rescue_chennai / Rescue123!")
        print("   Rescue: rescue_kochi / Rescue123!")
        print("\n🌐 Access URLs:")
        print("   Admin Dashboard: http://localhost:3000/pages/analytics.html")
        print("   Reports Page: http://localhost:3000/pages/reports.html")
    else:
        print("❌ Some tests failed. Check the errors above.")