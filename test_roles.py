#!/usr/bin/env python3
"""
Test Rescue Team Login
Tests the rescue team credentials we created
"""

import requests
import json

def test_rescue_team_login():
    """Test login with rescue team credentials"""
    rescue_teams = [
        {"username": "rescue_mumbai", "password": "rescue123"},
        {"username": "rescue_chennai", "password": "rescue123"},
        {"username": "rescue_kochi", "password": "rescue123"}
    ]
    
    print("🚁 Testing Rescue Team Credentials...")
    
    for team in rescue_teams:
        print(f"\n🧪 Testing: {team['username']}")
        
        try:
            response = requests.post(
                "http://localhost:9000/api/auth/login",
                data=team,
                timeout=10
            )
            
            if response.status_code == 200:
                login_data = response.json()
                print(f"✅ LOGIN SUCCESS!")
                print(f"👤 User: {login_data['user']['first_name']} {login_data['user']['last_name']}")
                print(f"🎭 Role: {login_data['user']['role']}")
                print(f"📍 Location: {login_data['user']['location']}")
            else:
                print(f"❌ Login failed: {response.status_code}")
                print(f"   Response: {response.text}")
                
        except Exception as e:
            print(f"❌ Error: {e}")
    
    return True

def test_admin_access():
    """Test admin access"""
    print(f"\n🔐 Testing Admin Access...")
    
    admin_creds = {"username": "oceanadmin", "password": "Ocean@Admin2025"}
    
    try:
        response = requests.post(
            "http://localhost:9000/api/auth/login",
            data=admin_creds,
            timeout=10
        )
        
        if response.status_code == 200:
            login_data = response.json()
            print(f"✅ ADMIN LOGIN SUCCESS!")
            print(f"👤 User: {login_data['user']['first_name']} {login_data['user']['last_name']}")
            print(f"🎭 Role: {login_data['user']['role']}")
            
            # Test analytics access
            token = login_data['access_token']
            headers = {
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json"
            }
            
            analytics_response = requests.get(
                "http://localhost:9000/api/analytics/dashboard",
                headers=headers,
                timeout=10
            )
            
            if analytics_response.status_code == 200:
                print(f"✅ Analytics access OK!")
            else:
                print(f"❌ Analytics access failed: {analytics_response.status_code}")
                
        else:
            print(f"❌ Admin login failed: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Admin login error: {e}")

if __name__ == "__main__":
    print("🌊 Ocean Guard - Role Access Test")
    print("=" * 50)
    
    test_rescue_team_login()
    test_admin_access()
    
    print("\n" + "=" * 50)
    print("🎯 RESCUE TEAM CREDENTIALS:")
    print("   Mumbai: rescue_mumbai / rescue123")
    print("   Chennai: rescue_chennai / rescue123") 
    print("   Kochi: rescue_kochi / rescue123")
    print("\n🔑 ADMIN CREDENTIALS:")
    print("   Admin: oceanadmin / Ocean@Admin2025")
    print("\n🌐 ACCESS URLs:")
    print("   Reports Dashboard: http://localhost:3000/pages/reports.html")
    print("   Analytics: http://localhost:3000/pages/analytics.html")
    print("\nDone!")