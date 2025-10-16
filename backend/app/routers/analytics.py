"""
Analytics router for Ocean Hazard API
"""

from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, desc
from sqlalchemy.orm import selectinload
from typing import Optional, Dict, Any
from datetime import datetime, timedelta
import json

from app.database import get_db
from app.models.incident import Incident, IncidentStatus, HazardType
from app.models.analytics import AnalyticsSnapshot, SystemMetrics, UserVisit, WebsiteStats
from app.models.user import User, UserRole
from app.routers.auth import get_current_active_user

router = APIRouter()

@router.get("/public/dashboard")
async def get_public_dashboard_analytics(
    db: AsyncSession = Depends(get_db)
):
    """Get public dashboard analytics data (no authentication required)"""
    # Get total incidents
    total_incidents_result = await db.execute(select(func.count(Incident.id)))
    total_incidents = total_incidents_result.scalar()
    
    # Get active incidents
    active_incidents_result = await db.execute(
        select(func.count(Incident.id)).where(
            Incident.status.in_([IncidentStatus.PENDING, IncidentStatus.VERIFIED, IncidentStatus.IN_PROGRESS])
        )
    )
    active_incidents = active_incidents_result.scalar()
    
    # Get resolved incidents
    resolved_incidents_result = await db.execute(
        select(func.count(Incident.id)).where(Incident.status == IncidentStatus.RESOLVED)
    )
    resolved_incidents = resolved_incidents_result.scalar()
    
    # Get incidents by type
    incidents_by_type_result = await db.execute(
        select(Incident.hazard_type, func.count(Incident.id))
        .group_by(Incident.hazard_type)
    )
    incidents_by_type = dict(incidents_by_type_result.all())
    
    return {
        "total_incidents": total_incidents,
        "active_incidents": active_incidents,
        "resolved_incidents": resolved_incidents,
        "incidents_by_type": incidents_by_type,
        "last_updated": datetime.utcnow().isoformat()
    }

@router.get("/public/timeline")
async def get_public_incidents_timeline(
    days: int = Query(default=30, description="Number of days to look back"),
    db: AsyncSession = Depends(get_db)
):
    """Get incidents timeline data (public access)"""
    start_date = datetime.utcnow() - timedelta(days=days)
    
    # Get incidents grouped by date
    result = await db.execute(
        select(
            func.date(Incident.created_at).label('date'),
            func.count(Incident.id).label('count')
        )
        .where(Incident.created_at >= start_date)
        .group_by(func.date(Incident.created_at))
        .order_by(func.date(Incident.created_at))
    )
    
    timeline_data = []
    for row in result.all():
        timeline_data.append({
            "date": row.date.isoformat() if row.date else None,
            "count": row.count
        })
    
    return timeline_data

