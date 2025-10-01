#!/usr/bin/env python3
"""
Fix Database Enum Case Issue
The database has lowercase 'admin' but enum expects 'ADMIN'
"""

import sqlite3
import os

def fix_enum_case():
    """Fix the enum case mismatch in the database"""
    
    db_path = "backend/database/ocean_hazard.db"
    
    if not os.path.exists(db_path):
        print(f"❌ Database not found at {db_path}")
        return False
    
    try:
        print("🔧 Fixing enum case mismatch...")
        
        # Connect to database
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Check current roles
        cursor.execute("SELECT username, role FROM users")
        users = cursor.fetchall()
        
        print("📋 Current users and roles:")
        for username, role in users:
            print(f"   {username}: {role}")
        
        # Fix the enum case
        role_mapping = {
            'admin': 'ADMIN',
            'public': 'PUBLIC', 
            'authority': 'AUTHORITY',
            'rescue_team': 'RESCUE_TEAM'
        }
        
        print("\n🔄 Updating roles to match enum...")
        
        for old_role, new_role in role_mapping.items():
            cursor.execute(
                "UPDATE users SET role = ? WHERE LOWER(role) = ?",
                (new_role, old_role.lower())
            )
            
        # Commit changes
        conn.commit()
        
        # Verify the fix
        print("\n✅ Verification - Updated roles:")
        cursor.execute("SELECT username, role FROM users")
        users = cursor.fetchall()
        
        for username, role in users:
            print(f"   {username}: {role}")
            
        conn.close()
        
        print("\n🎉 Database enum case fixed successfully!")
        return True
        
    except Exception as e:
        print(f"❌ Error fixing database: {e}")
        return False

if __name__ == "__main__":
    fix_enum_case()