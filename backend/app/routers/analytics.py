"""
Analytics router for Ocean Hazard API
"""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, desc
from sqlalchemy.orm import selectinload
from typing import Optional, Dict, Any
from datetime import datetime, timedelta
import json

from app.database import get_db
from app.models.incident import Incident, IncidentStatus, HazardType
from app.models.analytics import AnalyticsSnapshot, SystemMetrics
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