@router.get("/dashboard")
async def get_dashboard_analytics(
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get dashboard analytics data"""
    # Get total incidents
    total_incidents_result = await db.execute(select(func.count(Incident.id)))
    total_incidents = total_incidents_result.scalar()
    
    # Get active incidents
    active_incidents_result = await db.execute(
        select(func.count(Incident.id)).where(
            Incident.status.in_([IncidentStatus.PENDING, IncidentStatus.VERIFIED, IncidentStatus.IN_PROGRESS])
        )
    )
    active_incidents = active_incidents_result.scalar()
    
    # Get resolved incidents
    resolved_incidents_result = await db.execute(
        select(func.count(Incident.id)).where(Incident.status == IncidentStatus.RESOLVED)
    )
    resolved_incidents = resolved_incidents_result.scalar()
    
    # Get false alarms
    false_alarms_result = await db.execute(
        select(func.count(Incident.id)).where(Incident.status == IncidentStatus.FALSE_ALARM)
    )
    false_alarms = false_alarms_result.scalar()
    
    # Get incidents by type
    incidents_by_type_result = await db.execute(
        select(Incident.hazard_type, func.count(Incident.id))
        .group_by(Incident.hazard_type)
    )
    incidents_by_type = dict(incidents_by_type_result.all())
    
    # Get recent incidents (last 7 days)
    week_ago = datetime.utcnow() - timedelta(days=7)
    recent_incidents_result = await db.execute(
        select(func.count(Incident.id)).where(Incident.created_at >= week_ago)
    )
    recent_incidents = recent_incidents_result.scalar()
    
    # Calculate average response time (mock data for now)
    avg_response_time_hours = 6.5
    
    return {
        "total_incidents": total_incidents,
        "active_incidents": active_incidents,
        "resolved_incidents": resolved_incidents,
        "false_alarms": false_alarms,
        "incidents_by_type": incidents_by_type,
        "recent_incidents": recent_incidents,
        "average_response_time_hours": avg_response_time_hours,
        "last_updated": datetime.utcnow().isoformat()
    }

@router.get("/incidents/timeline")
async def get_incidents_timeline(
    days: int = Query(30, ge=1, le=365),
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get incidents timeline data"""
    start_date = datetime.utcnow() - timedelta(days=days)
    
    # Get incidents grouped by date
    timeline_result = await db.execute(
        select(
            func.date(Incident.created_at).label('date'),
            func.count(Incident.id).label('count')
        )
        .where(Incident.created_at >= start_date)
        .group_by(func.date(Incident.created_at))
        .order_by(func.date(Incident.created_at))
    )
    
    timeline_data = timeline_result.all()
    
    # Format data for frontend
    timeline = []
    for row in timeline_data:
        timeline.append({
            "date": row.date.isoformat(),
            "count": row.count
        })
    
    return {
        "timeline": timeline,
        "period_days": days,
        "start_date": start_date.isoformat(),
        "end_date": datetime.utcnow().isoformat()
    }

@router.get("/incidents/distribution")
async def get_incidents_distribution(
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get incidents distribution by type and region"""
    # By hazard type
    type_distribution_result = await db.execute(
        select(Incident.hazard_type, func.count(Incident.id))
        .group_by(Incident.hazard_type)
    )
    type_distribution = dict(type_distribution_result.all())
    
    # By status
    status_distribution_result = await db.execute(
        select(Incident.status, func.count(Incident.id))
        .group_by(Incident.status)
    )
    status_distribution = dict(status_distribution_result.all())
    
    # By urgency level
    urgency_distribution_result = await db.execute(
        select(Incident.urgency, func.count(Incident.id))
        .group_by(Incident.urgency)
    )
    urgency_distribution = dict(urgency_distribution_result.all())
    
    return {
        "by_type": type_distribution,
        "by_status": status_distribution,
        "by_urgency": urgency_distribution
    }

@router.get("/response-efficiency")
async def get_response_efficiency(
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get response efficiency metrics"""
    # This would typically involve more complex calculations
    # For now, returning mock data
    return {
        "average_response_time_hours": 6.5,
        "verification_rate": 0.85,
        "resolution_rate": 0.78,
        "false_alarm_rate": 0.12,
        "efficiency_score": 8.2
    }

@router.get("/geographic")
async def get_geographic_analytics(
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get geographic distribution of incidents"""
    # Get incidents with coordinates
    incidents_result = await db.execute(
        select(Incident.latitude, Incident.longitude, Incident.hazard_type, Incident.status)
        .where(Incident.latitude.isnot(None))
        .where(Incident.longitude.isnot(None))
    )
    
    incidents = incidents_result.all()
    
    # Format for frontend map
    geographic_data = []
    for incident in incidents:
        geographic_data.append({
            "lat": float(incident.latitude),
            "lng": float(incident.longitude),
            "type": incident.hazard_type,
            "status": incident.status
        })
    
    return {
        "incidents": geographic_data,
        "total_located_incidents": len(geographic_data)
    }

@router.get("/public/system-stats")
async def get_public_system_stats(
    db: AsyncSession = Depends(get_db)
):
    """Get public system statistics (no authentication required)"""
    # Get total reports filed
    total_reports_result = await db.execute(select(func.count(Incident.id)))
    total_reports = total_reports_result.scalar()
    
    # Get active incidents
    active_incidents_result = await db.execute(
        select(func.count(Incident.id)).where(
            Incident.status.in_([IncidentStatus.PENDING, IncidentStatus.VERIFIED, IncidentStatus.IN_PROGRESS])
        )
    )
    active_incidents = active_incidents_result.scalar()
    
    # Get rescue teams registered (users with RESCUE_TEAM role)
    rescue_teams_result = await db.execute(
        select(func.count(User.id)).where(User.role == UserRole.RESCUE_TEAM)
    )
    rescue_teams = rescue_teams_result.scalar()
    
    # Static coastline length for India (actual value)
    coastline_km = 7516
    
    return {
        "total_reports": total_reports,
        "active_incidents": active_incidents,
        "rescue_teams_registered": rescue_teams,
        "coastline_watched_km": coastline_km,
        "last_updated": datetime.utcnow().isoformat()
    }

# ===== USER VISIT TRACKING ENDPOINTS =====

@router.post("/track-visit")
async def track_user_visit(
    visit_data: Dict[str, Any],
    db: AsyncSession = Depends(get_db)
):
    """Track user visits and store analytics data"""
    try:
        # Extract visit data
        ip_address = visit_data.get('ip', 'unknown')
        user_agent = visit_data.get('userAgent', '')
        location_data = visit_data.get('location', {})
        referrer = visit_data.get('referrer', '')
        page_url = visit_data.get('pageUrl', '')
        session_id = visit_data.get('sessionId', '')
        user_id = visit_data.get('userId')

        # Parse location data
        country = location_data.get('country')
        city = location_data.get('city')
        region = location_data.get('region')
        latitude = location_data.get('latitude')
        longitude = location_data.get('longitude')
        timezone = location_data.get('timezone')

        # Parse device/browser info
        language = visit_data.get('language', '')
        device_type = visit_data.get('deviceType', 'desktop')
        browser = visit_data.get('browser', '')
        os = visit_data.get('os', '')
        is_bot = visit_data.get('isBot', False)

        # Create new visit record
        new_visit = UserVisit(
            ip_address=ip_address,
            user_agent=user_agent,
            country=country,
            city=city,
            region=region,
            latitude=latitude,
            longitude=longitude,
            timezone=timezone,
            language=language,
            referrer=referrer,
            page_url=page_url,
            session_id=session_id,
            user_id=user_id,
            device_type=device_type,
            browser=browser,
            os=os,
            is_bot=is_bot
        )

        db.add(new_visit)
        await db.commit()
        await db.refresh(new_visit)

        return {
            "success": True,
            "visit_id": new_visit.id,
            "message": "Visit tracked successfully"
        }

    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to track visit: {str(e)}")

@router.get("/visits/summary")
async def get_visits_summary(
    days: int = Query(default=30, description="Number of days to look back"),
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get website visits summary (admin only)"""
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Admin access required")

    start_date = datetime.utcnow() - timedelta(days=days)

    # Total visits
    total_visits_result = await db.execute(
        select(func.count(UserVisit.id)).where(UserVisit.created_at >= start_date)
    )
    total_visits = total_visits_result.scalar()

    # Unique visitors (unique IP addresses)
    unique_visitors_result = await db.execute(
        select(func.count(func.distinct(UserVisit.ip_address))).where(UserVisit.created_at >= start_date)
    )
    unique_visitors = unique_visitors_result.scalar()

    # Unique sessions
    unique_sessions_result = await db.execute(
        select(func.count(func.distinct(UserVisit.session_id))).where(
            and_(UserVisit.created_at >= start_date, UserVisit.session_id.isnot(None))
        )
    )
    unique_sessions = unique_sessions_result.scalar()

    # Visits by country
    country_result = await db.execute(
        select(UserVisit.country, func.count(UserVisit.id))
        .where(and_(UserVisit.created_at >= start_date, UserVisit.country.isnot(None)))
        .group_by(UserVisit.country)
        .order_by(func.count(UserVisit.id).desc())
        .limit(10)
    )
    visits_by_country = dict(country_result.all())

    # Visits by device type
    device_result = await db.execute(
        select(UserVisit.device_type, func.count(UserVisit.id))
        .where(and_(UserVisit.created_at >= start_date, UserVisit.device_type.isnot(None)))
        .group_by(UserVisit.device_type)
    )
    visits_by_device = dict(device_result.all())

    # Daily visits for the last 30 days
    daily_visits_result = await db.execute(
        select(
            func.date(UserVisit.created_at).label('date'),
            func.count(UserVisit.id).label('visits')
        )
        .where(UserVisit.created_at >= start_date)
        .group_by(func.date(UserVisit.created_at))
        .order_by(func.date(UserVisit.created_at))
    )

    daily_visits = []
    for row in daily_visits_result.all():
        daily_visits.append({
            "date": row.date.isoformat() if row.date else None,
            "visits": row.visits
        })

    return {
        "total_visits": total_visits,
        "unique_visitors": unique_visitors,
        "unique_sessions": unique_sessions,
        "visits_by_country": visits_by_country,
        "visits_by_device": visits_by_device,
        "daily_visits": daily_visits,
        "period_days": days,
        "generated_at": datetime.utcnow().isoformat()
    }

@router.get("/visits/details")
async def get_visits_details(
    skip: int = Query(default=0, description="Number of records to skip"),
    limit: int = Query(default=100, description="Number of records to return"),
    days: int = Query(default=7, description="Number of days to look back"),
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get detailed visit records (admin only)"""
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Admin access required")

    start_date = datetime.utcnow() - timedelta(days=days)

    result = await db.execute(
        select(UserVisit)
        .where(UserVisit.created_at >= start_date)
        .order_by(UserVisit.created_at.desc())
        .offset(skip)
        .limit(limit)
    )

    visits = result.scalars().all()

    return {
        "visits": [
            {
                "id": visit.id,
                "ip_address": visit.ip_address,
                "country": visit.country,
                "city": visit.city,
                "device_type": visit.device_type,
                "browser": visit.browser,
                "os": visit.os,
                "page_url": visit.page_url,
                "referrer": visit.referrer,
                "created_at": visit.created_at.isoformat() if visit.created_at else None,
                "is_bot": visit.is_bot
            }
            for visit in visits
        ],
        "total": len(visits),
        "skip": skip,
        "limit": limit
    }

@router.get("/visits/stats")
async def get_visits_stats(
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get real-time visit statistics (admin only)"""
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Admin access required")

    # Today's visits
    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    today_visits_result = await db.execute(
        select(func.count(UserVisit.id)).where(UserVisit.created_at >= today_start)
    )
    today_visits = today_visits_result.scalar()

    # This week's visits
    week_start = datetime.utcnow() - timedelta(days=7)
    week_visits_result = await db.execute(
        select(func.count(UserVisit.id)).where(UserVisit.created_at >= week_start)
    )
    week_visits = week_visits_result.scalar()

    # This month's visits
    month_start = datetime.utcnow() - timedelta(days=30)
    month_visits_result = await db.execute(
        select(func.count(UserVisit.id)).where(UserVisit.created_at >= month_start)
    )
    month_visits = month_visits_result.scalar()

    # Total visits ever
    total_visits_result = await db.execute(select(func.count(UserVisit.id)))
    total_visits = total_visits_result.scalar()

    # Unique visitors (distinct IP addresses)
    unique_visitors_result = await db.execute(
        select(func.count(func.distinct(UserVisit.ip_address)))
    )
    unique_visitors = unique_visitors_result.scalar()

    # Current online users (visits in last 5 minutes)
    online_threshold = datetime.utcnow() - timedelta(minutes=5)
    online_users_result = await db.execute(
        select(func.count(func.distinct(UserVisit.session_id))).where(
            UserVisit.created_at >= online_threshold
        )
    )
    online_users = online_users_result.scalar()

    return {
        "today_visits": today_visits,
        "week_visits": week_visits,
        "month_visits": month_visits,
        "total_visits": total_visits,
        "unique_visitors": unique_visitors,
        "online_users": online_users,
        "last_updated": datetime.utcnow().isoformat()
    }