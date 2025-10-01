#!/usr/bin/env python3
"""
Local PostgreSQL Database Setup for Ocean Hazard
This script helps you set up a local PostgreSQL database
"""

import subprocess
import sys
import os
import asyncio
from pathlib import Path

def check_postgresql_installed():
    """Check if PostgreSQL is installed"""
    try:
        result = subprocess.run(['psql', '--version'], capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ PostgreSQL found: {result.stdout.strip()}")
            return True
        else:
            print("❌ PostgreSQL not found")
            return False
    except FileNotFoundError:
        print("❌ PostgreSQL not found")
        return False

def install_postgresql_windows():
    """Install PostgreSQL on Windows"""
    print("📦 Installing PostgreSQL on Windows...")
    print("\n🔧 Manual Installation Steps:")
    print("1. Download PostgreSQL from: https://www.postgresql.org/download/windows/")
    print("2. Run the installer")
    print("3. Remember the password you set for 'postgres' user")
    print("4. Make sure to add PostgreSQL to PATH during installation")
    print("\n💡 Alternative: Use Chocolatey (if installed):")
    print("   choco install postgresql")
    
    input("\nPress Enter after installing PostgreSQL...")

def create_local_database():
    """Create local database and user"""
    print("\n🗄️ Creating local database...")
    
    # Database configuration
    db_name = "ocean_hazard_db"
    db_user = "ocean_user"
    db_password = "ocean_password"
    
    try:
        # Create database
        subprocess.run([
            'psql', '-U', 'postgres', '-c', 
            f'CREATE DATABASE {db_name};'
        ], check=True)
        print(f"✅ Database '{db_name}' created")
        
        # Create user
        subprocess.run([
            'psql', '-U', 'postgres', '-c', 
            f"CREATE USER {db_user} WITH PASSWORD '{db_password}';"
        ], check=True)
        print(f"✅ User '{db_user}' created")
        
        # Grant privileges
        subprocess.run([
            'psql', '-U', 'postgres', '-c', 
            f'GRANT ALL PRIVILEGES ON DATABASE {db_name} TO {db_user};'
        ], check=True)
        print(f"✅ Privileges granted to '{db_user}'")
        
        return db_name, db_user, db_password
        
    except subprocess.CalledProcessError as e:
        print(f"❌ Error creating database: {e}")
        return None, None, None

def update_env_file(db_name, db_user, db_password):
    """Update environment file with local database settings"""
    env_file = "backend/env.local"
    
    # Local database URL
    local_db_url = f"postgresql+asyncpg://{db_user}:{db_password}@localhost:5432/{db_name}"
    
    # Read current env file
    if os.path.exists(env_file):
        with open(env_file, 'r') as f:
            content = f.read()
    else:
        content = ""
    
    # Update DATABASE_URL to use local database
    if "DATABASE_URL=" in content:
        lines = content.split('\n')
        for i, line in enumerate(lines):
            if line.startswith("DATABASE_URL="):
                lines[i] = f"DATABASE_URL={local_db_url}"
                break
        content = '\n'.join(lines)
    else:
        content += f"\nDATABASE_URL={local_db_url}\n"
    
    # Write updated content
    with open(env_file, 'w') as f:
        f.write(content)
    
    print(f"✅ Updated {env_file} with local database settings")
    print(f"📝 Database URL: {local_db_url}")

def test_local_connection():
    """Test local database connection"""
    print("\n🧪 Testing local database connection...")
    
    try:
        # Test connection using psql
        result = subprocess.run([
            'psql', '-U', 'ocean_user', '-d', 'ocean_hazard_db', '-c', 'SELECT 1;'
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            print("✅ Local database connection successful!")
            return True
        else:
            print(f"❌ Local database connection failed: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"❌ Error testing connection: {e}")
        return False

def main():
    """Main setup function"""
    print("🌊 Ocean Hazard - Local Database Setup")
    print("=" * 50)
    
    # Check if PostgreSQL is installed
    if not check_postgresql_installed():
        print("\n📦 PostgreSQL not found. Installing...")
        install_postgresql_windows()
        
        # Check again after installation
        if not check_postgresql_installed():
            print("❌ PostgreSQL installation failed. Please install manually.")
            return
    
    # Create database
    print("\n🗄️ Setting up local database...")
    db_name, db_user, db_password = create_local_database()
    
    if db_name and db_user and db_password:
        # Update environment file
        update_env_file(db_name, db_user, db_password)
        
        # Test connection
        if test_local_connection():
            print("\n🎉 Local database setup complete!")
            print("\n📋 Next steps:")
            print("1. Run: python test_db_connection.py")
            print("2. Start your application with: python start_server.py")
        else:
            print("\n❌ Database setup incomplete. Please check your PostgreSQL installation.")
    else:
        print("\n❌ Failed to create local database")

if __name__ == "__main__":
    main()


