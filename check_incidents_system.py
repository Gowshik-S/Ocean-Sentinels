#!/usr/bin/env python3
"""
Check Incidents Database and API
"""

import sqlite3
import requests

def check_incidents_db():
    """Check if there are incidents in the database"""
    
    # Connect to database
    conn = sqlite3.connect('backend/database/ocean_hazard.db')
    cursor = conn.cursor()
    
    # Check incidents table
    cursor.execute('SELECT COUNT(*) FROM incidents')
    count = cursor.fetchone()[0]
    
    print(f"📊 Total incidents in database: {count}")
    
    if count > 0:
        cursor.execute('SELECT id, reference_id, hazard_type, location, status, created_at FROM incidents LIMIT 5')
        incidents = cursor.fetchall()
        
        print("📋 Recent incidents:")
        for incident in incidents:
            print(f"   ID: {incident[0]} | Ref: {incident[1]} | Type: {incident[2]} | Location: {incident[3]} | Status: {incident[4]}")
    else:
        print("⚠️ No incidents found in database")
    
    conn.close()
    return count

def test_incidents_api():
    """Test the incidents API endpoint"""
    
    base_url = "http://127.0.0.1:9000"
    
    # First login as rescue team
    login_data = {
        "username": "rescue_mumbai",
        "password": "Ocean@Admin2025"
    }
    
    try:
        print("\n🔐 Testing rescue team login...")
        
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
                print(f"   Total incidents: {incidents_data.get('total', 0)}")
                print(f"   Items returned: {len(incidents_data.get('items', []))}")
                
                if incidents_data.get('items'):
                    print("   📋 Sample incident:")
                    sample = incidents_data['items'][0]
                    print(f"      Ref: {sample.get('reference_id')}")
                    print(f"      Type: {sample.get('hazard_type')}")
                    print(f"      Status: {sample.get('status')}")
                
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

def create_sample_incidents():
    """Create sample incidents for testing"""
    
    # Connect to database
    conn = sqlite3.connect('backend/database/ocean_hazard.db')
    cursor = conn.cursor()
    
    print("\n🆕 Creating sample incidents...")
    
    sample_incidents = [
        ("OG-20250930-TEST001", "TIDAL_SURGE", "Mumbai Coast", 19.0760, 72.8777, "High tide surge reported near Marine Drive", "HIGH", "PENDING", "test@example.com"),
        ("OG-20250930-TEST002", "ROUGH_SEAS", "Chennai Marina", 13.0827, 80.2707, "Rough sea conditions, fishing boats advised to return", "MEDIUM", "PENDING", "chennai@example.com"),
        ("OG-20250930-TEST003", "COASTAL_EROSION", "Kochi Beach", 9.9312, 76.2673, "Severe erosion observed along coastline", "LOW", "PENDING", "kochi@example.com")
    ]
    
    for incident in sample_incidents:
        cursor.execute("""
            INSERT INTO incidents (
                reference_id, hazard_type, location, latitude, longitude, 
                description, urgency, status, contact_info, 
                reporter_id, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, CURRENT_TIMESTAMP)
        """, incident)
    
    conn.commit()
    conn.close()
    
    print(f"   ✅ Created {len(sample_incidents)} sample incidents")

if __name__ == "__main__":
    print("🔍 Checking Incidents System")
    print("=" * 50)
    
    # Check database
    incident_count = check_incidents_db()
    
    # Create sample data if none exists
    if incident_count == 0:
        create_sample_incidents()
        incident_count = check_incidents_db()
    
    # Test API
    api_working = test_incidents_api()
    
    print("\n" + "=" * 50)
    if api_working and incident_count > 0:
        print("🎉 INCIDENTS SYSTEM WORKING!")
        print("   Reports should now load in the frontend")
    else:
        print("❌ Issues found - check logs above")