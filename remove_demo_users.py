#!/usr/bin/env python3
"""
Remove Demo Users Information
Since there's no delete API endpoint, this script provides information
about demo users that should be removed manually from the database.
"""

import requests

def check_backend_running():
    """Check if the backend server is running"""
    try:
        response = requests.get("http://127.0.0.1:9000/health", timeout=5)
        return response.status_code == 200
    except:
        return False

def show_demo_users_info():
    """Show information about demo users to remove"""
    print("🗑️  Demo Users Removal Information")
    print("=" * 50)
    
    print("⚠️  IMPORTANT: Manual Database Cleanup Required")
    print("Since there's no delete API endpoint, you'll need to remove")
    print("these users manually from the database.")
    
    print("\n📋 DEMO USERS TO REMOVE:")
    print("-" * 40)
    
    demo_users = [
        {
            "username": "demo_citizen",
            "email": "citizen@oceanguard.demo",
            "role": "public"
        },
        {
            "username": "demo_admin",
            "email": "admin@oceanguard.demo",
            "role": "admin"
        },
        {
            "username": "demo_rescue",
            "email": "rescue@oceanguard.demo",
            "role": "rescue_team"
        },
        {
            "username": "demo_authority",
            "email": "authority@oceanguard.demo",
            "role": "authority"
        }
    ]
    
    for i, user in enumerate(demo_users, 1):
        print(f"{i}. Username: {user['username']}")
        print(f"   Email: {user['email']}")
        print(f"   Role: {user['role']}")
        print()
    
    print("🛠️  MANUAL REMOVAL OPTIONS:")
    print("-" * 30)
    print("Option 1: Direct Database Access")
    print("  - Connect to: backend/database/ocean_hazard.db")
    print("  - Execute SQL: DELETE FROM users WHERE username IN ('demo_citizen', 'demo_admin', 'demo_rescue', 'demo_authority');")
    print()
    print("Option 2: Database Tool")
    print("  - Use SQLite browser or similar tool")
    print("  - Open: backend/database/ocean_hazard.db")
    print("  - Delete rows where username starts with 'demo_'")
    print()
    print("Option 3: Recreate Database")
    print("  - Delete: backend/database/ocean_hazard.db")
    print("  - Restart backend to recreate clean database")

def generate_sql_script():
    """Generate SQL script to remove demo users"""
    print("\n📜 SQL SCRIPT FOR DEMO USER REMOVAL:")
    print("-" * 40)
    
    sql_script = """-- Remove demo users from Ocean Hazard database
DELETE FROM users WHERE username IN (
    'demo_citizen',
    'demo_admin', 
    'demo_rescue',
    'demo_authority'
);

-- Or remove by email pattern
DELETE FROM users WHERE email LIKE '%@oceanguard.demo';

-- Verify removal
SELECT id, username, email, role FROM users WHERE username LIKE 'demo_%';
"""
    
    print(sql_script)
    
    # Save to file
    try:
        with open('remove_demo_users.sql', 'w') as f:
            f.write(sql_script)
        print("✅ SQL script saved to: remove_demo_users.sql")
    except Exception as e:
        print(f"❌ Error saving SQL script: {e}")

def test_demo_login():
    """Test if demo users can still login (to verify they exist)"""
    if not check_backend_running():
        print("❌ Backend server is not running!")
        print("   Please start the backend with: python start_ocean_hazard.py")
        return
    
    print("\n� TESTING DEMO USER EXISTENCE:")
    print("-" * 35)
    
    demo_credentials = [
        ("demo_citizen", "citizen123"),
        ("demo_admin", "admin123"),
        ("demo_rescue", "rescue123"),
        ("demo_authority", "authority123")
    ]
    
    for username, password in demo_credentials:
        try:
            response = requests.post(
                "http://127.0.0.1:9000/api/auth/login",
                data={
                    "username": username,
                    "password": password
                },
                timeout=5
            )
            
            if response.status_code == 200:
                print(f"✅ {username} - EXISTS (can login)")
            else:
                print(f"❌ {username} - NOT FOUND or invalid credentials")
                
        except Exception as e:
            print(f"❌ {username} - ERROR: {str(e)}")

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Information about removing demo users")
    parser.add_argument("--sql", action="store_true", help="Generate SQL removal script")
    parser.add_argument("--test", action="store_true", help="Test if demo users exist")
    args = parser.parse_args()
    
    if args.sql:
        generate_sql_script()
    elif args.test:
        test_demo_login()
    else:
        show_demo_users_info()