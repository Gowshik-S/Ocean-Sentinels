#!/usr/bin/env python3
"""
Simple manual test for Ocean Hazard server
"""

import sqlite3
import os
import sys

# Add the backend to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend'))

DB_PATH = "backend/database/ocean_hazard.db"

def test_database_direct():
    """Test database connection directly"""
    print("🔍 Testing Database Connection")
    print("=" * 35)
    
    try:
        # Check if database file exists
        print(f"Database path: {DB_PATH}")
        print(f"Database exists: {os.path.exists(DB_PATH)}")
        
        # Connect to database
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        # Check tables
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = cursor.fetchall()
        print(f"Tables found: {[table[0] for table in tables]}")
        
        # Check users table
        if ('users',) in tables:
            cursor.execute('SELECT COUNT(*) FROM users')
            user_count = cursor.fetchone()[0]
            print(f"Total users: {user_count}")
            
            # Get recent users
            cursor.execute('SELECT id, username, email, created_at FROM users ORDER BY created_at DESC LIMIT 5')
            recent_users = cursor.fetchall()
            print("Recent users:")
            for user in recent_users:
                print(f"  ID: {user[0]}, Username: {user[1]}, Email: {user[2]}, Created: {user[3]}")
        
        # Check incidents table
        if ('incidents',) in tables:
            cursor.execute('SELECT COUNT(*) FROM incidents')
            incident_count = cursor.fetchone()[0]
            print(f"Total incidents: {incident_count}")
            
            # Get recent incidents
            cursor.execute('SELECT id, reference_id, hazard_type, status, created_at FROM incidents ORDER BY created_at DESC LIMIT 5')
            recent_incidents = cursor.fetchall()
            print("Recent incidents:")
            for incident in recent_incidents:
                print(f"  ID: {incident[0]}, Ref: {incident[1]}, Type: {incident[2]}, Status: {incident[3]}, Created: {incident[4]}")
        
        conn.close()
        print("✅ Database connection successful!")
        return True
        
    except Exception as e:
        print(f"❌ Database error: {e}")
        return False

def manual_user_registration():
    """Manually register a user in the database"""
    print("\n📝 Manual User Registration Test")
    print("=" * 40)
    
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        # Simple hash function (for testing)
        import hashlib
        def hash_password(password):
            return hashlib.sha256(password.encode()).hexdigest()
        
        # Test user data
        from datetime import datetime
        username = f"manual_test_{datetime.now().strftime('%H%M%S')}"
        email = f"manual_test_{datetime.now().strftime('%H%M%S')}@example.com"
        password = "testpass123"
        hashed_pw = hash_password(password)
        
        print(f"Creating user: {username}")
        print(f"Email: {email}")
        
        # Insert user
        cursor.execute('''
            INSERT INTO users (username, email, hashed_password, first_name, last_name, phone, location, role, is_active, is_verified)
            VALUES (?, ?, ?, ?, ?, ?, ?, 'PUBLIC', 1, 0)
        ''', (username, email, hashed_pw, "Manual", "Test", "1234567890", "test-location"))
        
        user_id = cursor.lastrowid
        conn.commit()
        
        print(f"✅ User created with ID: {user_id}")
        
        # Verify user was created
        cursor.execute('SELECT id, username, email, first_name, last_name FROM users WHERE id = ?', (user_id,))
        user_data = cursor.fetchone()
        
        if user_data:
            print(f"✅ User verified: {user_data}")
        else:
            print("❌ User verification failed")
        
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Registration error: {e}")
        return False

def manual_incident_creation():
    """Manually create an incident in the database"""
    print("\n📋 Manual Incident Creation Test")
    print("=" * 42)
    
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        # Get a user ID for the incident
        cursor.execute('SELECT id FROM users LIMIT 1')
        user_row = cursor.fetchone()
        if not user_row:
            print("❌ No users found. Cannot create incident.")
            return False
        
        user_id = user_row[0]
        
        # Create incident
        from datetime import datetime
        import random
        
        reference_id = f"OG-{datetime.now().strftime('%Y%m%d%H%M%S')}-{random.randint(1000, 9999)}"
        
        cursor.execute('''
            INSERT INTO incidents (
                reference_id, hazard_type, location, latitude, longitude,
                description, urgency, status, contact_info, reporter_id, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            reference_id,
            "HIGH_WAVES",
            "Test Beach, Test City",
            12.9716,
            77.5946,
            "Manual test incident creation",
            "MEDIUM",
            "PENDING",
            "test@example.com",
            user_id,
            datetime.now().isoformat()
        ))
        
        incident_id = cursor.lastrowid
        conn.commit()
        
        print(f"✅ Incident created with ID: {incident_id}")
        print(f"Reference ID: {reference_id}")
        
        # Verify incident was created
        cursor.execute('SELECT id, reference_id, hazard_type, status FROM incidents WHERE id = ?', (incident_id,))
        incident_data = cursor.fetchone()
        
        if incident_data:
            print(f"✅ Incident verified: {incident_data}")
        else:
            print("❌ Incident verification failed")
        
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Incident creation error: {e}")
        return False

def main():
    print("🌊 Ocean Hazard Manual Database Test")
    print("="*50)
    
    # Test database connection
    db_success = test_database_direct()
    
    if db_success:
        # Test user registration
        registration_success = manual_user_registration()
        
        # Test incident creation
        incident_success = manual_incident_creation()
        
        # Final summary
        print(f"\n🎯 Test Summary")
        print("=" * 15)
        print(f"✅ Database Connection: {'Success' if db_success else 'Failed'}")
        print(f"✅ User Registration: {'Success' if registration_success else 'Failed'}")
        print(f"✅ Incident Creation: {'Success' if incident_success else 'Failed'}")
        
        if db_success and registration_success and incident_success:
            print(f"\n🎉 ALL TESTS PASSED!")
            print(f"✅ SQLite database is working correctly!")
            print(f"✅ Frontend should be able to connect to the database through the API")
        else:
            print(f"\n❌ Some tests failed. Check the database configuration.")
    
    else:
        print("\n❌ Database connection failed. Cannot proceed with other tests.")

if __name__ == "__main__":
    main()