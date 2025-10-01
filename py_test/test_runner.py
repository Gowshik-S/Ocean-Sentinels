#!/usr/bin/env python3
"""
Ocean Hazard - Test Runner
Main script to run all tests and validation
"""

import os
import sys
import subprocess
import time

def run_command(command, description):
    """Run a command and capture output"""
    print(f"\n🔄 {description}...")
    print(f"   Command: {command}")
    
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0:
            print(f"✅ {description} completed successfully")
            if result.stdout.strip():
                print("   Output:", result.stdout.strip())
            return True
        else:
            print(f"❌ {description} failed")
            if result.stderr.strip():
                print("   Error:", result.stderr.strip())
            if result.stdout.strip():
                print("   Output:", result.stdout.strip())
            return False
            
    except subprocess.TimeoutExpired:
        print(f"⏰ {description} timed out")
        return False
    except Exception as e:
        print(f"❌ {description} error: {str(e)}")
        return False

def check_servers():
    """Check if servers are running"""
    print("\n🌐 Checking server status...")
    
    # Check backend
    backend_cmd = 'python -c "import requests; r = requests.get(\'http://127.0.0.1:9000/health\', timeout=5); print(f\'Backend: {r.status_code} - {r.json()}\')"'
    backend_ok = run_command(backend_cmd, "Backend health check")
    
    # Check frontend
    frontend_cmd = 'python -c "import requests; r = requests.get(\'http://localhost:3000/pages/index.html\', timeout=5); print(f\'Frontend: {r.status_code}\')"'
    frontend_ok = run_command(frontend_cmd, "Frontend health check")
    
    return backend_ok, frontend_ok

def run_database_validation():
    """Run database validation"""
    return run_command("python py_test/database_validator.py", "Database validation")

def run_comprehensive_test():
    """Run comprehensive system test"""
    return run_command("python py_test/comprehensive_test.py", "Comprehensive system test")

def run_quick_api_test():
    """Run quick API test"""
    test_script = """
import requests
import json

print("🧪 Quick API Test")
print("=" * 30)

# Test 1: Backend health
try:
    r = requests.get('http://127.0.0.1:9000/health', timeout=5)
    print(f"✅ Backend health: {r.status_code}")
except Exception as e:
    print(f"❌ Backend health: {e}")

# Test 2: Unauthorized access
try:
    r = requests.get('http://127.0.0.1:9000/api/incidents/')
    if r.status_code == 401:
        print("✅ Authentication required: 401")
    else:
        print(f"❌ Unexpected status: {r.status_code}")
except Exception as e:
    print(f"❌ Auth test error: {e}")

# Test 3: Registration endpoint
try:
    test_data = {
        "username": "quicktest",
        "email": "quicktest@example.com", 
        "password": "test123",
        "first_name": "Quick",
        "last_name": "Test",
        "phone": "1234567890",
        "location": "Test"
    }
    r = requests.post('http://127.0.0.1:9000/api/auth/register', json=test_data)
    if r.status_code in [200, 400]:  # 400 if user exists
        print(f"✅ Registration endpoint: {r.status_code}")
    else:
        print(f"❌ Registration error: {r.status_code}")
except Exception as e:
    print(f"❌ Registration test error: {e}")

print("\\n🎯 Quick test completed")
"""
    
    with open("py_test/quick_api_test.py", "w") as f:
        f.write(test_script)
    
    return run_command("python py_test/quick_api_test.py", "Quick API test")

def main():
    """Main test runner"""
    print("🌊 Ocean Hazard - Test Runner")
    print("=" * 40)
    
    # Check current directory
    if not os.path.exists("backend") or not os.path.exists("pages"):
        print("❌ Please run this script from the Ocean-Hazard root directory")
        print("   Current directory:", os.getcwd())
        return False
    
    # Ensure test directory exists
    os.makedirs("py_test/tests", exist_ok=True)
    
    print("📁 Test environment:")
    print(f"   Working directory: {os.getcwd()}")
    print(f"   Test directory: py_test/")
    
    # Check servers
    backend_ok, frontend_ok = check_servers()
    
    if not backend_ok:
        print("\n⚠️  Backend server not running!")
        print("   Start with: python start_ocean_hazard.py")
    
    if not frontend_ok:
        print("\n⚠️  Frontend server not running!")
        print("   Start with: python start_frontend.py")
    
    if not (backend_ok or frontend_ok):
        print("\n❌ No servers running. Please start servers first.")
        return False
    
    # Run tests
    print("\n🧪 Running test suite...")
    
    test_results = {}
    
    # Test 1: Database validation
    test_results['database'] = run_database_validation()
    
    # Test 2: Quick API test
    test_results['api'] = run_quick_api_test()
    
    # Test 3: Comprehensive test (if backend is running)
    if backend_ok:
        test_results['comprehensive'] = run_comprehensive_test()
    else:
        test_results['comprehensive'] = False
        print("⚠️  Skipping comprehensive test - backend not available")
    
    # Summary
    print("\n" + "=" * 40)
    print("📊 TEST SUMMARY")
    print("=" * 40)
    
    for test_name, result in test_results.items():
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} {test_name.title()} Test")
    
    total_tests = len(test_results)
    passed_tests = sum(test_results.values())
    
    print(f"\nOverall: {passed_tests}/{total_tests} tests passed")
    
    if passed_tests == total_tests:
        print("🎉 All tests passed!")
    else:
        print("⚠️  Some tests failed. Check output above for details.")
    
    # Recommendations
    print("\n🎯 NEXT STEPS:")
    if not backend_ok:
        print("1. Start backend: python start_ocean_hazard.py")
    if not frontend_ok:
        print("2. Start frontend: python start_frontend.py")
    
    print("3. Manual testing:")
    print("   - Open http://localhost:3000/pages/index.html")
    print("   - Test registration/login flow")
    print("   - Test report submission")
    print("   - Check my-reports page")
    
    print("4. Check test results in py_test/tests/ folder")
    
    return passed_tests == total_tests

if __name__ == "__main__":
    try:
        success = main()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️ Test runner interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error: {str(e)}")
        sys.exit(1)