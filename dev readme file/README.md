# 🌊 Ocean Hazard FastAPI Backend

A comprehensive FastAPI backend for India's Coastal Safety Network, built for the Ministry of Earth Sciences, Government of India.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   FastAPI       │    │   AWS Cloud     │
│   (HTML/JS)     │◄──►│   Backend       │◄──►│   Infrastructure │
│                 │    │                 │    │                 │
│ • User Interface│    │ • REST API      │    │ • RDS PostgreSQL│
│ • Real-time Map │    │ • WebSocket     │    │ • ElastiCache   │
│ • Analytics     │    │ • Authentication│    │ • ECS Fargate   │
│ • Reports       │    │ • Authorization │    │ • S3 Storage    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Features

### 🔐 Authentication & Authorization
- JWT-based authentication
- Role-based access control (Public, Admin, Authority, Rescue Team)
- Secure password hashing with bcrypt
- Session management

### 📊 Incident Management
- Create, read, update incident reports
- Real-time incident tracking
- Geographic location support
- Photo evidence upload
- Status workflow (Pending → Verified → In Progress → Resolved)

### 📈 Analytics Dashboard
- Real-time dashboard metrics
- Incident timeline analysis
- Geographic distribution
- Response efficiency tracking
- Custom date range filtering

### 🔄 Real-time Updates
- WebSocket connections for live updates
- Push notifications for new incidents
- Status change alerts
- Real-time map updates

### ☁️ AWS Cloud Integration
- PostgreSQL RDS database
- Redis ElastiCache for sessions
- S3 storage for file uploads
- ECS Fargate for containerized deployment
- Application Load Balancer

## 🛠️ Technology Stack

- **Backend**: FastAPI, Python 3.11
- **Database**: PostgreSQL with SQLAlchemy ORM
- **Cache**: Redis
- **Authentication**: JWT with python-jose
- **Cloud**: AWS (RDS, ElastiCache, ECS, S3)
- **Containerization**: Docker
- **Real-time**: WebSockets
- **Security**: bcrypt, CORS, HTTPS

## 📦 Installation

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/Gowshik-S/Ocean-Hazard.git
   cd Ocean-Hazard/backend
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up environment variables**
   ```bash
   cp env.example .env
   # Edit .env with your configuration
   ```

5. **Run with Docker Compose**
   ```bash
   docker-compose up -d
   ```

6. **Or run directly**
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

### AWS Production Deployment

1. **Prerequisites**
   - AWS CLI configured
   - Docker installed
   - CloudFormation permissions

2. **Deploy to AWS**
   ```bash
   ./scripts/deploy.sh
   ```

## 🔧 Configuration

### Environment Variables

```bash
# Database
DATABASE_URL=postgresql://user:password@host:port/database
REDIS_URL=redis://host:port

# JWT
SECRET_KEY=your-secret-key
ACCESS_TOKEN_EXPIRE_MINUTES=30

# AWS
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-east-1
AWS_S3_BUCKET=your-bucket-name

# Application
DEBUG=True
HOST=0.0.0.0
PORT=8000
```

## 📚 API Documentation

### Authentication Endpoints
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/auth/me` - Get current user
- `POST /api/auth/logout` - User logout

### Incident Endpoints
- `POST /api/incidents/` - Create incident
- `GET /api/incidents/` - List incidents (with filtering)
- `GET /api/incidents/{id}` - Get specific incident
- `PUT /api/incidents/{id}/verify` - Verify incident (Admin)
- `PUT /api/incidents/{id}/deploy` - Deploy response (Admin)
- `PUT /api/incidents/{id}/resolve` - Resolve incident (Admin)

### Analytics Endpoints
- `GET /api/analytics/dashboard` - Dashboard metrics
- `GET /api/analytics/incidents/timeline` - Timeline data
- `GET /api/analytics/incidents/distribution` - Distribution data
- `GET /api/analytics/geographic` - Geographic data

### WebSocket Endpoints
- `WS /api/ws/incidents` - Real-time incident updates

## 🔒 Security Features

- JWT token-based authentication
- Role-based access control
- Password hashing with bcrypt
- CORS protection
- SQL injection prevention
- XSS protection
- Rate limiting (configurable)

## 📊 Database Schema

### Users Table
- User authentication and profile data
- Role-based permissions
- Activity tracking

### Incidents Table
- Incident reports with location data
- Status tracking
- Verification workflow
- Timestamps and audit trail

### Analytics Tables
- System metrics
- Performance data
- Historical snapshots

## 🚀 Deployment

### Local Development
```bash
docker-compose up -d
```

### AWS Production
```bash
./scripts/deploy.sh
```

### Manual AWS Deployment
1. Create RDS PostgreSQL instance
2. Create ElastiCache Redis cluster
3. Build and push Docker image to ECR
4. Deploy ECS service with Fargate
5. Configure Application Load Balancer

## 📈 Monitoring & Logging

- CloudWatch integration
- Application logs
- Performance metrics
- Error tracking
- Health checks

## 🔧 Development

### Running Tests
```bash
pytest
```

### Database Migrations
```bash
alembic upgrade head
```

### Code Quality
```bash
black app/
flake8 app/
mypy app/
```

## 📞 Support

- **Project**: Ocean Guard Coastal Safety Network
- **Organization**: Ministry of Earth Sciences, Government of India
- **Contact**: support@oceanguard.gov.in
- **Documentation**: [API Docs](http://localhost:8000/api/docs)

## 📄 License

This project is part of India's Digital Initiative for Coastal Safety and Security.

---

**Last Updated**: January 27, 2025 | **Version**: 1.0.0 | **Status**: Production Ready


