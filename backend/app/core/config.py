"""
Configuration settings for Ocean Hazard API
"""

import os
from typing import List

class Settings:
    """Application settings loaded from environment variables"""

    def __init__(self):
        # Database
        self.DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./database/ocean_hazard.db")
        self.DATABASE_URL_LOCAL: str = os.getenv("DATABASE_URL_LOCAL", "sqlite+aiosqlite:///./database/ocean_hazard.db")

        # JWT
        self.SECRET_KEY: str = os.getenv("SECRET_KEY", "")
        if not self.SECRET_KEY:
            import secrets
            self.SECRET_KEY = secrets.token_hex(32)
            import warnings
            warnings.warn("SECRET_KEY not set! Using random key — sessions won't persist across restarts. Set SECRET_KEY env var in production.")
        self.ALGORITHM: str = os.getenv("ALGORITHM", "HS256")
        self.ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))

        # AWS
        self.AWS_ACCESS_KEY_ID: str = os.getenv("AWS_ACCESS_KEY_ID", "")
        self.AWS_SECRET_ACCESS_KEY: str = os.getenv("AWS_SECRET_ACCESS_KEY", "")
        self.AWS_REGION: str = os.getenv("AWS_REGION", "us-east-1")
        self.AWS_S3_BUCKET: str = os.getenv("AWS_S3_BUCKET", "ocean-hazard-storage")

        # Redis
        self.REDIS_URL: str = os.getenv("REDIS_URL", "redis://localhost:6379")
        self.REDIS_URL_CLOUD: str = os.getenv("REDIS_URL_CLOUD", "redis://your-redis-endpoint.amazonaws.com:6379")

        # Application
        self.DEBUG: bool = os.getenv("DEBUG", "True").lower() == "true"
        self.HOST: str = os.getenv("HOST", "0.0.0.0")
        self.PORT: int = int(os.getenv("PORT", "8000"))
        self.WEBSOCKET_PORT: int = int(os.getenv("WEBSOCKET_PORT", "8000"))  # Use same port as HTTP server
        self.CORS_ORIGINS: List[str] = [
            "http://localhost:8080",
            "http://127.0.0.1:8080",
            "http://localhost:5500",
            "http://127.0.0.1:5500",
            "http://localhost:3000",
            "http://127.0.0.1:3000",
            "*"
        ]

        # Email
        self.SMTP_HOST: str = os.getenv("SMTP_HOST", "smtp.gmail.com")
        self.SMTP_PORT: int = int(os.getenv("SMTP_PORT", "587"))
        self.SMTP_USERNAME: str = os.getenv("SMTP_USERNAME", "")
        self.SMTP_PASSWORD: str = os.getenv("SMTP_PASSWORD", "")

        # Mapbox
        self.MAPBOX_TOKEN: str = os.getenv("MAPBOX_TOKEN", "")
        self.MAPBOX_ACCESS_TOKEN: str = os.getenv("MAPBOX_ACCESS_TOKEN", "")

        # Analytics
        self.ENABLE_ANALYTICS: bool = os.getenv("ENABLE_ANALYTICS", "True").lower() == "true"

# Create settings instance
settings = Settings()



