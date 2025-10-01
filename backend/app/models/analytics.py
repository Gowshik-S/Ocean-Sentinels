"""
Analytics models for Ocean Hazard API
"""

from sqlalchemy import Column, Integer, String, DateTime, Float, Text, Boolean
from sqlalchemy.sql import func
from app.database import Base

class AnalyticsSnapshot(Base):
    __tablename__ = "analytics_snapshots"
    
    id = Column(Integer, primary_key=True, index=True)
    date = Column(DateTime(timezone=True), nullable=False, index=True)
    total_incidents = Column(Integer, default=0)
    active_incidents = Column(Integer, default=0)
    resolved_incidents = Column(Integer, default=0)
    false_alarms = Column(Integer, default=0)
    average_response_time_hours = Column(Float, default=0.0)
    incidents_by_type = Column(Text, nullable=True)  # JSON string
    incidents_by_region = Column(Text, nullable=True)  # JSON string
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    def __repr__(self):
        return f"<AnalyticsSnapshot(id={self.id}, date='{self.date}', total_incidents={self.total_incidents})>"

class SystemMetrics(Base):
    __tablename__ = "system_metrics"
    
    id = Column(Integer, primary_key=True, index=True)
    metric_name = Column(String(100), nullable=False, index=True)
    metric_value = Column(Float, nullable=False)
    metric_unit = Column(String(20), nullable=True)
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    def __repr__(self):
        return f"<SystemMetrics(id={self.id}, name='{self.metric_name}', value={self.metric_value})>"



