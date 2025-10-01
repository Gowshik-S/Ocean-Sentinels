#!/usr/bin/env python3
"""Fix user roles in database"""

import sqlite3

def fix_user_roles():
    """Update users with correct roles"""
    
    # Connect to database
    conn = sqlite3.connect('backend/database/ocean_hazard.db')
    cursor = conn.cursor()
    
    print("🔧 Fixing user roles...")
    
    # Update admin user
    cursor.execute("UPDATE users SET role = 'admin' WHERE username = 'oceanadmin'")
    print("✅ Updated oceanadmin to ADMIN role")
    
    # Update rescue team users
    rescue_users = ['rescue_mumbai', 'rescue_chennai', 'rescue_kochi', 'rescue_visakhapatnam']
    
    for username in rescue_users:
        cursor.execute("UPDATE users SET role = 'rescue_team' WHERE username = ?", (username,))
        print(f"✅ Updated {username} to RESCUE_TEAM role")
    
    # Commit changes
    conn.commit()
    
    # Verify changes
    print("\n🔍 Verifying role updates:")
    cursor.execute("SELECT username, role FROM users WHERE username IN ('oceanadmin', 'rescue_mumbai', 'rescue_chennai', 'rescue_kochi', 'rescue_visakhapatnam')")
    
    users = cursor.fetchall()
    for username, role in users:
        print(f"   {username:<20} -> {role}")
    
    conn.close()
    print("\n✅ Role updates complete!")

if __name__ == "__main__":
    fix_user_roles()