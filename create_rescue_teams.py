#!/usr/bin/env python3
"""
Create Rescue Team Users
Creates rescue team accounts with proper permissions
"""

import requests
import json

def create_rescue_teams():
    """Create rescue team users"""
    
    rescue_teams = [
        {
            "username": "rescue_mumbai",
            "email": "rescue.mumbai@oceanguard.gov.in",
            "password": "Rescue@Mumbai2025",
            "first_name": "Mumbai",
            "last_name": "Rescue Team",
            "phone": "022-2266-5544",
            "location": "Mumbai Coast Guard Station",
            "role": "RESCUE_TEAM"
        },
        {
            "username": "rescue_chennai",
            "email": "rescue.chennai@oceanguard.gov.in", 
            "password": "Rescue@Chennai2025",
            "first_name": "Chennai",
            "last_name": "Rescue Team",
            "phone": "044-2536-0147",
            "location": "Chennai Port Rescue Station",
            "role": "RESCUE_TEAM"
        },
        {
            "username": "rescue_kochi",
            "email": "rescue.kochi@oceanguard.gov.in",
            "password": "Rescue@Kochi2025", 
            "first_name": "Kochi",
            "last_name": "Rescue Team",
            "phone": "0484-266-2341",
            "location": "Kochi Naval Base",
            "role": "RESCUE_TEAM"
        },
        {
            "username": "rescue_visakhapatnam",
            "email": "rescue.vizag@oceanguard.gov.in",
            "password": "Rescue@Vizag2025",
            "first_name": "Visakhapatnam", 
            "last_name": "Rescue Team",
            "phone": "0891-256-4789",
            "location": "Visakhapatnam Port",
            "role": "RESCUE_TEAM"
        }
    ]
    
    print("🛟 Ocean Guard - Rescue Team Registration")
    print("=" * 50)
    
    # Check backend
    try:
        response = requests.get("http://localhost:9000/health", timeout=5)
        print("✅ Backend server accessible")
    except:
        print("❌ Backend server not running!")
        print("   Please start: python start_ocean_hazard.py")
        return False
    
    created_teams = []
    
    for team in rescue_teams:
        try:
            print(f"\n🏥 Creating {team['first_name']} Rescue Team...")
            
            response = requests.post(
                "http://localhost:9000/api/auth/register",
                json=team,
                timeout=10
            )
            
            if response.status_code == 200:
                result = response.json()
                print(f"✅ {team['first_name']} team created!")
                print(f"   Username: {team['username']}")
                print(f"   Password: {team['password']}")
                print(f"   Location: {team['location']}")
                created_teams.append(team)
            else:
                print(f"⚠️  {team['first_name']} team: {response.text}")
                
        except Exception as e:
            print(f"❌ Error creating {team['first_name']} team: {e}")
    
    if created_teams:
        print("\n" + "=" * 50)
        print("🎉 RESCUE TEAMS CREATED!")
        print("=" * 50)
        print("🚁 Access Details:")
        for team in created_teams:
            print(f"📍 {team['first_name']} Rescue Team:")
            print(f"   Username: {team['username']}")
            print(f"   Password: {team['password']}")
            print(f"   Location: {team['location']}")
            print()
        
        print("🔗 Incident Reports Access: http://localhost:3000/pages/reports.html")
        return True
    
    return False

def test_rescue_login():
    """Test rescue team login"""
    print("\n🧪 Testing Rescue Team Login...")
    
    test_creds = {
        "username": "rescue_mumbai",
        "password": "Rescue@Mumbai2025"
    }
    
    try:
        response = requests.post(
            "http://localhost:9000/api/auth/login",
            data=test_creds,
            timeout=10
        )
        
        if response.status_code == 200:
            login_data = response.json()
            print("✅ Rescue team login successful!")
            print(f"👤 Team: {login_data['user']['first_name']} {login_data['user']['last_name']}")
            print(f"🎭 Role: {login_data['user']['role']}")
            return True
        else:
            print(f"❌ Rescue login failed: {response.text}")
            
    except Exception as e:
        print(f"❌ Login test error: {e}")
    
    return False

if __name__ == "__main__":
    if create_rescue_teams():
        test_rescue_login()
        print("\n🌊 Rescue teams are ready for deployment!")