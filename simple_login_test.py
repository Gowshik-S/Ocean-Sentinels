#!/usr/bin/env python3
"""
Simple Login Test
Tests login credentials without starting server
"""

import requests
import json
import time

def test_login(username, password, expected_role=None):
    """Test a single login"""
    try:
        response = requests.post(
            "http://localhost:9000/api/auth/login",
            data={"username": username, "password": password},
            timeout=5
        )
        
        if response.status_code == 200:
            data = response.json()
            user = data.get('user', {})
            print(f"✅ {username} - LOGIN SUCCESS")
            print(f"   Role: {user.get('role', 'unknown')}")
            print(f"   Name: {user.get('first_name', '')} {user.get('last_name', '')}")
            
            if expected_role and user.get('role') == expected_role:
                print(f"   ✅ Role matches expected: {expected_role}")
            elif expected_role:
                print(f"   ❌ Role mismatch. Expected: {expected_role}, Got: {user.get('role')}")
            
            return True
        else:
            print(f"❌ {username} - LOGIN FAILED ({response.status_code})")
            return False
            
    except Exception as e:
        print(f"❌ {username} - ERROR: {e}")
        return False

def main():
    print("🔐 Testing Login Credentials")
    print("=" * 50)
    
    # Wait a moment for server to be ready
    time.sleep(2)
    
    # Test rescue teams
    rescue_teams = [
        ("rescue_mumbai", "rescue123", "rescue_team"),
        ("rescue_chennai", "rescue123", "rescue_team"),
        ("rescue_kochi", "rescue123", "rescue_team")
    ]
    
    print("\n🚁 RESCUE TEAMS:")
    for username, password, expected_role in rescue_teams:
        test_login(username, password, expected_role)
        print()
    
    # Test admin
    print("🔑 ADMIN:")
    test_login("oceanadmin", "Ocean@Admin2025", "admin")
    
    print("\n" + "=" * 50)
    print("🎯 SUMMARY:")
    print("   Frontend: http://localhost:3000")
    print("   Reports: http://localhost:3000/pages/reports.html")
    print("   Analytics: http://localhost:3000/pages/analytics.html")

if __name__ == "__main__":
    main()