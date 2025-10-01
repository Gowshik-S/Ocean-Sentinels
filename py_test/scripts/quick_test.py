import requests
import sqlite3
import json
from datetime import datetime

print('🔍 Testing SQLite Registration & Reports')
print('=' * 50)

# Check database status first
print('📊 Current Database Status:')
conn = sqlite3.connect('backend/database/ocean_hazard.db')
cursor = conn.cursor()
cursor.execute('SELECT COUNT(*) FROM users')
users_before = cursor.fetchone()[0]
print(f'   Users in database: {users_before}')
conn.close()

# Test registration
timestamp = datetime.now().strftime('%H%M%S')
test_user = {
    'username': f'testuser_{timestamp}',
    'email': f'testuser_{timestamp}@example.com',
    'password': 'testpass123',
    'first_name': 'Test',
    'last_name': 'User'
}

print(f'🔄 Testing registration for: {test_user["username"]}')

try:
    response = requests.post(
        'http://127.0.0.1:8004/api/auth/register',
        json=test_user,
        timeout=5
    )
    
    if response.status_code == 200:
        result = response.json()
        print(f'✅ Registration successful: {result["user"]["username"]}')
        
        # Check database after
        conn = sqlite3.connect('backend/database/ocean_hazard.db')
        cursor = conn.cursor()
        cursor.execute('SELECT COUNT(*) FROM users')
        users_after = cursor.fetchone()[0]
        print(f'   Users after registration: {users_after}')
        
        if users_after > users_before:
            print('🎉 SUCCESS: User saved to SQLite database!')
        else:
            print('❌ FAILED: User not saved to database')
        
        conn.close()
    else:
        print(f'❌ Registration failed: {response.status_code} - {response.text}')

    # Test reports
    print(f'📋 Testing reports access...')
    reports_response = requests.get('http://127.0.0.1:8004/api/my-reports/', timeout=5)
    
    if reports_response.status_code == 200:
        reports_result = reports_response.json()
        print(f'✅ Reports access successful: {reports_result["total"]} reports')
        if "source" in reports_result:
            print(f'   Source: {reports_result["source"]}')
    else:
        print(f'❌ Reports failed: {reports_response.status_code}')

except Exception as e:
    print(f'❌ Test error: {e}')