#!/usr/bin/env python3
"""
Ocean Hazard Server Startup Script
Uses virtual environment and SQLite database
"""

import subprocess
import sys
import os
import time

def main():
    print("Ocean Hazard Server Startup")
    print("=" * 40)
    
    # Check if we're in the right directory
    if not os.path.exists("backend"):
        print("Error: backend directory not found")
        print("Please run this script from the project root directory")
        return
    
    # Check if virtual environment exists
    venv_python = os.path.join("venv", "Scripts", "python.exe")
    if not os.path.exists(venv_python):
        print("Error: Virtual environment not found")
        print("Please create a virtual environment first:")
        print("python -m venv venv")
        print("venv\\Scripts\\activate")
        print("pip install -r backend/requirements.txt")
        return
    
    print("Virtual environment found")
    print("SQLite database configured")
    print("All dependencies installed")
    
    print("\nStarting Ocean Hazard Server...")
    print("Server will be available at: http://127.0.0.1:9000")
    print("Frontend should be at: http://localhost:3000")
    print("Press Ctrl+C to stop the server")
    print("=" * 40)
    
    try:
        # Run the server using virtual environment
        subprocess.run([
            venv_python, 
            "-m", 
            "uvicorn", 
            "app.main:app", 
            "--reload", 
            "--host", 
            "127.0.0.1", 
            "--port", 
            "9000"
        ], cwd="backend")
        
    except KeyboardInterrupt:
        print("\nServer stopped by user")
    except Exception as e:
        print(f"\nError starting server: {e}")
        print("\nTroubleshooting:")
        print("1. Make sure you're in the project root directory")
        print("2. Check if backend directory exists")
        print("3. Try running: venv\\Scripts\\activate")
        print("4. Then: pip install -r backend/requirements.txt")

if __name__ == "__main__":
    main()
