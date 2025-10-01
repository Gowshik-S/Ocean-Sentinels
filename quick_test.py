#!/usr/bin/env python3
"""
Quick Credential Test
"""

import requests
import json

def test_credentials():
    """Test all user credentials"""
    
    credentials = [
        {"username": "oceanadmin", "password": "Ocean@Admin2025", "expected_role": "ADMIN"},
        {"username": "rescue_team_mumbai", "password": "Rescue123!", "expected_role": "RESCUE_TEAM"},
        {"username": "rescue_team_chennai", "password": "Rescue123!", "expected_role": "RESCUE_TEAM"},
        {"username": "rescue_team_kochi", "password": "Rescue123!", "expected_role": "RESCUE_TEAM"},
    ]
    
    print("🔐 Testing All Credentials")
    print("=" * 50)
    
    for cred in credentials:
        try:
            response = requests.post(
                "http://localhost:9000/api/auth/login",
                data=cred,
                timeout=5
            )
            
            if response.status_code == 200:
                user_data = response.json()
                role = user_data['user']['role']
                print(f"✅ {cred['username']}: LOGIN SUCCESS (Role: {role})")
                
                if role != cred['expected_role']:
                    print(f"   ⚠️  Expected {cred['expected_role']}, got {role}")
            else:
                print(f"❌ {cred['username']}: LOGIN FAILED ({response.status_code})")
                
        except Exception as e:
            print(f"❌ {cred['username']}: ERROR - {e}")
    
    print("\n🌐 Access URLs:")
    print("   Admin Dashboard: http://localhost:3000/pages/analytics.html")
    print("   Incident Reports: http://localhost:3000/pages/reports.html")

if __name__ == "__main__":
    test_credentials()