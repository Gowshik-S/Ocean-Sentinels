#!/usr/bin/env python3
"""
Ocean Hazard POST Commands Test
Tests all POST endpoints with example requests
"""

import requests
import json
from datetime import datetime

# Server configuration
BASE_URL = "http://127.0.0.1:8002"
API_BASE = f"{BASE_URL}/api"

def test_post_commands():
    """Test all POST endpoints"""
    print("🌊 Ocean Hazard POST Commands Test")
    print("=" * 60)
    
    # Test credentials
    admin_token = None
    user_token = None
    
    # 1. Test Login (Form Data)
    print("\n1️⃣ Testing POST /api/auth/login (Form Data)")
    print("-" * 40)
    
    try:
        response = requests.post(f"{API_BASE}/auth/login", data={
            "username": "admin",
            "password": "admin"
        })
        
        if response.status_code == 200:
            result = response.json()
            admin_token = result.get("access_token")
            print(f"✅ Login successful!")
            print(f"   Token: {admin_token}")
            print(f"   User: {result['user']['username']} ({result['user']['role']})")
        else:
            print(f"❌ Login failed: {response.status_code} - {response.text}")
            
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # 2. Test Login JSON
    print("\n2️⃣ Testing POST /api/auth/login-json (JSON Data)")
    print("-" * 40)
    
    try:
        response = requests.post(f"{API_BASE}/auth/login-json", 
                               json={
                                   "username": "user",
                                   "password": "user"
                               },
                               headers={"Content-Type": "application/json"})
        
        if response.status_code == 200:
            result = response.json()
            user_token = result.get("access_token")
            print(f"✅ JSON Login successful!")
            print(f"   Token: {user_token}")
            print(f"   User: {result['user']['username']} ({result['user']['role']})")
        else:
            print(f"❌ JSON Login failed: {response.status_code} - {response.text}")
            
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # 3. Test Registration (JSON)
    print("\n3️⃣ Testing POST /api/auth/register (JSON)")
    print("-" * 40)
    
    try:
        timestamp = str(int(datetime.now().timestamp()))
        response = requests.post(f"{API_BASE}/auth/register", 
                               json={
                                   "username": f"testuser{timestamp}",
                                   "email": f"test{timestamp}@example.com",
                                   "password": "testpass123",
                                   "first_name": "Test",
                                   "last_name": "User"
                               },
                               headers={"Content-Type": "application/json"})
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Registration successful!")
            print(f"   Message: {result['message']}")
            print(f"   New User: {result['user']['username']} (ID: {result['user']['id']})")
        else:
            print(f"❌ Registration failed: {response.status_code} - {response.text}")
            
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # 4. Test Registration (Form Data)
    print("\n4️⃣ Testing POST /api/auth/register-form (Form Data)")
    print("-" * 40)
    
    try:
        timestamp = str(int(datetime.now().timestamp()) + 1)
        response = requests.post(f"{API_BASE}/auth/register-form", data={
            "username": f"formuser{timestamp}",
            "email": f"form{timestamp}@example.com",
            "password": "formpass123",
            "first_name": "Form",
            "last_name": "User"
        })
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Form registration successful!")
            print(f"   Message: {result['message']}")
            print(f"   New User: {result['user']['username']} (ID: {result['user']['id']})")
        else:
            print(f"❌ Form registration failed: {response.status_code} - {response.text}")
            
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # 5. Test Create Incident
    print("\n5️⃣ Testing POST /api/incidents/ (Create Incident)")
    print("-" * 40)
    
    if user_token:
        try:
            response = requests.post(f"{API_BASE}/incidents/", 
                                   json={
                                       "hazard_type": "HIGH_WAVES",
                                       "location": "Marina Beach, Chennai",
                                       "latitude": 13.0475,
                                       "longitude": 80.2824,
                                       "description": "Extremely high waves observed at Marina Beach. Dangerous for swimmers and fishermen.",
                                       "urgency": "HIGH",
                                       "contact_info": "+91 9876543210"
                                   },
                                   headers={
                                       "Content-Type": "application/json",
                                       "Authorization": f"Bearer {user_token}"
                                   })
            
            if response.status_code == 200:
                result = response.json()
                print(f"✅ Incident created successfully!")
                print(f"   Reference ID: {result['reference_id']}")
                print(f"   Status: {result['status']}")
                print(f"   Message: {result['message']}")
            else:
                print(f"❌ Incident creation failed: {response.status_code} - {response.text}")
                
        except Exception as e:
            print(f"❌ Error: {e}")
    else:
        print("❌ No user token available - skipping incident creation")
    
    # 6. Test Admin - Add Rescue Team
    print("\n6️⃣ Testing POST /api/admin/teams/ (Add Rescue Team)")
    print("-" * 40)
    
    if admin_token:
        try:
            response = requests.post(f"{API_BASE}/admin/teams/", 
                                   json={
                                       "id": 1,
                                       "name": "Chennai Coast Guard Team Alpha",
                                       "type": "marine_rescue",
                                       "location": "Chennai Port",
                                       "contact_number": "+91 44-25361234",
                                       "email": "alpha@chennaicoastguard.gov.in",
                                       "leader": "Captain Rajesh Kumar",
                                       "members_count": 12,
                                       "equipment": ["rescue_boats", "diving_gear", "medical_kit"],
                                       "status": "active"
                                   },
                                   headers={
                                       "Content-Type": "application/json",
                                       "Authorization": f"Bearer {admin_token}"
                                   })
            
            if response.status_code == 200:
                result = response.json()
                print(f"✅ Rescue team added successfully!")
                print(f"   Message: {result['message']}")
                print(f"   Team ID: {result['team_id']}")
            else:
                print(f"❌ Team addition failed: {response.status_code} - {response.text}")
                
        except Exception as e:
            print(f"❌ Error: {e}")
    else:
        print("❌ No admin token available - skipping team addition")
    
    # 7. Test Admin - Add Authority
    print("\n7️⃣ Testing POST /api/admin/authorities/ (Add Authority)")
    print("-" * 40)
    
    if admin_token:
        try:
            response = requests.post(f"{API_BASE}/admin/authorities/", 
                                   json={
                                       "id": 2,
                                       "name": "Dr. Priya Sharma",
                                       "position": "Regional Director",
                                       "email": "priya.sharma@tamilnadu.gov.in",
                                       "phone": "+91 44-28411234",
                                       "department": "Tamil Nadu State Disaster Management Authority",
                                       "level": "state",
                                       "jurisdiction": "Tamil Nadu coastal disaster management",
                                       "status": "active"
                                   },
                                   headers={
                                       "Content-Type": "application/json",
                                       "Authorization": f"Bearer {admin_token}"
                                   })
            
            if response.status_code == 200:
                result = response.json()
                print(f"✅ Authority added successfully!")
                print(f"   Message: {result['message']}")
                print(f"   Authority ID: {result['authority_id']}")
            else:
                print(f"❌ Authority addition failed: {response.status_code} - {response.text}")
                
        except Exception as e:
            print(f"❌ Error: {e}")
    else:
        print("❌ No admin token available - skipping authority addition")
    
    # Summary
    print("\n📋 POST Commands Summary")
    print("=" * 40)
    print("✅ Available POST endpoints:")
    print("   1. /api/auth/login (Form data)")
    print("   2. /api/auth/login-json (JSON data)")
    print("   3. /api/auth/register (JSON registration)")
    print("   4. /api/auth/register-form (Form registration)")
    print("   5. /api/incidents/ (Create incident)")
    print("   6. /api/admin/teams/ (Admin: Add rescue team)")
    print("   7. /api/admin/authorities/ (Admin: Add authority)")

