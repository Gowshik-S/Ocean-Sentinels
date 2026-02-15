#!/usr/bin/env python3
"""
Migration script: Add mesh_message_id column to incidents table.

Run this manually if the auto-migration in main.py doesn't execute
(e.g., database was created before the mesh feature was added).

Usage:
    cd backend
    python -m scripts.migrate_mesh_column
"""

import asyncio
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(__file__), "..", ".env"))

from sqlalchemy import text
from app.database import engine


async def migrate():
    print("Running migration: Add mesh_message_id to incidents table...")
    async with engine.begin() as conn:
        # Add column if it doesn't exist (PostgreSQL syntax)
        await conn.execute(text(
            "ALTER TABLE incidents ADD COLUMN IF NOT EXISTS mesh_message_id VARCHAR(128) UNIQUE"
        ))
        await conn.execute(text(
            "CREATE INDEX IF NOT EXISTS ix_incidents_mesh_message_id ON incidents (mesh_message_id)"
        ))
    print("Migration complete: mesh_message_id column added successfully.")


if __name__ == "__main__":
    asyncio.run(migrate())
