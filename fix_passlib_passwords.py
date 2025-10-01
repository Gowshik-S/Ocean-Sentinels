#!/usr/bin/env python3
"""
Fix bcrypt compatibility issue for rescue team passwords
"""

import sqlite3
from passlib.context import CryptContext

# Use the same password context as FastAPI backend
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def fix_rescue_passwords_with_passlib():
    """Fix rescue team passwords using passlib (same as FastAPI)"""
    
    # Connect to database
    conn = sqlite3.connect('backend/database/ocean_hazard.db')
    cursor = conn.cursor()
    
    # Get admin password hash for reference
    cursor.execute('SELECT username, hashed_password FROM users WHERE role = ?', ('ADMIN',))
    admin_data = cursor.fetchone()
    if admin_data:
        print(f"📋 Admin hash example: {admin_data[1][:50]}...")
    
    # Get rescue team users
    cursor.execute('SELECT username FROM users WHERE role = ?', ('RESCUE_TEAM',))
    rescue_users = [row[0] for row in cursor.fetchall()]
    
    print(f"🔧 Fixing passwords for {len(rescue_users)} rescue team users using passlib...")
    
    # Generate correct passlib hash (same method as FastAPI)
    password = "Rescue123!"
    hashed_password = pwd_context.hash(password)
    
    print(f"🔐 New passlib hash: {hashed_password[:50]}...")
    
    # Update all rescue team passwords
    for username in rescue_users:
        cursor.execute("""
            UPDATE users 
            SET hashed_password = ?, updated_at = CURRENT_TIMESTAMP
            WHERE username = ? AND role = 'RESCUE_TEAM'
        """, (hashed_password, username))
        
        print(f"   ✅ Updated password for {username}")
    
    # Commit changes
    conn.commit()
    
    # Verify the fix
    print("\n🧪 Verifying passwords with passlib...")
    cursor.execute('SELECT username, hashed_password FROM users WHERE role = ?', ('RESCUE_TEAM',))
    rescue_users_data = cursor.fetchall()
    
    for username, hash_val in rescue_users_data:
        try:
            if pwd_context.verify(password, hash_val):
                print(f"   ✅ {username} password verified with passlib")
            else:
                print(f"   ❌ {username} password verification failed")
        except Exception as e:
            print(f"   ❌ {username} error: {e}")
    
    conn.close()
    
    print(f"\n🎉 Rescue team passwords fixed with passlib compatibility!")
    print(f"Password: {password}")
    print(f"Users: {', '.join([row[0] for row in rescue_users_data])}")

if __name__ == "__main__":
    fix_rescue_passwords_with_passlib()