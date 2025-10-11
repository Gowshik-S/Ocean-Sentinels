# Railway Deployment Guide for Ocean Hazard

## Pre-deployment Checklist

✅ **Files Created:**
- `.gitignore` - Excludes sensitive files and development artifacts
- `.env.example` - Template for environment variables
- `Procfile` - Railway deployment configuration
- `railway.json` - Railway service configuration

## Environment Variables to Set in Railway

In your Railway dashboard, add these environment variables:

### Database Configuration
```
DB_HOST=your_aws_rds_host
DB_PORT=5432
DB_NAME=your_database_name
DB_USER=your_database_username
DB_PASSWORD=your_database_password
```

### JWT Configuration
```
JWT_SECRET_KEY=your_jwt_secret_key_here
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30
```

### Server Configuration
```
PORT=9000
HOST=0.0.0.0
DEBUG=False
```

### CORS Configuration
```
FRONTEND_URL=https://your-frontend-url.railway.app
```

## Deployment Steps

1. **Prepare Repository:**
   ```bash
   git add .
   git commit -m "Prepare for Railway deployment"
   git push origin main
   ```

2. **Deploy to Railway:**
   - Connect your GitHub repository to Railway
   - Railway will automatically detect the Python app
   - Set the environment variables listed above
   - Deploy!

3. **Verify Deployment:**
   - Check the health endpoint: `https://your-app.railway.app/health`
   - Test the API docs: `https://your-app.railway.app/api/docs`

## Important Notes

- **Database:** Make sure your AWS RDS instance allows connections from Railway IPs
- **CORS:** Update the CORS settings in production to use your actual frontend URL
- **Environment:** Never commit `.env` files with real credentials
- **Logs:** Use Railway's built-in logging to monitor the application

## Files Excluded from Deployment

The `.gitignore` file excludes:
- Development test files (`test_*.py`, `debug_*.html`)
- Virtual environment (`venv/`)
- Environment files (`.env`)
- Python cache files (`__pycache__/`)
- Database files (`.sqlite`, `.db`)
- OS files (`.DS_Store`, `Thumbs.db`)

## Security Considerations

- All sensitive configuration is moved to environment variables
- Test files and debug scripts are excluded from deployment
- Database credentials are not in the codebase
- JWT secrets are configurable via environment

## Troubleshooting

If deployment fails:
1. Check Railway logs for error messages
2. Verify all environment variables are set correctly
3. Ensure AWS RDS security groups allow Railway connections
4. Check that the start command in `Procfile` is correct