import requests
import json

# Test data
test_user = {
    "username": "testuser123",
    "email": "testuser123@example.com",
    "password": "test123",
    "first_name": "Test",
    "last_name": "User",
    "phone": "1234567890",
    "location": "Test Location"
}

try:
    # Test registration
    print("🧪 Testing registration endpoint...")
    response = requests.post(
        "http://localhost:8001/api/auth/register",
        json=test_user,
        headers={"Content-Type": "application/json"}
    )
    
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")
    
    if response.status_code == 200:
        print("✅ Registration successful!")
        user_data = response.json()
        print(f"User ID: {user_data.get('id')}")
        print(f"Username: {user_data.get('username')}")
        print(f"Email: {user_data.get('email')}")
    else:
        print("❌ Registration failed!")
        
except Exception as e:
    print(f"❌ Error: {e}")