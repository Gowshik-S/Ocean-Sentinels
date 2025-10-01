#!/usr/bin/env python3
import sqlite3
import bcrypt

def fix_rescue_passwords():
    """Fix rescue team passwords with proper bcrypt hashing"""
    
    # Connect to database
    conn = sqlite3.connect('backend/database/ocean_hazard.db')
    cursor = conn.cursor()
    
    # Get rescue team users
    cursor.execute('SELECT username FROM users WHERE role = ?', ('RESCUE_TEAM',))
    rescue_users = [row[0] for row in cursor.fetchall()]
    
    print(f"🔧 Fixing passwords for {len(rescue_users)} rescue team users...")
    
    # Generate correct bcrypt hash
    password = "Rescue123!"
    salt = bcrypt.gensalt()
    hashed_password = bcrypt.hashpw(password.encode('utf-8'), salt).decode('utf-8')
    
    print(f"🔐 New bcrypt hash: {hashed_password[:50]}...")
    
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
    print("\n🧪 Verifying passwords...")
    cursor.execute('SELECT username, hashed_password FROM users WHERE role = ?', ('RESCUE_TEAM',))
    rescue_users = cursor.fetchall()
    
    for username, hash_val in rescue_users:
        try:
            if bcrypt.checkpw(b'Rescue123!', hash_val.encode('utf-8')):
                print(f"   ✅ {username} password verified")
            else:
                print(f"   ❌ {username} password still wrong")
        except Exception as e:
            print(f"   ❌ {username} error: {e}")
    
    conn.close()
    
    print(f"\n🎉 Rescue team passwords fixed!")
    print(f"Password: {password}")
    print(f"Users: {', '.join([row[0] for row in rescue_users])}")

if __name__ == "__main__":
    fix_rescue_passwords()