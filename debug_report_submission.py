#!/usr/bin/env python3
"""
Debug Report Submission Issues
Test report submission to identify the root cause of [object Object] error
"""

import requests
import json

def test_backend_connection():
    """Test if backend is running and accessible"""
    try:
        response = requests.get("http://127.0.0.1:9000/health", timeout=5)
        print(f"✅ Backend Health: {response.status_code} - {response.json()}")
        return True
    except Exception as e:
        print(f"❌ Backend Connection Failed: {e}")
        return False

def test_create_incident():
    """Test incident creation endpoint"""
    print("\n🧪 Testing Incident Creation Endpoint")
    
    # First, login to get a token
    try:
        login_response = requests.post(
            "http://127.0.0.1:9000/api/auth/login",
            data={
                "username": "demo_citizen",
                "password": "citizen123"
            },
            timeout=10
        )
        
        if login_response.status_code != 200:
            print(f"❌ Login failed: {login_response.status_code} - {login_response.text}")
            return
        
        login_data = login_response.json()
        token = login_data["access_token"]
        print(f"✅ Login successful, got token: {token[:30]}...")
        
        # Now test incident creation
        incident_data = {
            "hazard_type": "high-waves",  # Using correct enum value
            "location": "Test Location - Mumbai Coast",
            "latitude": 19.0760,
            "longitude": 72.8777,
            "description": "Test incident submission from debug script",
            "contact_info": "debug@test.com",
            "urgency": "medium"  # Using lowercase as per enum
        }
        
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        print(f"📤 Sending incident data: {json.dumps(incident_data, indent=2)}")
        
        incident_response = requests.post(
            "http://127.0.0.1:9000/api/incidents/",
            headers=headers,
            json=incident_data,
            timeout=10
        )
        
        print(f"📥 Response Status: {incident_response.status_code}")
        print(f"📥 Response Headers: {dict(incident_response.headers)}")
        
        if incident_response.status_code == 200:
            response_data = incident_response.json()
            print(f"✅ Incident creation successful!")
            print(f"📋 Response: {json.dumps(response_data, indent=2)}")
        else:
            print(f"❌ Incident creation failed: {incident_response.status_code}")
            print(f"📋 Error Response: {incident_response.text}")
            
            # Try to parse as JSON for better error info
            try:
                error_data = incident_response.json()
                print(f"📋 Parsed Error: {json.dumps(error_data, indent=2)}")
            except:
                print("📋 Could not parse error as JSON")
        
    except Exception as e:
        print(f"❌ Test failed with exception: {e}")
        print(f"📋 Exception type: {type(e)}")

def test_without_auth():
    """Test incident creation without authentication (should fail properly)"""
    print("\n🧪 Testing Incident Creation Without Auth (Should Fail)")
    
    incident_data = {
        "hazard_type": "flooding",  # Using correct enum value
        "location": "Test Location",
        "description": "Test incident without auth",
        "urgency": "low"  # Using lowercase as per enum
    }
    
    try:
        response = requests.post(
            "http://127.0.0.1:9000/api/incidents/",
            json=incident_data,
            timeout=10
        )
        
        print(f"📥 Status: {response.status_code}")
        print(f"📥 Response: {response.text}")
        
        if response.status_code == 401:
            print("✅ Properly rejected unauthorized request")
        else:
            print("⚠️ Unexpected response for unauthorized request")
            
    except Exception as e:
        print(f"❌ Test failed: {e}")

if __name__ == "__main__":
    print("🌊 Ocean Hazard - Report Submission Debug")
    print("=" * 50)
    
    if test_backend_connection():
        test_create_incident()
        test_without_auth()
    else:
        print("\n💡 Please start the backend server with: python start_ocean_hazard.py")