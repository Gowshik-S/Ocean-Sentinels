"""
AWS RDS PostgreSQL configuration for Ocean Hazard API
"""

import boto3
from sqlalchemy import create_engine
from sqlalchemy.ext.asyncio import create_async_engine
from app.core.config import settings
import os

def get_aws_rds_connection_string():
    """Get AWS RDS connection string with proper configuration"""
    
    # For production, use AWS RDS endpoint
    if os.getenv('ENVIRONMENT') == 'production':
        # AWS RDS configuration
        db_host = os.getenv('DB_HOST', 'your-rds-endpoint.amazonaws.com')
        db_port = os.getenv('DB_PORT', '5432')
        db_name = os.getenv('DB_NAME', 'ocean_hazard_db')
        db_user = os.getenv('DB_USER', 'postgres')
        db_password = os.getenv('DB_PASSWORD')
        
        # Construct connection string
        connection_string = f"postgresql+asyncpg://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"
        
        return connection_string
    else:
        # For development, use local database
        return settings.DATABASE_URL_LOCAL

def create_aws_engine():
    """Create async engine for AWS RDS"""
    connection_string = get_aws_rds_connection_string()
    
    engine = create_async_engine(
        connection_string,
        echo=settings.DEBUG,
        future=True,
        pool_size=10,
        max_overflow=20,
        pool_pre_ping=True,
        pool_recycle=3600
    )
    
    return engine

def get_aws_credentials():
    """Get AWS credentials from environment or IAM role"""
    try:
        # Try to get credentials from environment variables first
        access_key = os.getenv('AWS_ACCESS_KEY_ID')
        secret_key = os.getenv('AWS_SECRET_ACCESS_KEY')
        
        if access_key and secret_key:
            return {
                'aws_access_key_id': access_key,
                'aws_secret_access_key': secret_key,
                'region_name': settings.AWS_REGION
            }
        
        # If not found, use IAM role (for EC2/ECS deployment)
        return {
            'region_name': settings.AWS_REGION
        }
    except Exception as e:
        print(f"Error getting AWS credentials: {e}")
        return None

def create_s3_client():
    """Create S3 client for file storage"""
    credentials = get_aws_credentials()
    
    if credentials:
        return boto3.client('s3', **credentials)
    else:
        return boto3.client('s3', region_name=settings.AWS_REGION)

def create_redis_client():
    """Create Redis client for caching and real-time features"""
    import redis.asyncio as redis
    
    # For production, use AWS ElastiCache
    if os.getenv('ENVIRONMENT') == 'production':
        redis_url = settings.REDIS_URL_CLOUD
    else:
        redis_url = settings.REDIS_URL
    
    return redis.from_url(redis_url)

# AWS RDS specific configurations
AWS_RDS_CONFIG = {
    'engine': 'postgresql',
    'instance_class': 'db.t3.micro',  # For development
    'allocated_storage': 20,
    'max_allocated_storage': 100,
    'backup_retention_period': 7,
    'multi_az': False,  # Set to True for production
    'publicly_accessible': False,
    'storage_encrypted': True,
    'deletion_protection': True,  # Set to True for production
    'backup_window': '03:00-04:00',
    'maintenance_window': 'sun:04:00-sun:05:00'
}

# Database migration configuration
ALEMBIC_CONFIG = {
    'script_location': 'alembic',
    'version_locations': ['alembic/versions'],
    'file_template': '%(year)d%(month)02d%(day)02d_%(hour)02d%(minute)02d_%(rev)s_%(slug)s',
    'truncate_slug_length': 40,
    'revision_environment': False,
    'sqlalchemy_module_prefix': 'sqlalchemy.',
    'version_path_separator': 'os',
    'prepend_sys_path': '',
    'timezone': 'UTC'
}



