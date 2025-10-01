#!/usr/bin/env python3
"""
Test Rescue Team Login After Password Fix
"""

import requests
import json

def test_rescue_login():
    """Test rescue team login"""
    
    base_url = "http://127.0.0.1:9000"
    
    # Test rescue teams
    rescue_teams = [
        "rescue_mumbai",
        "rescue_chennai", 
        "rescue_kochi"
    ]
    
    password = "Rescue123!"
    
    print("🚑 Testing Rescue Team Logins")
    print("=" * 40)
    
    all_success = True
    
    for username in rescue_teams:
        print(f"\n🔐 Testing {username}...")
        
        login_data = {
            "username": username,
            "password": password
        }
        
        try:
            # Login request
            response = requests.post(f"{base_url}/api/auth/login", data=login_data)
            
            if response.status_code == 200:
                result = response.json()
                token = result.get("access_token")
                
                print(f"   ✅ Login successful!")
                print(f"   Token: {token[:20]}...")
                
                # Test authenticated request
                headers = {"Authorization": f"Bearer {token}"}
                me_response = requests.get(f"{base_url}/api/auth/me", headers=headers)
                
                if me_response.status_code == 200:
                    user_info = me_response.json()
                    print(f"   ✅ Auth verified!")
                    print(f"   Role: {user_info.get('role')}")
                    print(f"   Email: {user_info.get('email')}")
                else:
                    print(f"   ❌ Auth verification failed: {me_response.status_code}")
                    all_success = False
                    
            else:
                print(f"   ❌ Login failed: {response.status_code}")
                print(f"   Response: {response.text}")
                all_success = False
                
        except Exception as e:
            print(f"   ❌ Error: {e}")
            all_success = False
    
    print("\n" + "=" * 40)
    if all_success:
        print("🎉 ALL RESCUE TEAM LOGINS WORKING!")
        print("\n📋 Working Credentials:")
        for team in rescue_teams:
            print(f"   {team} / {password}")
        print("\n🌐 Access URL:")
        print("   http://localhost:3000/pages/reports.html")
    else:
        print("❌ Some rescue team logins failed")

if __name__ == "__main__":
    test_rescue_login()