"""
Incident schemas for Ocean Hazard API
"""

from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from app.models.incident import HazardType, UrgencyLevel, IncidentStatus

class IncidentBase(BaseModel):
    hazard_type: HazardType
    location: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    description: str
    urgency: UrgencyLevel = UrgencyLevel.LOW
    contact_info: Optional[str] = None

class IncidentCreate(IncidentBase):
    pass

class IncidentUpdate(BaseModel):
    status: Optional[IncidentStatus] = None
    description: Optional[str] = None
    urgency: Optional[UrgencyLevel] = None

class IncidentResponse(IncidentBase):
    id: int
    reference_id: str
    status: IncidentStatus
    reporter_id: int
    verified_by_id: Optional[int] = None
    photo_url: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    verified_at: Optional[datetime] = None
    resolved_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

class IncidentListResponse(BaseModel):
    incidents: list[IncidentResponse]
    total: int
    page: int
    size: int
    has_next: bool
    has_prev: bool