def show_post_examples():
    """Show example POST requests"""
    print("\n📝 POST Request Examples")
    print("=" * 60)
    
    examples = [
        {
            "title": "1. Login with Form Data",
            "url": "/api/auth/login",
            "method": "POST",
            "content_type": "application/x-www-form-urlencoded",
            "data": "username=admin&password=admin"
        },
        {
            "title": "2. Login with JSON",
            "url": "/api/auth/login-json",
            "method": "POST",
            "content_type": "application/json",
            "data": '{"username": "user", "password": "user"}'
        },
        {
            "title": "3. Register User (JSON)",
            "url": "/api/auth/register",
            "method": "POST",
            "content_type": "application/json",
            "data": '''{
    "username": "newuser",
    "email": "newuser@example.com",
    "password": "securepass123",
    "first_name": "New",
    "last_name": "User"
}'''
        },
        {
            "title": "4. Create Incident Report",
            "url": "/api/incidents/",
            "method": "POST",
            "content_type": "application/json",
            "headers": "Authorization: Bearer <user_token>",
            "data": '''{
    "hazard_type": "TSUNAMI",
    "location": "Pondicherry Beach",
    "latitude": 11.9139,
    "longitude": 79.8145,
    "description": "Unusual wave patterns observed",
    "urgency": "HIGH",
    "contact_info": "+91 9876543210"
}'''
        },
        {
            "title": "5. Add Rescue Team (Admin Only)",
            "url": "/api/admin/teams/",
            "method": "POST",
            "content_type": "application/json",
            "headers": "Authorization: Bearer <admin_token>",
            "data": '''{
    "name": "Emergency Response Team",
    "type": "marine_rescue",
    "location": "Chennai Coast Guard Station",
    "contact_number": "+91 44-25361234",
    "email": "team@coastguard.gov.in",
    "leader": "Captain Smith",
    "members_count": 15,
    "status": "active"
}'''
        }
    ]
    
    for example in examples:
        print(f"\n{example['title']}")
        print("-" * 50)
        print(f"URL: {example['url']}")
        print(f"Method: {example['method']}")
        print(f"Content-Type: {example['content_type']}")
        if 'headers' in example:
            print(f"Headers: {example['headers']}")
        print(f"Data:\n{example['data']}")

if __name__ == "__main__":
    print("Choose an option:")
    print("1. Test all POST commands")
    print("2. Show POST request examples")
    print("3. Both")
    
    choice = input("\nEnter choice (1/2/3): ").strip()
    
    if choice in ['1', '3']:
        test_post_commands()
    
    if choice in ['2', '3']:
        show_post_examples()
    
    print("\n🎯 Test completed!")