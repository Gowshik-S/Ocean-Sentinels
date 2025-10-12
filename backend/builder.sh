#!/bin/bash

# Render build script for Ocean Hazard Backend

echo "🚀 Starting build process..."

# Set writable directories for Rust toolchain to avoid read-only file system errors
export RUSTUP_HOME=/tmp/rustup
export CARGO_HOME=/tmp/cargo

# Upgrade pip to the latest version
pip install --upgrade pip

# Install dependencies
pip install -r requirements.txt

echo "✅ Dependencies installed successfully"

# Run database migrations if needed
# python -m alembic upgrade head

echo "🎉 Build completed!"