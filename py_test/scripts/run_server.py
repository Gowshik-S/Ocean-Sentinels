#!/usr/bin/env python3
"""
Simple Ocean Hazard Server Runner
This script starts the server with proper error handling
"""

import subprocess
import sys
import os
import time

def main():
    print("🌊 Ocean Hazard Server Runner")
    print("=" * 40)
    
    # Check if we're in the right directory
    if not os.path.exists("backend"):
        print("❌ Error: backend directory not found")
        print("Please run this script from the project root directory")
        return
    
    # Check if virtual environment exists
    venv_path = os.path.join("venv", "Scripts", "python.exe")
    if os.path.exists(venv_path):
        python_cmd = venv_path
        print("✅ Using virtual environment")
    else:
        python_cmd = "python"
        print("⚠️  Using system Python (virtual environment not found)")
    
    # Start the server
    print("\n🚀 Starting server...")
    print("Server will be available at: http://127.0.0.1:8002")
    print("Press Ctrl+C to stop the server")
    print("=" * 40)
    
    try:
        # Run the server
        subprocess.run([
            python_cmd, 
            "-m", 
            "uvicorn", 
            "app.main:app", 
            "--reload", 
            "--host", 
            "127.0.0.1", 
            "--port", 
            "8002"
        ], cwd="backend")
        
    except KeyboardInterrupt:
        print("\n👋 Server stopped by user")
    except Exception as e:
        print(f"\n❌ Error starting server: {e}")
        print("\n🔧 Troubleshooting:")
        print("1. Make sure you're in the project root directory")
        print("2. Check if backend directory exists")
        print("3. Try running: pip install -r backend/requirements.txt")

if __name__ == "__main__":
    main()

