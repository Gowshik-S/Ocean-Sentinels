# 🌊 AWS RDS Database Setup Guide

## Step 1: Create RDS PostgreSQL Instance

### Via AWS Console:
1. **Login to AWS Console** → Go to RDS service
2. **Create Database** → Choose "PostgreSQL"
3. **Configuration:**
   - **Engine**: PostgreSQL 15.4
   - **Template**: Free tier (for development)
   - **DB Instance Identifier**: `ocean-hazard-db`
   - **Master Username**: `ocean_admin` (or your choice)
   - **Master Password**: Create a strong password
   - **Database Name**: `ocean_hazard_db`

4. **Instance Configuration:**
   - **DB Instance Class**: `db.t3.micro` (Free tier)
   - **Storage**: 20 GB (Free tier)
   - **Storage Type**: General Purpose SSD (gp2)

5. **Connectivity:**
   - **VPC**: Default VPC
   - **Subnet Group**: Default
   - **Public Access**: Yes (for development)
   - **VPC Security Groups**: Create new or use existing
   - **Database Port**: 5432

6. **Additional Configuration:**
   - **Backup Retention**: 7 days
   - **Monitoring**: Disable enhanced monitoring (to save costs)
   - **Deletion Protection**: Disable (for development)

## Step 2: Configure Security Group

1. **Go to EC2 Console** → Security Groups
2. **Create Security Group** for RDS:
   - **Name**: `ocean-hazard-rds-sg`
   - **Description**: Security group for Ocean Hazard RDS
   - **Inbound Rules**:
     - **Type**: PostgreSQL
     - **Port**: 5432
     - **Source**: Your IP address (0.0.0.0/0 for development)

## Step 3: Get Connection Details

After RDS instance is created (10-15 minutes):

1. **Go to RDS Console** → Databases
2. **Click on your database instance**
3. **Note down:**
   - **Endpoint**: `ocean-hazard-db.xxxxx.us-east-1.rds.amazonaws.com`
   - **Port**: 5432
   - **Database Name**: `ocean_hazard_db`
   - **Username**: Your master username
   - **Password**: Your master password

## Step 4: Update Environment Configuration

Update `backend/env.local` with your RDS details:

```bash
# AWS RDS Configuration
DATABASE_URL=postgresql+asyncpg://your_username:your_password@your-endpoint.amazonaws.com:5432/ocean_hazard_db
DB_HOST=your-endpoint.amazonaws.com
DB_PORT=5432
DB_NAME=ocean_hazard_db
DB_USER=your_username
DB_PASSWORD=your_password
```

## Step 5: Test Connection

Run the database connection test:

```bash
cd backend
python -c "
import asyncio
from app.database.database import engine
from sqlalchemy import text

async def test_connection():
    try:
        async with engine.begin() as conn:
            result = await conn.execute(text('SELECT 1'))
            print('✅ Database connection successful!')
            return True
    except Exception as e:
        print(f'❌ Database connection failed: {e}')
        return False

asyncio.run(test_connection())
"
```

## Step 6: Create Database Tables

After successful connection, create the database tables:

```bash
cd backend
python -c "
import asyncio
from app.database.database import engine, Base

async def create_tables():
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        print('✅ Database tables created successfully!')
    except Exception as e:
        print(f'❌ Error creating tables: {e}')

asyncio.run(create_tables())
"
```

## Cost Optimization

- **Free Tier**: Use `db.t3.micro` instance
- **Storage**: 20 GB free for 12 months
- **Backup**: 7 days retention (free)
- **Monitoring**: Disable enhanced monitoring
- **Multi-AZ**: Disable for development

## Security Best Practices

1. **Use VPC**: Don't use public access in production
2. **Security Groups**: Restrict access to specific IPs
3. **Encryption**: Enable encryption for production
4. **Backup**: Enable automated backups
5. **Monitoring**: Enable CloudWatch monitoring

## Troubleshooting

### Connection Issues:
- Check security group rules
- Verify endpoint and port
- Ensure database is in "Available" state
- Check username/password

### Performance Issues:
- Upgrade instance class if needed
- Enable performance insights
- Monitor CloudWatch metrics

## Next Steps

1. ✅ Create RDS instance
2. ✅ Configure security groups
3. ✅ Update environment variables
4. ✅ Test connection
5. ✅ Create database tables
6. 🚀 Start your application with database


