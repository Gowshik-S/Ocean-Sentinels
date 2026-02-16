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
from app.schemas.incident import IncidentCreate, IncidentUpdate
from app.routers.auth import get_current_user, get_current_active_user

router = APIRouter()

def format_hazard_type(hazard_type: HazardType) -> str:
    """Format hazard type enum to frontend-compatible format"""
    return hazard_type.value.lower().replace('_', '-')

def format_status(status: IncidentStatus) -> str:
    """Format status enum to frontend-compatible format"""
    return status.value.lower()

def format_urgency(urgency: UrgencyLevel) -> str:
    """Format urgency enum to frontend-compatible format"""
    return urgency.value.lower()

def generate_reference_id() -> str:
    """Generate a unique reference ID for incidents"""
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    random_suffix = str(uuid.uuid4())[:8].upper()
    return f"OG-{timestamp}-{random_suffix}"

@router.post("/", response_model=None)
async def create_incident(
    incident_data: dict,  # Use dict instead of Pydantic model temporarily
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a new incident report"""
    try:
        reference_id = generate_reference_id()
        
        # Manually validate and convert the data
        hazard_type = incident_data.get('hazard_type', 'other').upper().replace('-', '_')
        location = incident_data.get('location', '')
        description = incident_data.get('description', '')
        urgency = incident_data.get('urgency', 'low').upper()
        mesh_message_id = incident_data.get('mesh_message_id')
        
        # --- Mesh deduplication ---
        # If a mesh_message_id is provided, check if this incident already exists
        if mesh_message_id:
            existing_result = await db.execute(
                select(Incident).where(Incident.mesh_message_id == mesh_message_id)
            )
            existing_incident = existing_result.scalar_one_or_none()
            if existing_incident:
                # Return the existing incident with duplicate flag.
                # The Android client uses 'duplicate: true' to know it was
                # already delivered by another device in the mesh, so it
                # can mark the local copy as DELIVERED and stop relaying.
                incident_dict = {
                    "id": int(existing_incident.id),
                    "reference_id": str(existing_incident.reference_id),
                    "hazard_type": format_hazard_type(existing_incident.hazard_type),
                    "location": str(existing_incident.location),
                    "latitude": float(existing_incident.latitude) if existing_incident.latitude else None,
                    "longitude": float(existing_incident.longitude) if existing_incident.longitude else None,
                    "description": str(existing_incident.description),
                    "urgency": format_urgency(existing_incident.urgency),
                    "status": format_status(existing_incident.status),
                    "contact_info": str(existing_incident.contact_info) if existing_incident.contact_info else None,
                    "photo_url": str(existing_incident.photo_url) if existing_incident.photo_url else None,
                    "reporter_id": int(existing_incident.reporter_id),
                    "verified_by_id": int(existing_incident.verified_by_id) if existing_incident.verified_by_id else None,
                    "assigned_to_id": int(existing_incident.assigned_to_id) if existing_incident.assigned_to_id else None,
                    "created_at": existing_incident.created_at.isoformat() if existing_incident.created_at else None,
                    "updated_at": existing_incident.updated_at.isoformat() if existing_incident.updated_at else None,
                    "verified_at": existing_incident.verified_at.isoformat() if existing_incident.verified_at else None,
                    "resolved_at": existing_incident.resolved_at.isoformat() if existing_incident.resolved_at else None,
                    "assigned_at": existing_incident.assigned_at.isoformat() if existing_incident.assigned_at else None,
                    "duplicate": True,
                    "mesh_message_id": mesh_message_id
                }
                return incident_dict
        
        # Convert string enum values to enum instances
        hazard_type_enum = HazardType(hazard_type)
        urgency_enum = UrgencyLevel(urgency)
        
        db_incident = Incident(
            reference_id=reference_id,
            hazard_type=hazard_type_enum,
            location=location,
            latitude=incident_data.get('latitude'),
            longitude=incident_data.get('longitude'),
            description=description,
            urgency=urgency_enum,
            contact_info=incident_data.get('contact_info'),
            reporter_id=current_user.id,
            status=IncidentStatus.PENDING,
            mesh_message_id=mesh_message_id
        )
        
        db.add(db_incident)
        await db.commit()
        await db.refresh(db_incident)
        
        # Return incident as simple dict - no validation
        incident_dict = {
            "id": db_incident.id,
            "reference_id": db_incident.reference_id,
            "hazard_type": format_hazard_type(db_incident.hazard_type),
            "location": str(db_incident.location),
            "latitude": float(db_incident.latitude) if db_incident.latitude else None,
            "longitude": float(db_incident.longitude) if db_incident.longitude else None,
            "description": str(db_incident.description),
            "urgency": format_urgency(db_incident.urgency),
            "status": format_status(db_incident.status),
            "contact_info": str(db_incident.contact_info) if db_incident.contact_info else None,
            "photo_url": str(db_incident.photo_url) if db_incident.photo_url else None,
            "reporter_id": int(db_incident.reporter_id),
            "verified_by_id": int(db_incident.verified_by_id) if db_incident.verified_by_id else None,
            "assigned_to_id": int(db_incident.assigned_to_id) if db_incident.assigned_to_id else None,
            "created_at": db_incident.created_at.isoformat() if db_incident.created_at else None,
            "updated_at": db_incident.updated_at.isoformat() if db_incident.updated_at else None,
            "verified_at": db_incident.verified_at.isoformat() if db_incident.verified_at else None,
            "resolved_at": db_incident.resolved_at.isoformat() if db_incident.resolved_at else None,
            "assigned_at": db_incident.assigned_at.isoformat() if db_incident.assigned_at else None,
            "duplicate": False,
            "mesh_message_id": mesh_message_id
        }
        
        return incident_dict
        
    except Exception as e:
        try:
            await db.rollback()
        except Exception:
            pass  # Connection may already be closed
        print(f"Incident creation error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to create incident: {str(e)}")


@router.post("/mesh/check", response_model=None)
async def check_mesh_messages(
    request_data: dict,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Bulk check which mesh_message_ids have already been delivered to the server.
    
    Android devices call this when they come online to find out which queued
    messages have already been delivered by another device in the mesh.
    Those can then be marked as DELIVERED locally and stop being relayed.
    
    Request:  { "message_ids": ["abc123", "def456", ...] }
    Response: { "delivered": ["abc123"], "unknown": ["def456"] }
    """
    message_ids = request_data.get("message_ids", [])
    if not message_ids or not isinstance(message_ids, list):
        return {"delivered": [], "unknown": []}
    
    # Cap at 100 to prevent abuse
    message_ids = message_ids[:100]
    
    try:
        result = await db.execute(
            select(Incident.mesh_message_id).where(
                Incident.mesh_message_id.in_(message_ids)
            )
        )
        delivered_ids = set(row[0] for row in result.all() if row[0])
        
        return {
            "delivered": [mid for mid in message_ids if mid in delivered_ids],
            "unknown": [mid for mid in message_ids if mid not in delivered_ids]
        }
    except Exception as e:
        print(f"Mesh check error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to check mesh messages: {str(e)}")


@router.get("/", response_model=None)
async def get_incidents(
    page: int = Query(1, ge=1),
    size: int = Query(10, ge=1, le=100),
    status: Optional[str] = None,
    hazard_type: Optional[str] = None,
    reporter_id: Optional[int] = None,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get incidents with filtering and pagination"""
    try:
        query = select(Incident)
        
        # Apply filters based on user role
        if current_user.role == UserRole.PUBLIC:
            # Public users can only see their own incidents
            query = query.where(Incident.reporter_id == current_user.id)
        elif current_user.role in [UserRole.ADMIN, UserRole.AUTHORITY, UserRole.RESCUE_TEAM]:
            # Admin/Authority/Rescue Team can see all incidents with filters
            filters = []
            if status:
                try:
                    status_enum = IncidentStatus(status)
                    filters.append(Incident.status == status_enum)
                except ValueError:
                    pass  # Invalid status, ignore filter
            if hazard_type:
                try:
                    hazard_type_enum = HazardType(hazard_type.upper().replace('-', '_'))
                    filters.append(Incident.hazard_type == hazard_type_enum)
                except ValueError:
                    pass  # Invalid hazard type, ignore filter
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
                try:
                    status_enum = IncidentStatus(status)
                    filters.append(Incident.status == status_enum)
                except ValueError:
                    pass
            if hazard_type:
                try:
                    hazard_type_enum = HazardType(hazard_type.upper().replace('-', '_'))
                    filters.append(Incident.hazard_type == hazard_type_enum)
                except ValueError:
                    pass
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
        
        # Convert incidents to dicts for proper serialization
        incidents_data = []
        for incident in incidents:
            incident_dict = {
                "id": int(incident.id),
                "reference_id": str(incident.reference_id),
                "hazard_type": format_hazard_type(incident.hazard_type),
                "location": str(incident.location),
                "latitude": float(incident.latitude) if incident.latitude else None,
                "longitude": float(incident.longitude) if incident.longitude else None,
                "description": str(incident.description),
                "urgency": format_urgency(incident.urgency),
                "status": format_status(incident.status),
                "contact_info": str(incident.contact_info) if incident.contact_info else None,
                "photo_url": str(incident.photo_url) if incident.photo_url else None,
                "reporter_id": int(incident.reporter_id),
                "verified_by_id": int(incident.verified_by_id) if incident.verified_by_id else None,
                "assigned_to_id": int(incident.assigned_to_id) if incident.assigned_to_id else None,
                "created_at": incident.created_at.isoformat() if incident.created_at else None,
                "updated_at": incident.updated_at.isoformat() if incident.updated_at else None,
                "verified_at": incident.verified_at.isoformat() if incident.verified_at else None,
                "resolved_at": incident.resolved_at.isoformat() if incident.resolved_at else None,
                "assigned_at": incident.assigned_at.isoformat() if incident.assigned_at else None
            }
            incidents_data.append(incident_dict)
        
        response_dict = {
            "incidents": incidents_data,
            "total": int(total),
            "page": int(page),
            "size": int(size),
            "has_next": bool((page * size) < total),
            "has_prev": bool(page > 1)
        }
        
        return response_dict
        
    except Exception as e:
        print(f"Get incidents error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to get incidents: {str(e)}")

@router.get("/test")
async def test_incident_endpoint():
    """Simple test endpoint"""
    return {"message": "Incident endpoint is working", "status": "ok"}

@router.get("/count")
async def get_incident_count(
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get incident count only"""
    try:
        count_result = await db.execute(select(func.count(Incident.id)))
        total = count_result.scalar()
        return {"count": total, "status": "success"}
    except Exception as e:
        return {"error": str(e), "status": "error"}

@router.get("/{incident_id}", response_model=None)
async def get_incident(
    incident_id: int,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get a specific incident by ID"""
    query = select(Incident).where(Incident.id == incident_id)
    
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
    
    # Return incident as dict for proper serialization
    incident_dict = {
        "id": int(incident.id),
        "reference_id": str(incident.reference_id),
        "hazard_type": format_hazard_type(incident.hazard_type),
        "location": str(incident.location),
        "latitude": float(incident.latitude) if incident.latitude else None,
        "longitude": float(incident.longitude) if incident.longitude else None,
        "description": str(incident.description),
        "urgency": format_urgency(incident.urgency),
        "status": format_status(incident.status),
        "contact_info": str(incident.contact_info) if incident.contact_info else None,
        "photo_url": str(incident.photo_url) if incident.photo_url else None,
        "reporter_id": int(incident.reporter_id),
        "verified_by_id": int(incident.verified_by_id) if incident.verified_by_id else None,
        "assigned_to_id": int(incident.assigned_to_id) if incident.assigned_to_id else None,
        "created_at": incident.created_at.isoformat() if incident.created_at else None,
        "updated_at": incident.updated_at.isoformat() if incident.updated_at else None,
        "verified_at": incident.verified_at.isoformat() if incident.verified_at else None,
        "resolved_at": incident.resolved_at.isoformat() if incident.resolved_at else None,
        "assigned_at": incident.assigned_at.isoformat() if incident.assigned_at else None
    }
    
    return incident_dict

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


@router.put("/{incident_id}/assign")
async def assign_incident(
    incident_id: int,
    assignment_data: dict,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Assign an incident to a rescue team member (Admin/Authority only)"""
    if current_user.role not in [UserRole.ADMIN, UserRole.AUTHORITY]:
        raise HTTPException(status_code=403, detail="Only Admin/Authority can assign incidents")
    
    result = await db.execute(select(Incident).where(Incident.id == incident_id))
    incident = result.scalar_one_or_none()
    
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")
    
    rescue_team_id = assignment_data.get("assigned_to_id")
    if not rescue_team_id:
        raise HTTPException(status_code=400, detail="assigned_to_id is required")
    
    # Verify the rescue team member exists and has RESCUE_TEAM role
    rescue_user_result = await db.execute(select(User).where(User.id == rescue_team_id))
    rescue_user = rescue_user_result.scalar_one_or_none()
    
    if not rescue_user:
        raise HTTPException(status_code=404, detail="Rescue team member not found")
    if rescue_user.role != UserRole.RESCUE_TEAM:
        raise HTTPException(status_code=400, detail="User is not a rescue team member")
    
    incident.assigned_to_id = rescue_team_id
    incident.assigned_at = datetime.utcnow()
    if incident.status == IncidentStatus.PENDING:
        incident.status = IncidentStatus.VERIFIED
    
    await db.commit()
    await db.refresh(incident)
    
    return {"message": f"Incident assigned to rescue team member #{rescue_team_id}"}


@router.get("/assigned/me", response_model=None)
async def get_my_assigned_incidents(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get incidents assigned to the current rescue team member"""
    if current_user.role != UserRole.RESCUE_TEAM:
        raise HTTPException(status_code=403, detail="Only rescue team members can view assigned incidents")
    
    try:
        query = select(Incident).where(Incident.assigned_to_id == current_user.id)
        
        # Count
        count_query = select(func.count(Incident.id)).where(Incident.assigned_to_id == current_user.id)
        total_result = await db.execute(count_query)
        total = total_result.scalar()
        
        # Paginate
        query = query.order_by(desc(Incident.created_at))
        query = query.offset((page - 1) * size).limit(size)
        
        result = await db.execute(query)
        incidents = result.scalars().all()
        
        incidents_data = []
        for incident in incidents:
            incident_dict = {
                "id": int(incident.id),
                "reference_id": str(incident.reference_id),
                "hazard_type": format_hazard_type(incident.hazard_type),
                "location": str(incident.location),
                "latitude": float(incident.latitude) if incident.latitude else None,
                "longitude": float(incident.longitude) if incident.longitude else None,
                "description": str(incident.description),
                "urgency": format_urgency(incident.urgency),
                "status": format_status(incident.status),
                "contact_info": str(incident.contact_info) if incident.contact_info else None,
                "photo_url": str(incident.photo_url) if incident.photo_url else None,
                "reporter_id": int(incident.reporter_id),
                "verified_by_id": int(incident.verified_by_id) if incident.verified_by_id else None,
                "assigned_to_id": int(incident.assigned_to_id) if incident.assigned_to_id else None,
                "created_at": incident.created_at.isoformat() if incident.created_at else None,
                "updated_at": incident.updated_at.isoformat() if incident.updated_at else None,
                "verified_at": incident.verified_at.isoformat() if incident.verified_at else None,
                "resolved_at": incident.resolved_at.isoformat() if incident.resolved_at else None,
                "assigned_at": incident.assigned_at.isoformat() if incident.assigned_at else None
            }
            incidents_data.append(incident_dict)
        
        return {
            "incidents": incidents_data,
            "total": int(total),
            "page": int(page),
            "size": int(size),
            "has_next": bool((page * size) < total),
            "has_prev": bool(page > 1)
        }
    except Exception as e:
        print(f"Get assigned incidents error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to get assigned incidents: {str(e)}")

