import requests
import json
from datetime import datetime

# Test with a unique user to see the actual response structure
timestamp = datetime.now().strftime('%H%M%S%f')[:-3]
test_user = {
    'username': f'test_{timestamp}',
    'email': f'test_{timestamp}@example.com',
    'password': 'testpass123',
    'first_name': 'Test',
    'last_name': 'User'
}

print(f'Testing registration with: {test_user["username"]}')
try:
    response = requests.post('http://127.0.0.1:9000/api/auth/register', json=test_user)
    print(f'Status: {response.status_code}')
    if response.status_code == 200:
        data = response.json()
        print(f'Response structure:')
        print(json.dumps(data, indent=2))
    else:
        print(f'Error response: {response.text}')
except Exception as e:
    print(f'Network error: {e}')