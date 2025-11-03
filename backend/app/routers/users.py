from fastapi import APIRouter, Depends, HTTPException, status, Query, Request
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID
from app.database import get_db
from app.models import User, UserMFA, UserRole, AuditLog
from app.schemas import UserCreate, UserResponse, UserUpdate
from app.auth import hash_password, require_role, get_current_user
from datetime import datetime

router = APIRouter(prefix="/users", tags=["users"])

def log_audit(db: Session, user_id: str, action: str, details: dict = None, ip_address: str = None):
    """Helper to log audit events"""
    audit_log = AuditLog(
        user_id=user_id,
        action=action,
        details=details,
        ip_address=ip_address
    )
    db.add(audit_log)
    db.commit()

@router.post("", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    user_data: UserCreate,
    request: Request,
    current_user: User = Depends(require_role([UserRole.ADMIN])),
    db: Session = Depends(get_db)
):
    """Create a new user (ADMIN only)"""
    # Check if user exists
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Create user
    user = User(
        email=user_data.email,
        password_hash=hash_password(user_data.password),
        role=user_data.role
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    
    # Create empty MFA record
    user_mfa = UserMFA(user_id=user.id)
    db.add(user_mfa)
    db.commit()
    
    log_audit(db, str(current_user.id), "USER_CREATE", {
        "created_user_email": user.email,
        "role": user.role.value
    }, request.client.host)
    
    return UserResponse(
        id=user.id,
        email=user.email,
        role=user.role,
        is_active=user.is_active,
        created_at=user.created_at,
        last_login=user.last_login,
        mfa_enabled=False
    )

@router.get("", response_model=List[UserResponse])
async def list_users(
    query: Optional[str] = Query(None),
    current_user: User = Depends(require_role([UserRole.ADMIN])),
    db: Session = Depends(get_db)
):
    """List all users (ADMIN only)"""
    users_query = db.query(User)
    
    if query:
        users_query = users_query.filter(User.email.ilike(f"%{query}%"))
    
    users = users_query.all()
    
    # Get MFA status for each user
    result = []
    for user in users:
        user_mfa = db.query(UserMFA).filter(UserMFA.user_id == user.id).first()
        result.append(UserResponse(
            id=user.id,
            email=user.email,
            role=user.role,
            is_active=user.is_active,
            created_at=user.created_at,
            last_login=user.last_login,
            mfa_enabled=user_mfa.is_enabled if user_mfa else False
        ))
    
    return result

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: UUID,
    current_user: User = Depends(require_role([UserRole.ADMIN])),
    db: Session = Depends(get_db)
):
    """Get user by ID (ADMIN only)"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    user_mfa = db.query(UserMFA).filter(UserMFA.user_id == user.id).first()
    
    return UserResponse(
        id=user.id,
        email=user.email,
        role=user.role,
        is_active=user.is_active,
        created_at=user.created_at,
        last_login=user.last_login,
        mfa_enabled=user_mfa.is_enabled if user_mfa else False
    )

@router.patch("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: UUID,
    user_data: UserUpdate,
    request: Request,
    current_user: User = Depends(require_role([UserRole.ADMIN])),
    db: Session = Depends(get_db)
):
    """Update user (ADMIN only)"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Update fields
    update_details = {}
    if user_data.role is not None:
        user.role = user_data.role
        update_details["role"] = user_data.role.value
    if user_data.is_active is not None:
        user.is_active = user_data.is_active
        update_details["is_active"] = user_data.is_active
    
    db.commit()
    db.refresh(user)
    
    log_audit(db, str(current_user.id), "USER_UPDATE", {
        "updated_user_id": str(user_id),
        "changes": update_details
    }, request.client.host)
    
    user_mfa = db.query(UserMFA).filter(UserMFA.user_id == user.id).first()
    
    return UserResponse(
        id=user.id,
        email=user.email,
        role=user.role,
        is_active=user.is_active,
        created_at=user.created_at,
        last_login=user.last_login,
        mfa_enabled=user_mfa.is_enabled if user_mfa else False
    )

@router.post("/{user_id}/reset-password")
async def reset_user_password(
    user_id: UUID,
    new_password: str,
    request: Request,
    current_user: User = Depends(require_role([UserRole.ADMIN])),
    db: Session = Depends(get_db)
):
    """Reset user password (ADMIN only)"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    user.password_hash = hash_password(new_password)
    user.failed_login_attempts = 0
    user.locked_until = None
    db.commit()
    
    log_audit(db, str(current_user.id), "PASSWORD_RESET", {
        "target_user_id": str(user_id)
    }, request.client.host)
    
    return {"message": "Password reset successfully"}


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(
    user_id: UUID,
    request: Request,
    current_user: User = Depends(require_role([UserRole.ADMIN])),
    db: Session = Depends(get_db)
):
    """Delete a user (ADMIN only)
    - Prevent deleting self
    - Prevent deleting the last remaining ADMIN
    """
    user = db.query(User).filter(User.id == user_id).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    # Prevent self-delete
    if user.id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Admins cannot delete their own account"
        )

    # If target is ADMIN, ensure not the last admin
    if user.role == UserRole.ADMIN:
        admin_count = db.query(User).filter(User.role == UserRole.ADMIN, User.is_active == True).count()
        if admin_count <= 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot delete the last remaining admin"
            )

    db.delete(user)
    db.commit()

    log_audit(db, str(current_user.id), "USER_DELETE", {
        "deleted_user_id": str(user_id),
        "deleted_user_email": user.email,
        "deleted_user_role": user.role.value,
    }, request.client.host)

    return

