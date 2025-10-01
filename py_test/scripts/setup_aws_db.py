#!/usr/bin/env python3
"""
AWS RDS Database Setup Script for Ocean Hazard
This script helps you create and configure your AWS RDS PostgreSQL database
"""

import boto3
import json
from botocore.exceptions import ClientError

def create_rds_instance():
    """Create RDS PostgreSQL instance"""
    
    # AWS Configuration
    region = input("Enter your AWS region (e.g., us-east-1): ").strip()
    access_key = input("Enter your AWS Access Key ID: ").strip()
    secret_key = input("Enter your AWS Secret Access Key: ").strip()
    
    # Database Configuration
    db_instance_id = "ocean-hazard-db"
    db_name = "ocean_hazard_db"
    db_username = input("Enter database username: ").strip()
    db_password = input("Enter database password: ").strip()
    
    try:
        # Create RDS client
        rds_client = boto3.client(
            'rds',
            region_name=region,
            aws_access_key_id=access_key,
            aws_secret_access_key=secret_key
        )
        
        print("🚀 Creating RDS PostgreSQL instance...")
        
        # Create RDS instance
        response = rds_client.create_db_instance(
            DBInstanceIdentifier=db_instance_id,
            DBInstanceClass='db.t3.micro',  # Free tier eligible
            Engine='postgres',
            EngineVersion='15.4',
            MasterUsername=db_username,
            MasterUserPassword=db_password,
            DBName=db_name,
            AllocatedStorage=20,
            StorageType='gp2',
            VpcSecurityGroupIds=[],  # You'll need to configure security groups
            DBSubnetGroupName='default',  # You may need to create a subnet group
            BackupRetentionPeriod=7,
            MultiAZ=False,
            PubliclyAccessible=True,  # For development only
            StorageEncrypted=False,
            DeletionProtection=False,
            Tags=[
                {
                    'Key': 'Project',
                    'Value': 'Ocean-Hazard'
                },
                {
                    'Key': 'Environment',
                    'Value': 'Development'
                }
            ]
        )
        
        print("✅ RDS instance creation initiated!")
        print(f"Instance ID: {response['DBInstance']['DBInstanceIdentifier']}")
        print("⏳ This may take 10-15 minutes to complete...")
        
        # Save configuration
        config = {
            "region": region,
            "access_key": access_key,
            "secret_key": secret_key,
            "db_instance_id": db_instance_id,
            "db_name": db_name,
            "db_username": db_username,
            "db_password": db_password
        }
        
        with open("aws_db_config.json", "w") as f:
            json.dump(config, f, indent=2)
        
        print("📝 Configuration saved to aws_db_config.json")
        
    except ClientError as e:
        print(f"❌ Error creating RDS instance: {e}")
    except Exception as e:
        print(f"❌ Unexpected error: {e}")

def get_rds_endpoint():
    """Get RDS endpoint after creation"""
    try:
        with open("aws_db_config.json", "r") as f:
            config = json.load(f)
        
        rds_client = boto3.client(
            'rds',
            region_name=config["region"],
            aws_access_key_id=config["access_key"],
            aws_secret_access_key=config["secret_key"]
        )
        
        response = rds_client.describe_db_instances(
            DBInstanceIdentifier=config["db_instance_id"]
        )
        
        db_instance = response['DBInstances'][0]
        endpoint = db_instance['Endpoint']['Address']
        port = db_instance['Endpoint']['Port']
        
        print(f"🌐 Database Endpoint: {endpoint}")
        print(f"🔌 Port: {port}")
        print(f"📊 Status: {db_instance['DBInstanceStatus']}")
        
        return endpoint, port
        
    except Exception as e:
        print(f"❌ Error getting RDS endpoint: {e}")
        return None, None

def update_env_file():
    """Update environment file with database credentials"""
    try:
        with open("aws_db_config.json", "r") as f:
            config = json.load(f)
        
        endpoint, port = get_rds_endpoint()
        
        if endpoint:
            # Update env.local file
            database_url = f"postgresql+asyncpg://{config['db_username']}:{config['db_password']}@{endpoint}:{port}/{config['db_name']}"
            
            print(f"\n📝 Update your backend/env.local file with:")
            print(f"DATABASE_URL={database_url}")
            print(f"DB_HOST={endpoint}")
            print(f"DB_PORT={port}")
            print(f"DB_NAME={config['db_name']}")
            print(f"DB_USER={config['db_username']}")
            print(f"DB_PASSWORD={config['db_password']}")
            
    except Exception as e:
        print(f"❌ Error updating environment file: {e}")

if __name__ == "__main__":
    print("🌊 Ocean Hazard - AWS RDS Database Setup")
    print("=" * 50)
    
    choice = input("Choose an option:\n1. Create new RDS instance\n2. Get existing RDS endpoint\n3. Update environment file\nEnter choice (1-3): ").strip()
    
    if choice == "1":
        create_rds_instance()
    elif choice == "2":
        get_rds_endpoint()
    elif choice == "3":
        update_env_file()
    else:
        print("❌ Invalid choice")


