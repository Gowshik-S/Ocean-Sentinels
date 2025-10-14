"""
Users router for Ocean Hazard API
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List

from app.database import get_db
from app.models.user import User, UserRole
from app.schemas.user import UserResponse, UserUpdate
from app.routers.auth import get_current_user, get_current_active_user

router = APIRouter()

@router.get("/me", response_model=None)
async def get_current_user_info(current_user: User = Depends(get_current_active_user)):
    """Get current user information"""
    return {
        "id": current_user.id,
        "username": current_user.username,
        "email": current_user.email,
        "first_name": current_user.first_name,
        "last_name": current_user.last_name,
        "phone": current_user.phone,
        "location": current_user.location,
        "role": current_user.role.value if hasattr(current_user.role, 'value') else str(current_user.role),
        "is_active": current_user.is_active,
        "is_verified": current_user.is_verified,
        "created_at": current_user.created_at,
        "last_login": current_user.last_login
    }

@router.put("/me", response_model=None)
async def update_current_user(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Update current user information"""
    update_data = user_update.dict(exclude_unset=True)
    
    for field, value in update_data.items():
        setattr(current_user, field, value)
    
    await db.commit()
    await db.refresh(current_user)
    
    return {
        "id": current_user.id,
        "username": current_user.username,
        "email": current_user.email,
        "first_name": current_user.first_name,
        "last_name": current_user.last_name,
        "phone": current_user.phone,
        "location": current_user.location,
        "role": current_user.role.value if hasattr(current_user.role, 'value') else str(current_user.role),
        "is_active": current_user.is_active,
        "is_verified": current_user.is_verified,
        "created_at": current_user.created_at,
        "last_login": current_user.last_login
    }

@router.get("/", response_model=None)
async def get_users(
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get all users (Admin/Authority/Rescue Team only)"""
    if current_user.role not in [UserRole.ADMIN, UserRole.AUTHORITY, UserRole.RESCUE_TEAM]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    result = await db.execute(select(User))
    users = result.scalars().all()
    
    return [
        {
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "first_name": user.first_name,
            "last_name": user.last_name,
            "phone": user.phone,
            "location": user.location,
            "role": user.role.value if hasattr(user.role, 'value') else str(user.role),
            "is_active": user.is_active,
            "is_verified": user.is_verified,
            "created_at": user.created_at,
            "last_login": user.last_login
        }
        for user in users
    ]

@router.get("/{user_id}", response_model=None)
async def get_user(
    user_id: int,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get user by ID (Admin/Authority/Rescue Team only)"""
    if current_user.role not in [UserRole.ADMIN, UserRole.AUTHORITY, UserRole.RESCUE_TEAM]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {
        "id": user.id,
        "username": user.username,
        "email": user.email,
        "first_name": user.first_name,
        "last_name": user.last_name,
        "phone": user.phone,
        "location": user.location,
        "role": user.role.value if hasattr(user.role, 'value') else str(user.role),
        "is_active": user.is_active,
        "is_verified": user.is_verified,
        "created_at": user.created_at,
        "last_login": user.last_login
    }

@router.put("/{user_id}/activate")
async def activate_user(
    user_id: int,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Activate/deactivate user (Admin only)"""
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Access denied")
    
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.is_active = not user.is_active
    await db.commit()
    
    return {"message": f"User {'activated' if user.is_active else 'deactivated'} successfully"}

@router.put("/{user_id}/reset-password")
async def reset_user_password(
    user_id: int,
    password_data: dict,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Reset user password (Admin only)"""
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Access denied")

    new_password = password_data.get("password")
    if not new_password:
        raise HTTPException(status_code=400, detail="Password is required")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Hash the new password
    from app.core.security import get_password_hash
    user.hashed_password = get_password_hash(new_password)
    await db.commit()

    return {"message": "Password reset successfully"}

# TEMPORARY ENDPOINT - Remove after use
@router.put("/reset-oceanadmin-password")
async def reset_oceanadmin_password(
    password_data: dict,
    db: AsyncSession = Depends(get_db)
):
    """TEMPORARY: Reset OceanAdmin password - Remove after use"""
    new_password = password_data.get("password", "admin")

    result = await db.execute(select(User).where(User.username == "oceanadmin"))
    user = result.scalar_one_or_none()

    if not user:
        return {"message": "OceanAdmin user not found"}

    # Hash the new password
    from app.core.security import get_password_hash
    user.hashed_password = get_password_hash(new_password)
    await db.commit()

    return {"message": f"OceanAdmin password reset to '{new_password}'"}

