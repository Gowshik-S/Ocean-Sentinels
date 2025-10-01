#!/usr/bin/env python3
"""Simple test to check if the Ocean Hazard server is running"""

import requests
import time

def test_connection():
    try:
        response = requests.get('http://127.0.0.1:9000/health', timeout=5)
        print(f"✅ Server is running! Status: {response.status_code}")
        return True
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to server at http://127.0.0.1:9000")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    print("Testing Ocean Hazard server connection...")
    test_connection()