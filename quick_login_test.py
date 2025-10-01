#!/usr/bin/env python3
"""
Quick Ocean Hazard Login Test
Test the login functionality directly
"""

import requests
import json

def test_login_endpoints():
    """Test login endpoints and functionality"""
    backend_url = "http://127.0.0.1:9000"
    
    print("🌊 Ocean Hazard - Quick Login Test")
    print("=" * 40)
    
    # Test 1: Backend health
    try:
        print("🔄 Testing backend health...")
        response = requests.get(f"{backend_url}/health", timeout=5)
        if response.status_code == 200:
            print("✅ Backend server is running")
            data = response.json()
            print(f"   Status: {data.get('status')}")
        else:
            print(f"❌ Backend health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Backend server not accessible: {str(e)}")
        print("   Please start the backend with: python start_ocean_hazard.py")
        return False
    
    # Test 2: Check authentication requirement
    try:
        print("\n🔄 Testing authentication requirement...")
        response = requests.get(f"{backend_url}/api/incidents/")
        if response.status_code == 401:
            print("✅ API properly requires authentication")
        else:
            print(f"❌ Expected 401, got {response.status_code}")
    except Exception as e:
        print(f"❌ Auth test failed: {str(e)}")
    
    # Test 3: Registration endpoint
    try:
        print("\n🔄 Testing registration endpoint...")
        test_user = {
            "username": f"logintest_user",
            "email": f"logintest@example.com",
            "password": "testpassword123",
            "first_name": "Login",
            "last_name": "Test",
            "phone": "1234567890",
            "location": "Test Location"
        }
        
        response = requests.post(
            f"{backend_url}/api/auth/register",
            json=test_user,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            print("✅ Registration successful")
            user_data = response.json()
            print(f"   User ID: {user_data.get('id')}")
            
            # Test 4: Login with the registered user
            print("\n🔄 Testing login with registered user...")
            login_data = {
                "username": test_user["username"],
                "password": test_user["password"]
            }
            
            login_response = requests.post(
                f"{backend_url}/api/auth/login",
                data=login_data
            )
            
            if login_response.status_code == 200:
                print("✅ Login successful")
                login_result = login_response.json()
                print(f"   Token type: {login_result.get('token_type')}")
                print(f"   User: {login_result.get('user', {}).get('username')}")
                return True
            else:
                print(f"❌ Login failed: {login_response.status_code}")
                print(f"   Error: {login_response.json().get('detail', 'Unknown')}")
                return False
                
        elif response.status_code == 400:
            print("⚠️  User already exists, testing login with existing user...")
            
            # Try login with existing user
            login_data = {
                "username": test_user["username"],
                "password": test_user["password"]
            }
            
            login_response = requests.post(
                f"{backend_url}/api/auth/login",
                data=login_data
            )
            
            if login_response.status_code == 200:
                print("✅ Login successful with existing user")
                return True
            else:
                print(f"❌ Login failed with existing user: {login_response.status_code}")
                return False
        else:
            print(f"❌ Registration failed: {response.status_code}")
            print(f"   Error: {response.json().get('detail', 'Unknown')}")
            return False
            
    except Exception as e:
        print(f"❌ Registration/Login test failed: {str(e)}")
        return False

def main():
    """Main test function"""
    success = test_login_endpoints()
    
    print("\n" + "=" * 40)
    print("🎯 TEST RESULT")
    print("=" * 40)
    
    if success:
        print("✅ All login tests passed!")
        print("\n🔧 How to test in browser:")
        print("1. Open: http://localhost:3000/pages/index.html")
        print("2. Click 'Citizen Login/Register'")
        print("3. Try these options:")
        print("   • Demo login: username 'user' (no password needed)")
        print("   • Real login: use registered email and password")
        print("   • New user: click 'Register' tab to create account")
    else:
        print("❌ Some tests failed!")
        print("\n🔧 Troubleshooting:")
        print("1. Make sure backend is running: python start_ocean_hazard.py")
        print("2. Make sure frontend is running: python start_frontend.py")
        print("3. Check browser console for JavaScript errors")
    
    return success

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️ Test interrupted by user")
    except Exception as e:
        print(f"\n❌ Unexpected error: {str(e)}")