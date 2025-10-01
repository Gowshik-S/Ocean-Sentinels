#!/usr/bin/env python3
"""
Ocean Hazard - Comprehensive System Test
Tests all components: backend, database, API endpoints, authentication
"""

import requests
import json
import time
import sqlite3
import sys
import os
from datetime import datetime

# Configuration
BACKEND_URL = "http://127.0.0.1:9000"
DATABASE_PATH = "backend/database/ocean_hazard.db"

class OceanHazardTester:
    def __init__(self):
        self.test_results = []
        self.token = None
        self.test_user_id = None
        
    def log_test(self, test_name, status, message="", details=None):
        """Log test results"""
        result = {
            "test": test_name,
            "status": status,
            "message": message,
            "timestamp": datetime.now().isoformat(),
            "details": details
        }
        self.test_results.append(result)
        
        status_icon = "✅" if status == "PASS" else "❌" if status == "FAIL" else "⚠️"
        print(f"{status_icon} {test_name}: {message}")
        
        if details:
            print(f"    Details: {details}")
    
    def test_backend_health(self):
        """Test if backend server is running"""
        try:
            response = requests.get(f"{BACKEND_URL}/health", timeout=5)
            if response.status_code == 200:
                data = response.json()
                self.log_test("Backend Health", "PASS", f"Server responding: {data.get('status')}")
                return True
            else:
                self.log_test("Backend Health", "FAIL", f"Unexpected status code: {response.status_code}")
                return False
        except Exception as e:
            self.log_test("Backend Health", "FAIL", f"Connection failed: {str(e)}")
            return False
    
    def test_database_connection(self):
        """Test SQLite database connection and tables"""
        try:
            if not os.path.exists(DATABASE_PATH):
                self.log_test("Database Connection", "FAIL", f"Database file not found: {DATABASE_PATH}")
                return False
            
            conn = sqlite3.connect(DATABASE_PATH)
            cursor = conn.cursor()
            
            # Check if tables exist
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
            tables = [row[0] for row in cursor.fetchall()]
            
            required_tables = ['users', 'incidents']
            missing_tables = [table for table in required_tables if table not in tables]
            
            if missing_tables:
                self.log_test("Database Connection", "FAIL", f"Missing tables: {missing_tables}")
                return False
            
            # Check table data
            cursor.execute("SELECT COUNT(*) FROM users")
            user_count = cursor.fetchone()[0]
            
            cursor.execute("SELECT COUNT(*) FROM incidents")
            incident_count = cursor.fetchone()[0]
            
            conn.close()
            
            self.log_test("Database Connection", "PASS", 
                         f"Database OK - {user_count} users, {incident_count} incidents",
                         details=f"Tables: {tables}")
            return True
            
        except Exception as e:
            self.log_test("Database Connection", "FAIL", f"Database error: {str(e)}")
            return False
    
    def test_user_registration(self):
        """Test user registration API"""
        try:
            test_user = {
                "username": f"test_user_{int(time.time())}",
                "email": f"test_{int(time.time())}@example.com",
                "password": "testpassword123",
                "first_name": "Test",
                "last_name": "User",
                "phone": "1234567890",
                "location": "Test Location"
            }
            
            response = requests.post(
                f"{BACKEND_URL}/api/auth/register",
                json=test_user,
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code == 200:
                data = response.json()
                self.test_user_id = data.get('id')
                self.log_test("User Registration", "PASS", 
                             f"User created with ID: {self.test_user_id}")
                return True, test_user
            else:
                error_msg = response.json().get('detail', 'Unknown error')
                self.log_test("User Registration", "FAIL", 
                             f"Registration failed: {error_msg}")
                return False, None
                
        except Exception as e:
            self.log_test("User Registration", "FAIL", f"Registration error: {str(e)}")
            return False, None
    
    def test_user_login(self, username, password):
        """Test user login API"""
        try:
            login_data = {
                "username": username,
                "password": password
            }
            
            response = requests.post(
                f"{BACKEND_URL}/api/auth/login",
                data=login_data
            )
            
            if response.status_code == 200:
                data = response.json()
                self.token = data.get('access_token')
                user_info = data.get('user', {})
                
                self.log_test("User Login", "PASS", 
                             f"Login successful for {user_info.get('username')}")
                return True
            else:
                error_msg = response.json().get('detail', 'Unknown error')
                self.log_test("User Login", "FAIL", f"Login failed: {error_msg}")
                return False
                
        except Exception as e:
            self.log_test("User Login", "FAIL", f"Login error: {str(e)}")
            return False
    
    def test_incident_creation(self):
        """Test incident/report creation API"""
        if not self.token:
            self.log_test("Incident Creation", "SKIP", "No authentication token available")
            return False
        
        try:
            incident_data = {
                "hazard_type": "high-waves",
                "location": "Test Beach, Mumbai",
                "latitude": 19.0760,
                "longitude": 72.8777,
                "description": "Test incident for API validation",
                "urgency": "medium",
                "contact_info": "test@example.com"
            }
            
            headers = {
                "Authorization": f"Bearer {self.token}",
                "Content-Type": "application/json"
            }
            
            response = requests.post(
                f"{BACKEND_URL}/api/incidents/",
                json=incident_data,
                headers=headers
            )
            
            if response.status_code == 200:
                data = response.json()
                reference_id = data.get('reference_id')
                
                self.log_test("Incident Creation", "PASS", 
                             f"Incident created with reference: {reference_id}")
                return True
            else:
                error_msg = response.json().get('detail', 'Unknown error')
                self.log_test("Incident Creation", "FAIL", 
                             f"Creation failed: {error_msg}")
                return False
                
        except Exception as e:
            self.log_test("Incident Creation", "FAIL", f"Creation error: {str(e)}")
            return False
    
    def test_get_user_reports(self):
        """Test getting user's reports"""
        if not self.token:
            self.log_test("Get User Reports", "SKIP", "No authentication token available")
            return False
        
        try:
            headers = {
                "Authorization": f"Bearer {self.token}",
                "Content-Type": "application/json"
            }
            
            response = requests.get(
                f"{BACKEND_URL}/api/incidents/?page=1&size=10",
                headers=headers
            )
            
            if response.status_code == 200:
                data = response.json()
                incidents = data.get('incidents', [])
                total = data.get('total', 0)
                
                self.log_test("Get User Reports", "PASS", 
                             f"Retrieved {len(incidents)} incidents (total: {total})")
                return True
            else:
                error_msg = response.json().get('detail', 'Unknown error')
                self.log_test("Get User Reports", "FAIL", 
                             f"Retrieval failed: {error_msg}")
                return False
                
        except Exception as e:
            self.log_test("Get User Reports", "FAIL", f"Retrieval error: {str(e)}")
            return False
    
    def test_unauthorized_access(self):
        """Test that endpoints properly require authentication"""
        try:
            response = requests.get(f"{BACKEND_URL}/api/incidents/")
            
            if response.status_code == 401:
                self.log_test("Unauthorized Access", "PASS", 
                             "Endpoints properly require authentication")
                return True
            else:
                self.log_test("Unauthorized Access", "FAIL", 
                             f"Expected 401, got {response.status_code}")
                return False
                
        except Exception as e:
            self.log_test("Unauthorized Access", "FAIL", f"Test error: {str(e)}")
            return False
    
    def run_all_tests(self):
        """Run all test scenarios"""
        print("🌊 Ocean Hazard - Comprehensive System Test")
        print("=" * 50)
        
        # Test 1: Backend Health
        if not self.test_backend_health():
            print("\n❌ Backend server is not running. Please start the server first.")
            return False
        
        # Test 2: Database Connection
        self.test_database_connection()
        
        # Test 3: Unauthorized Access
        self.test_unauthorized_access()
        
        # Test 4: User Registration
        registration_success, test_user = self.test_user_registration()
        
        # Test 5: User Login
        if registration_success and test_user:
            login_success = self.test_user_login(test_user['username'], test_user['password'])
            
            # Test 6: Incident Creation
            if login_success:
                self.test_incident_creation()
                
                # Test 7: Get User Reports
                self.test_get_user_reports()
        
        # Print Summary
        self.print_summary()
        
        return True
    
    def print_summary(self):
        """Print test summary"""
        print("\n" + "=" * 50)
        print("📊 TEST SUMMARY")
        print("=" * 50)
        
        total_tests = len(self.test_results)
        passed_tests = len([t for t in self.test_results if t['status'] == 'PASS'])
        failed_tests = len([t for t in self.test_results if t['status'] == 'FAIL'])
        skipped_tests = len([t for t in self.test_results if t['status'] == 'SKIP'])
        
        print(f"Total Tests: {total_tests}")
        print(f"✅ Passed: {passed_tests}")
        print(f"❌ Failed: {failed_tests}")
        print(f"⚠️  Skipped: {skipped_tests}")
        
        success_rate = (passed_tests / (total_tests - skipped_tests)) * 100 if (total_tests - skipped_tests) > 0 else 0
        print(f"\nSuccess Rate: {success_rate:.1f}%")
        
        if failed_tests > 0:
            print("\n❌ FAILED TESTS:")
            for test in self.test_results:
                if test['status'] == 'FAIL':
                    print(f"  • {test['test']}: {test['message']}")
        
        # Save results to file
        results_file = f"py_test/tests/test_results_{int(time.time())}.json"
        os.makedirs(os.path.dirname(results_file), exist_ok=True)
        
        with open(results_file, 'w') as f:
            json.dump(self.test_results, f, indent=2)
        
        print(f"\n📄 Full results saved to: {results_file}")

def main():
    """Main test execution"""
    tester = OceanHazardTester()
    
    # Check if we're in the right directory
    if not os.path.exists("backend"):
        print("❌ Please run this script from the Ocean-Hazard root directory")
        sys.exit(1)
    
    try:
        tester.run_all_tests()
        
        print("\n🎯 RECOMMENDATIONS:")
        print("1. Ensure both frontend and backend servers are running")
        print("2. Frontend: python start_frontend.py")
        print("3. Backend: python start_ocean_hazard.py")
        print("4. Test registration/login flow in browser")
        print("5. Check my-reports.html page functionality")
        
    except KeyboardInterrupt:
        print("\n\n⚠️ Tests interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()