#!/usr/bin/env python3
"""
Check and Fix Rescue Team Passwords
"""

import sqlite3
import bcrypt
import os

def check_rescue_passwords():
    """Check the rescue team password hashes"""
    
    db_path = "backend/database/ocean_hazard.db"
    
    if not os.path.exists(db_path):
        print(f"❌ Database not found at {db_path}")
        return False
    
    try:
        print("🔍 Checking rescue team passwords...")
        
        # Connect to database
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Get rescue team users
        cursor.execute("""
            SELECT username, email, hashed_password, role 
            FROM users 
            WHERE role = 'RESCUE_TEAM'
        """)
        
        rescue_users = cursor.fetchall()
        
        print(f"📋 Found {len(rescue_users)} rescue team users:")
        
        for username, email, hashed_password, role in rescue_users:
            print(f"   {username} ({email}) - Role: {role}")
            print(f"   Hash: {hashed_password[:50]}...")
            
            # Test the expected password
            expected_password = "Rescue123!"
            try:
                # Check if password matches
                if bcrypt.checkpw(expected_password.encode('utf-8'), hashed_password.encode('utf-8')):
                    print(f"   ✅ Password 'Rescue123!' is correct for {username}")
                else:
                    print(f"   ❌ Password 'Rescue123!' is WRONG for {username}")
                    print(f"   🔧 Need to fix password for {username}")
            except Exception as e:
                print(f"   ❌ Error checking password for {username}: {e}")
                print(f"   🔧 Need to rehash password for {username}")
        
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Error checking passwords: {e}")
        return False

def fix_rescue_passwords():
    """Fix rescue team passwords by rehashing them"""
    
    db_path = "backend/database/ocean_hazard.db"
    
    try:
        print("\n🔧 Fixing rescue team passwords...")
        
        # Connect to database
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Get rescue team users
        cursor.execute("""
            SELECT username FROM users WHERE role = 'RESCUE_TEAM'
        """)
        
        rescue_users = [row[0] for row in cursor.fetchall()]
        
        # Generate correct password hash
        correct_password = "Rescue123!"
        salt = bcrypt.gensalt()
        hashed_password = bcrypt.hashpw(correct_password.encode('utf-8'), salt).decode('utf-8')
        
        print(f"🔐 New password hash: {hashed_password[:50]}...")
        
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
        conn.close()
        
        print(f"\n🎉 Fixed passwords for {len(rescue_users)} rescue team users!")
        print(f"   Password: {correct_password}")
        print(f"   Users: {', '.join(rescue_users)}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error fixing passwords: {e}")
        return False

if __name__ == "__main__":
    print("🚑 Rescue Team Password Check & Fix")
    print("=" * 50)
    
    check_rescue_passwords()
    
    print("\n" + "=" * 50)
    response = input("Do you want to fix the rescue team passwords? (y/n): ")
    
    if response.lower() == 'y':
        if fix_rescue_passwords():
            print("\n✅ Password fix completed!")
            print("\n📋 Test these credentials:")
            print("   rescue_mumbai / Rescue123!")
            print("   rescue_chennai / Rescue123!")
            print("   rescue_kochi / Rescue123!")
        else:
            print("\n❌ Password fix failed!")
    else:
        print("\n👍 No changes made.")