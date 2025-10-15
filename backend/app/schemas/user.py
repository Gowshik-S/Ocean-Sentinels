"""
User schemas for Ocean Hazard API
"""

from pydantic import BaseModel, EmailStr, validator
from typing import Optional
from datetime import datetime
from app.models.user import UserRole

class UserBase(BaseModel):
    username: str
    email: EmailStr
    first_name: str
    last_name: str
    phone: Optional[str] = None
    location: Optional[str] = None

    @validator('username', 'first_name', 'last_name', 'phone', 'location', pre=True)
    def strip_whitespace(cls, v):
        """Strip leading and trailing whitespace from string fields"""
        if isinstance(v, str):
            return v.strip()
        return v

class UserCreate(UserBase):
    password: str
    role: Optional[UserRole] = UserRole.PUBLIC

    @validator('password')
    def validate_password(cls, v):
        """Validate password strength"""
        if len(v) < 6:
            raise ValueError('Password must be at least 6 characters long')
        return v

class UserUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    phone: Optional[str] = None
    location: Optional[str] = None
    is_active: Optional[bool] = None

class UserResponse(UserBase):
    id: int
    role: str
    is_active: bool
    is_verified: bool
    created_at: datetime
    last_login: Optional[datetime] = None
    
    class Config:
        from_attributes = True

class UserLogin(BaseModel):
    username: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse

class TokenData(BaseModel):
    username: Optional[str] = None



