"""
Configuration settings for Ocean Hazard API
"""

from pydantic_settings import BaseSettings
from typing import List
import os

class Settings(BaseSettings):
    """Application settings"""
    
    # Database
    DATABASE_URL: str = "sqlite+aiosqlite:///./database/ocean_hazard.db"
    DATABASE_URL_LOCAL: str = "sqlite+aiosqlite:///./database/ocean_hazard.db"
    
    # JWT
    SECRET_KEY: str = "your-super-secret-jwt-key-here-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # AWS
    AWS_ACCESS_KEY_ID: str = ""
    AWS_SECRET_ACCESS_KEY: str = ""
    AWS_REGION: str = "us-east-1"
    AWS_S3_BUCKET: str = "ocean-hazard-storage"
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379"
    REDIS_URL_CLOUD: str = "redis://your-redis-endpoint.amazonaws.com:6379"
    
    # Application
    DEBUG: bool = True
    HOST: str = "127.0.0.1"
    PORT: int = 9000
    WEBSOCKET_PORT: int = 9000  # Use same port as HTTP server
    CORS_ORIGINS: List[str] = [
        "http://localhost:8080",
        "http://127.0.0.1:8080",
        "http://localhost:5500",
        "http://127.0.0.1:5500",
        "http://localhost:3000",
        "http://127.0.0.1:3000"
    ]
    
    # Email
    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_USERNAME: str = ""
    SMTP_PASSWORD: str = ""
    
    # Mapbox
    MAPBOX_ACCESS_TOKEN: str = ""
    
    class Config:
        env_file = "env.local"
        case_sensitive = True
        extra = "ignore"  # Ignore extra fields from env file

# Create settings instance
settings = Settings()



