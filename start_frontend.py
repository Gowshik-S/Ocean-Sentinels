#!/usr/bin/env python3
"""
Ocean Hazard Frontend Server Starter
Starts the HTTP server for serving frontend files
"""

import http.server
import socketserver
import os
import sys

def start_frontend_server():
    """Start the frontend HTTP server"""
    PORT = 3000
    DIRECTORY = os.path.dirname(os.path.abspath(__file__))
    
    print("🌐 Starting Ocean Hazard Frontend Server...")
    print(f"📁 Serving files from: {DIRECTORY}")
    print(f"🚀 Server will be available at: http://localhost:{PORT}")
    print("📱 Access the app at: http://localhost:3000/pages/index.html")
    print("📊 My Reports page: http://localhost:3000/pages/my-reports.html")
    print("Press Ctrl+C to stop the server")
    print("=" * 60)
    
    os.chdir(DIRECTORY)
    
    with socketserver.TCPServer(("", PORT), http.server.SimpleHTTPRequestHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n👋 Frontend server stopped by user")
            sys.exit(0)

if __name__ == "__main__":
    start_frontend_server()