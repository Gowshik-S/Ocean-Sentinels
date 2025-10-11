import requests

def simple_admin_test():
    base_url = "http://127.0.0.1:9000"
    
    try:
        print("🔐 Testing OceanAdmin login...")
        response = requests.post(
            f"{base_url}/api/auth/login",
            data={"username": "OceanAdmin", "password": "admin"},
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            timeout=10
        )
        
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text[:200]}...")
        
        if response.status_code == 200:
            print("✅ Admin login works!")
        else:
            print("❌ Admin login failed")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    simple_admin_test()