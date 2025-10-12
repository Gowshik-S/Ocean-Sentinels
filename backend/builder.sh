#!/bin/bash

# Render build script for Ocean Hazard Backend

echo "🚀 Starting build process..."

# Install dependencies
pip install -r requirements.txt

echo "✅ Dependencies installed successfully"

# Run database migrations if needed
# python -m alembic upgrade head

echo "🎉 Build completed!"