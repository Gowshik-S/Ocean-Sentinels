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

class UserVisit(Base):
    __tablename__ = "user_visits"

    id = Column(Integer, primary_key=True, index=True)
    ip_address = Column(String(45), nullable=False, index=True)  # IPv4/IPv6 support
    user_agent = Column(Text, nullable=True)
    country = Column(String(100), nullable=True)
    city = Column(String(100), nullable=True)
    region = Column(String(100), nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    timezone = Column(String(50), nullable=True)
    language = Column(String(10), nullable=True)
    referrer = Column(Text, nullable=True)
    page_url = Column(Text, nullable=True)
    session_id = Column(String(100), nullable=True, index=True)
    user_id = Column(Integer, nullable=True, index=True)  # If user is logged in
    visit_duration = Column(Integer, nullable=True)  # in seconds
    device_type = Column(String(20), nullable=True)  # desktop, mobile, tablet
    browser = Column(String(50), nullable=True)
    os = Column(String(50), nullable=True)
    is_bot = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)

    def __repr__(self):
        return f"<UserVisit(id={self.id}, ip='{self.ip_address}', country='{self.country}', created_at='{self.created_at}')>"

class WebsiteStats(Base):
    __tablename__ = "website_stats"

    id = Column(Integer, primary_key=True, index=True)
    date = Column(DateTime(timezone=True), nullable=False, index=True)
    total_visits = Column(Integer, default=0)
    unique_visitors = Column(Integer, default=0)
    page_views = Column(Integer, default=0)
    bounce_rate = Column(Float, default=0.0)
    avg_session_duration = Column(Float, default=0.0)  # in seconds
    top_countries = Column(Text, nullable=True)  # JSON string
    top_pages = Column(Text, nullable=True)  # JSON string
    device_breakdown = Column(Text, nullable=True)  # JSON string
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    def __repr__(self):
        return f"<WebsiteStats(id={self.id}, date='{self.date}', total_visits={self.total_visits})>"



