#!/usr/bin/env python3
"""
Test Backend API Endpoints
"""

import requests
import time
import sys

def test_backend():
    """Test if backend is running and responsive"""
    
    print("🧪 Testing Ocean Guard Backend...")
    
    # Wait for server to start
    print("⏳ Waiting for server to start...")
    time.sleep(2)
    
    base_url = "http://localhost:9000"
    
    # Test health endpoint
    try:
        print("🔍 Testing health endpoint...")
        response = requests.get(f"{base_url}/health", timeout=5)
        if response.status_code == 200:
            print("✅ Health endpoint OK")
        else:
            print(f"❌ Health endpoint failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Health endpoint error: {e}")
        return False
    
    # Test public analytics endpoint
    try:
        print("🔍 Testing public analytics endpoint...")
        response = requests.get(f"{base_url}/api/analytics/public/dashboard", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print("✅ Public analytics OK")
            print(f"📊 Total incidents: {data.get('total_incidents', 0)}")
            print(f"🔥 Active incidents: {data.get('active_incidents', 0)}")
            print(f"✅ Resolved incidents: {data.get('resolved_incidents', 0)}")
        else:
            print(f"❌ Public analytics failed: {response.status_code}")
            print(f"   Response: {response.text}")
    except Exception as e:
        print(f"❌ Public analytics error: {e}")
    
    # Test timeline endpoint
    try:
        print("🔍 Testing timeline endpoint...")
        response = requests.get(f"{base_url}/api/analytics/public/timeline", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Timeline OK - {len(data)} data points")
        else:
            print(f"❌ Timeline failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Timeline error: {e}")
    
    return True

if __name__ == "__main__":
    test_backend()