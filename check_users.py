#!/usr/bin/env python3
"""Check users in database"""

import sqlite3

# Connect to database
conn = sqlite3.connect('backend/database/ocean_hazard.db')
cursor = conn.cursor()

# Get all rescue team users
cursor.execute('SELECT username, email, role, first_name, last_name, is_active FROM users WHERE username LIKE "rescue_%"')
rescue_users = cursor.fetchall()

print("🔍 RESCUE TEAMS IN DATABASE:")
print("-" * 60)
for user in rescue_users:
    username, email, role, first_name, last_name, is_active = user
    status = "ACTIVE" if is_active else "INACTIVE"
    print(f"   {username:<20} | {role:<12} | {first_name} {last_name} | {status}")

# Get admin user
cursor.execute('SELECT username, email, role, first_name, last_name, is_active FROM users WHERE username = "oceanadmin"')
admin_user = cursor.fetchone()

print("\n🔑 ADMIN USER:")
print("-" * 60)
if admin_user:
    username, email, role, first_name, last_name, is_active = admin_user
    status = "ACTIVE" if is_active else "INACTIVE"
    print(f"   {username:<20} | {role:<12} | {first_name} {last_name} | {status}")
else:
    print("   Admin user not found!")

conn.close()