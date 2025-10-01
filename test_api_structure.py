#!/usr/bin/env python3
"""
Test API Response Structure for Incidents
"""

import requests
import json

def test_incidents_api():
    """Test the incidents API and check response structure"""
    
    base_url = "http://127.0.0.1:9000"
    
    # Login as rescue team
    login_data = {
        "username": "rescue_mumbai",
        "password": "Ocean@Admin2025"
    }
    
    try:
        print("🔐 Logging in as rescue team...")
        
        # Login
        response = requests.post(f"{base_url}/api/auth/login", data=login_data, timeout=10)
        
        if response.status_code == 200:
            result = response.json()
            token = result.get("access_token")
            print(f"   ✅ Login successful")
            
            # Test incidents API
            headers = {"Authorization": f"Bearer {token}"}
            incidents_response = requests.get(f"{base_url}/api/incidents/", headers=headers, timeout=10)
            
            print(f"\n📊 Testing incidents API...")
            print(f"   Status: {incidents_response.status_code}")
            
            if incidents_response.status_code == 200:
                incidents_data = incidents_response.json()
                print(f"   ✅ API working!")
                
                # Print the response structure
                print(f"\n📋 API Response Structure:")
                print(f"   Keys in response: {list(incidents_data.keys())}")
                
                if 'incidents' in incidents_data:
                    incidents_list = incidents_data['incidents']
                    print(f"   Total incidents: {len(incidents_list)}")
                    print(f"   Total count: {incidents_data.get('total', 'N/A')}")
                    print(f"   Page: {incidents_data.get('page', 'N/A')}")
                    
                    if incidents_list:
                        print(f"\n📝 Sample incident structure:")
                        sample = incidents_list[0]
                        print(f"   Keys: {list(sample.keys())}")
                        print(f"   Reference ID: {sample.get('reference_id', 'N/A')}")
                        print(f"   Hazard Type: {sample.get('hazard_type', 'N/A')}")
                        print(f"   Status: {sample.get('status', 'N/A')}")
                        print(f"   Location: {sample.get('location', 'N/A')}")
                        
                        # Check reporter info
                        if 'reporter' in sample:
                            reporter = sample['reporter']
                            print(f"   Reporter: {reporter.get('username', 'N/A')} (ID: {reporter.get('id', 'N/A')})")
                        elif 'reporter_id' in sample:
                            print(f"   Reporter ID: {sample['reporter_id']}")
                
                print(f"\n🎯 Response Summary:")
                print(f"   Structure: {json.dumps(incidents_data, indent=2)[:500]}...")
                
                return True
            else:
                print(f"   ❌ API failed: {incidents_response.text}")
                return False
                
        else:
            print(f"   ❌ Login failed: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False

if __name__ == "__main__":
    print("🔍 Testing Incidents API Response Structure")
    print("=" * 60)
    test_incidents_api()