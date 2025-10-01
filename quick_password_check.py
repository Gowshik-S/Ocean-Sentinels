#!/usr/bin/env python3
import sqlite3
import bcrypt

# Connect to database
conn = sqlite3.connect('backend/database/ocean_hazard.db')
cursor = conn.cursor()

# Get rescue team users  
cursor.execute('SELECT username, hashed_password FROM users WHERE role = ?', ('RESCUE_TEAM',))
rescue_users = cursor.fetchall()

print('🔍 Checking rescue team passwords...')
for username, hashed_password in rescue_users:
    print(f'User: {username}')
    print(f'Hash: {hashed_password[:50]}...')
    
    # Test password
    try:
        if bcrypt.checkpw(b'Rescue123!', hashed_password.encode('utf-8')):
            print(f'✅ Password correct for {username}')
        else:
            print(f'❌ Password WRONG for {username}')
    except Exception as e:
        print(f'❌ Error: {e}')
    print()

conn.close()