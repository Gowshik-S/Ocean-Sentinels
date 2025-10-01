#!/usr/bin/env python3
"""
Quick Status Check - Current Login Status
"""

import requests
import json

def quick_status_check():
    """Check current login status for all user types"""
    
    base_url = "http://127.0.0.1:9000"
    
    # Test credentials
    test_users = [
        {"username": "oceanadmin", "password": "Ocean@Admin2025", "type": "Admin"},
        {"username": "rescue_mumbai", "password": "Rescue123!", "type": "Rescue Team"},
        {"username": "rescue_chennai", "password": "Rescue123!", "type": "Rescue Team"},
        {"username": "rescue_kochi", "password": "Rescue123!", "type": "Rescue Team"}
    ]
    
    print("🔍 CURRENT SYSTEM STATUS CHECK")
    print("=" * 50)
    
    working_count = 0
    
    for user in test_users:
        print(f"\n🔐 Testing {user['type']}: {user['username']}")
        
        try:
            # Quick login test
            response = requests.post(f"{base_url}/api/auth/login", 
                                   data={"username": user["username"], "password": user["password"]},
                                   timeout=5)
            
            if response.status_code == 200:
                print(f"   ✅ Login SUCCESS")
                working_count += 1
            else:
                print(f"   ❌ Login FAILED ({response.status_code})")
                
        except requests.exceptions.ConnectionError:
            print(f"   ⚠️  Server not reachable")
        except Exception as e:
            print(f"   ❌ Error: {e}")
    
    print("\n" + "=" * 50)
    print(f"📊 SUMMARY: {working_count}/{len(test_users)} accounts working")
    
    if working_count == len(test_users):
        print("🎉 ALL SYSTEMS OPERATIONAL!")
        print("\n📋 Working Access:")
        print("   Admin Dashboard: http://localhost:3000/pages/analytics.html")
        print("   Reports Page: http://localhost:3000/pages/reports.html")
        print("\n🔑 Working Credentials:")
        print("   oceanadmin / Ocean@Admin2025 (Admin)")
        print("   rescue_mumbai / Rescue123! (Rescue Team)")
        print("   rescue_chennai / Rescue123! (Rescue Team)")
        print("   rescue_kochi / Rescue123! (Rescue Team)")
    else:
        print("⚠️  Some accounts need attention")

if __name__ == "__main__":
    quick_status_check()