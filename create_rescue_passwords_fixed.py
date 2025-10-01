#!/usr/bin/env python3
"""
Create Rescue Team Passwords with Fixed bcrypt Version
"""

import sqlite3
from passlib.context import CryptContext

def create_rescue_passwords_fixed():
    """Create rescue team passwords with proper passlib context"""
    
    # Use the same password context as FastAPI
    pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
    
    # Connect to database
    conn = sqlite3.connect('backend/database/ocean_hazard.db')
    cursor = conn.cursor()
    
    # Get rescue team users
    cursor.execute('SELECT username FROM users WHERE role = ?', ('RESCUE_TEAM',))
    rescue_users = [row[0] for row in cursor.fetchall()]
    
    print(f"🔧 Creating rescue passwords for {len(rescue_users)} users with fixed bcrypt...")
    
    # Create proper password hash
    password = "Rescue123!"
    hashed_password = pwd_context.hash(password)
    
    print(f"🔐 New hash: {hashed_password[:50]}...")
    
    # Update all rescue team passwords
    for username in rescue_users:
        cursor.execute("""
            UPDATE users 
            SET hashed_password = ?, updated_at = CURRENT_TIMESTAMP
            WHERE username = ? AND role = 'RESCUE_TEAM'
        """, (hashed_password, username))
        
        print(f"   ✅ Updated {username}")
    
    conn.commit()
    
    # Verify the passwords work
    print(f"\n🧪 Verifying passwords...")
    for username in rescue_users:
        if pwd_context.verify(password, hashed_password):
            print(f"   ✅ {username} password verified")
        else:
            print(f"   ❌ {username} password failed")
    
    conn.close()
    
    print(f"\n🎉 Rescue team passwords created!")
    print(f"Password: {password}")
    print(f"Users: {', '.join(rescue_users)}")
    
    return True

if __name__ == "__main__":
    print("🔧 Creating Rescue Passwords with Fixed bcrypt")
    print("=" * 50)
    try:
        create_rescue_passwords_fixed()
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()