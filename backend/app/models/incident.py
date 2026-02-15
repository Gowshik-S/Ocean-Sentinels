"""
Incident model for Ocean Hazard API
"""

from sqlalchemy import Column, Integer, String, DateTime, Boolean, Text, Float, ForeignKey, Enum
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum
from app.database import Base

class IncidentStatus(str, enum.Enum):
    PENDING = "PENDING"
    VERIFIED = "VERIFIED"
    IN_PROGRESS = "IN_PROGRESS"
    RESOLVED = "RESOLVED"
    FALSE_ALARM = "FALSE_ALARM"

class HazardType(str, enum.Enum):
    HIGH_WAVES = "HIGH_WAVES"
    FLOODING = "FLOODING"
    TSUNAMI = "TSUNAMI"
    LOST_VESSEL = "LOST_VESSEL"
    DEBRIS = "DEBRIS"
    OIL_SPILL = "OIL_SPILL"
    OTHER = "OTHER"

class UrgencyLevel(str, enum.Enum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"
    CRITICAL = "CRITICAL"

class Incident(Base):
    __tablename__ = "incidents"
    
    id = Column(Integer, primary_key=True, index=True)
    reference_id = Column(String(50), unique=True, index=True, nullable=False)
    hazard_type = Column(Enum(HazardType), nullable=False)
    location = Column(String(255), nullable=False)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    description = Column(Text, nullable=False)
    urgency = Column(Enum(UrgencyLevel), default=UrgencyLevel.LOW, nullable=False)
    status = Column(Enum(IncidentStatus), default=IncidentStatus.PENDING, nullable=False)
    contact_info = Column(String(100), nullable=True)
    photo_url = Column(String(500), nullable=True)
    
    # Mesh deduplication — unique ID from BLE mesh origin device
    mesh_message_id = Column(String(128), nullable=True, unique=True, index=True)
    
    # Foreign keys
    reporter_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    verified_by_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    assigned_to_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    verified_at = Column(DateTime(timezone=True), nullable=True)
    resolved_at = Column(DateTime(timezone=True), nullable=True)
    assigned_at = Column(DateTime(timezone=True), nullable=True)
    
    # Relationships (commented out to avoid circular imports)
    # reporter = relationship("User", back_populates="incidents", foreign_keys=[reporter_id])
    # verified_by = relationship("User", back_populates="verified_incidents", foreign_keys=[verified_by_id])
    
    def __repr__(self):
        return f"<Incident(id={self.id}, reference_id='{self.reference_id}', status='{self.status}')>"

