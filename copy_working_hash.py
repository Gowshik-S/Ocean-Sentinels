#!/usr/bin/env python3
"""
Copy Working Admin Hash to Rescue Teams (Temporary Fix)
"""

import sqlite3

def copy_working_admin_hash():
    """Copy the exact working admin hash to rescue teams"""
    
    # Connect to database
    conn = sqlite3.connect('backend/database/ocean_hazard.db')
    cursor = conn.cursor()
    
    # Get the working admin hash
    cursor.execute('SELECT username, hashed_password FROM users WHERE username = ?', ('oceanadmin',))
    admin_result = cursor.fetchone()
    
    if not admin_result:
        print("❌ Admin user not found")
        return False
        
    admin_username, admin_hash = admin_result
    print(f"✅ Found working admin hash for: {admin_username}")
    print(f"📋 Hash: {admin_hash[:50]}...")
    
    # Get rescue team users
    cursor.execute('SELECT username FROM users WHERE role = ?', ('RESCUE_TEAM',))
    rescue_users = [row[0] for row in cursor.fetchall()]
    
    print(f"\n🚑 Updating {len(rescue_users)} rescue team users...")
    
    # Copy admin hash to all rescue teams
    for username in rescue_users:
        cursor.execute("""
            UPDATE users 
            SET hashed_password = ?, updated_at = CURRENT_TIMESTAMP
            WHERE username = ? AND role = 'RESCUE_TEAM'
        """, (admin_hash, username))
        
        print(f"   ✅ Updated {username} with working hash")
    
    conn.commit()
    conn.close()
    
    print(f"\n🎯 TEMPORARY RESCUE TEAM CREDENTIALS:")
    print(f"   ⚠️ All rescue teams now use ADMIN password temporarily")
    print(f"   Username: rescue_mumbai, rescue_chennai, rescue_kochi")
    print(f"   Password: Ocean@Admin2025")
    print(f"\n🧪 Test rescue login at: http://localhost:3000/pages/reports.html")
    print(f"   Try: rescue_mumbai / Ocean@Admin2025")
    
    return True

if __name__ == "__main__":
    print("🔧 Copying Working Admin Hash to Rescue Teams")
    print("=" * 60)
    copy_working_admin_hash()