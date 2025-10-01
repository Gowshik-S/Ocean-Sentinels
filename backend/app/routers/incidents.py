"""
Incidents router for Ocean Hazard API
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_, desc, func
from sqlalchemy.orm import selectinload
from typing import Optional, List
from datetime import datetime
import uuid

from app.database import get_db
from app.models.incident import Incident, IncidentStatus, HazardType, UrgencyLevel
from app.models.user import User, UserRole
from app.schemas.incident import IncidentCreate, IncidentResponse, IncidentUpdate, IncidentListResponse
from app.routers.auth import get_current_user, get_current_active_user

router = APIRouter()

def generate_reference_id() -> str:
    """Generate a unique reference ID for incidents"""
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    random_suffix = str(uuid.uuid4())[:8].upper()
    return f"OG-{timestamp}-{random_suffix}"

@router.post("/", response_model=IncidentResponse)
async def create_incident(
    incident_data: IncidentCreate,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a new incident report"""
    reference_id = generate_reference_id()
    
    db_incident = Incident(
        reference_id=reference_id,
        hazard_type=incident_data.hazard_type,
        location=incident_data.location,
        latitude=incident_data.latitude,
        longitude=incident_data.longitude,
        description=incident_data.description,
        urgency=incident_data.urgency,
        contact_info=incident_data.contact_info,
        reporter_id=current_user.id,
        status=IncidentStatus.PENDING
    )
    
    db.add(db_incident)
    await db.commit()
    await db.refresh(db_incident)
    
    return db_incident

@router.get("/", response_model=IncidentListResponse)
async def get_incidents(
    page: int = Query(1, ge=1),
    size: int = Query(10, ge=1, le=100),
    status: Optional[IncidentStatus] = None,
    hazard_type: Optional[HazardType] = None,
    reporter_id: Optional[int] = None,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get incidents with filtering and pagination"""
    query = select(Incident)
    
    # Apply filters based on user role
    if current_user.role == UserRole.PUBLIC:
        # Public users can only see their own incidents
        query = query.where(Incident.reporter_id == current_user.id)
    elif current_user.role in [UserRole.ADMIN, UserRole.AUTHORITY, UserRole.RESCUE_TEAM]:
        # Admin/Authority/Rescue Team can see all incidents with filters
        filters = []
        if status:
            filters.append(Incident.status == status)
        if hazard_type:
            filters.append(Incident.hazard_type == hazard_type)
        if reporter_id:
            filters.append(Incident.reporter_id == reporter_id)
        
        if filters:
            query = query.where(and_(*filters))
    
    # Get total count
    count_query = select(func.count(Incident.id))
    if current_user.role == UserRole.PUBLIC:
        count_query = count_query.where(Incident.reporter_id == current_user.id)
    elif current_user.role in [UserRole.ADMIN, UserRole.AUTHORITY, UserRole.RESCUE_TEAM]:
        filters = []
        if status:
            filters.append(Incident.status == status)
        if hazard_type:
            filters.append(Incident.hazard_type == hazard_type)
        if reporter_id:
            filters.append(Incident.reporter_id == reporter_id)
        
        if filters:
            count_query = count_query.where(and_(*filters))
    
    total_result = await db.execute(count_query)
    total = total_result.scalar()
    
    # Apply pagination and ordering
    query = query.order_by(desc(Incident.created_at))
    query = query.offset((page - 1) * size).limit(size)
    
    result = await db.execute(query)
    incidents = result.scalars().all()
    
    return IncidentListResponse(
        incidents=incidents,
        total=total,
        page=page,
        size=size,
        has_next=(page * size) < total,
        has_prev=page > 1
    )

@router.get("/{incident_id}", response_model=IncidentResponse)
async def get_incident(
    incident_id: int,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get a specific incident by ID"""
    query = select(Incident).options(
        selectinload(Incident.reporter),
        selectinload(Incident.verified_by)
    ).where(Incident.id == incident_id)
    
    result = await db.execute(query)
    incident = result.scalar_one_or_none()
    
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")
    
    # Check access permissions
    if current_user.role == UserRole.PUBLIC and incident.reporter_id != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied")
    elif current_user.role == UserRole.RESCUE_TEAM and incident.reporter_id != current_user.id:
        # Rescue teams can view all incidents but with limited information
        pass
    
    return incident

@router.put("/{incident_id}/verify")
async def verify_incident(
    incident_id: int,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Verify an incident (Admin/Authority/Rescue Team only)"""
    if current_user.role not in [UserRole.ADMIN, UserRole.AUTHORITY, UserRole.RESCUE_TEAM]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    result = await db.execute(select(Incident).where(Incident.id == incident_id))
    incident = result.scalar_one_or_none()
    
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")
    
    incident.status = IncidentStatus.VERIFIED
    incident.verified_by_id = current_user.id
    incident.verified_at = datetime.utcnow()
    
    await db.commit()
    await db.refresh(incident)
    
    return {"message": "Incident verified successfully"}

@router.put("/{incident_id}/deploy")
async def deploy_response(
    incident_id: int,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Deploy response to an incident (Admin/Authority/Rescue Team only)"""
    if current_user.role not in [UserRole.ADMIN, UserRole.AUTHORITY, UserRole.RESCUE_TEAM]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    result = await db.execute(select(Incident).where(Incident.id == incident_id))
    incident = result.scalar_one_or_none()
    
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")
    
    incident.status = IncidentStatus.IN_PROGRESS
    
    await db.commit()
    await db.refresh(incident)
    
    return {"message": "Response deployed successfully"}

@router.put("/{incident_id}/resolve")
async def resolve_incident(
    incident_id: int,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Resolve an incident (Admin/Authority/Rescue Team only)"""
    if current_user.role not in [UserRole.ADMIN, UserRole.AUTHORITY, UserRole.RESCUE_TEAM]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    result = await db.execute(select(Incident).where(Incident.id == incident_id))
    incident = result.scalar_one_or_none()
    
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")
    
    incident.status = IncidentStatus.RESOLVED
    incident.resolved_at = datetime.utcnow()
    
    await db.commit()
    await db.refresh(incident)
    
    return {"message": "Incident resolved successfully"}

