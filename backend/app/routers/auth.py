from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from typing import Optional
from ..database import get_db
from ..models import User, UserMFA, AuditLog, UserRole
from ..schemas import (
    UserCreate, LoginRequest, LoginResponse, MFAVerifyRequest,
    MFAEnrollResponse, MFAActivateRequest, RefreshRequest, TokenResponse, UserResponse
)
from ..auth import (
    hash_password, verify_password, create_access_token, create_refresh_token,
    create_mfa_ticket, verify_token, get_current_user, verify_refresh_token,
    revoke_refresh_token
)
from ..totp import generate_totp_secret, get_totp_uri, generate_qr_code, verify_totp, generate_recovery_codes
from ..config import settings

router = APIRouter(prefix="/auth", tags=["authentication"])

def log_audit(db: Session, user_id: Optional[str], action: str, details: dict = None, ip_address: str = None):
    """Helper to log audit events"""
    audit_log = AuditLog(
        user_id=user_id,
        action=action,
        details=details,
        ip_address=ip_address
    )
    db.add(audit_log)
    db.commit()

def check_lockout(user: User) -> bool:
    """Check if user is locked out"""
    if user.locked_until and user.locked_until > datetime.utcnow():
        return True
    return False

def handle_failed_login(user: User, db: Session):
    """Handle failed login attempt"""
    user.failed_login_attempts += 1
    if user.failed_login_attempts >= settings.MAX_LOGIN_ATTEMPTS:
        user.locked_until = datetime.utcnow() + timedelta(minutes=settings.LOCKOUT_DURATION_MINUTES)
    db.commit()

def reset_failed_attempts(user: User, db: Session):
    """Reset failed login attempts"""
    user.failed_login_attempts = 0
    user.locked_until = None
    user.last_login = datetime.utcnow()
    db.commit()

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(
    user_data: UserCreate,
    request: Request,
    db: Session = Depends(get_db)
):
    """Public user registration (defaults to ANALYST role)"""
    # Check if user exists
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Create user with ANALYST role (ignore role from request for security)
    user = User(
        email=user_data.email,
        password_hash=hash_password(user_data.password),
        role=UserRole.ANALYST  # Force ANALYST for public signup
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    
    # Create empty MFA record
    user_mfa = UserMFA(user_id=user.id)
    db.add(user_mfa)
    db.commit()
    
    log_audit(db, str(user.id), "USER_REGISTER", {"email": user.email}, request.client.host)
    
    return UserResponse(
        id=user.id,
        email=user.email,
        role=user.role,
        is_active=user.is_active,
        created_at=user.created_at,
        last_login=user.last_login,
        mfa_enabled=False
    )

@router.post("/login", response_model=LoginResponse)
async def login(
    login_data: LoginRequest,
    request: Request,
    db: Session = Depends(get_db)
):
    """Authenticate user with email and password"""
    user = db.query(User).filter(User.email == login_data.email).first()
    
    if not user or not user.is_active:
        log_audit(db, None, "LOGIN_FAIL", {"email": login_data.email, "reason": "user_not_found"}, request.client.host)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    # Check lockout
    if check_lockout(user):
        log_audit(db, str(user.id), "LOGIN_FAIL", {"reason": "account_locked"}, request.client.host)
        raise HTTPException(
            status_code=status.HTTP_423_LOCKED,
            detail=f"Account locked due to too many failed attempts. Try again later."
        )
    
    # Verify password
    if not verify_password(login_data.password, user.password_hash):
        handle_failed_login(user, db)
        log_audit(db, str(user.id), "LOGIN_FAIL", {"reason": "invalid_password"}, request.client.host)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    # Check if MFA is enabled
    user_mfa = db.query(UserMFA).filter(UserMFA.user_id == user.id).first()
    
    if user_mfa and user_mfa.is_enabled:
        # MFA required - issue ticket
        ticket = create_mfa_ticket(str(user.id))
        log_audit(db, str(user.id), "LOGIN_MFA_REQUIRED", None, request.client.host)
        return LoginResponse(
            mfa_required=True,
            mfa_ticket=ticket
        )
    
    # No MFA - issue tokens directly
    reset_failed_attempts(user, db)
    access_token = create_access_token(data={"sub": str(user.id), "role": user.role.value})
    refresh_token = create_refresh_token(str(user.id), db)
    
    log_audit(db, str(user.id), "LOGIN_SUCCESS", None, request.client.host)
    
    return LoginResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        mfa_required=False
    )

@router.post("/mfa/verify", response_model=TokenResponse)
async def verify_mfa(
    mfa_data: MFAVerifyRequest,
    request: Request,
    db: Session = Depends(get_db)
):
    """Verify MFA code and issue tokens"""
    try:
        payload = verify_token(mfa_data.ticket)
        if payload.get("type") != "mfa_ticket":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid MFA ticket"
            )
        
        user_id = payload.get("sub")
        user = db.query(User).filter(User.id == user_id).first()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found"
            )
        
        user_mfa = db.query(UserMFA).filter(UserMFA.user_id == user.id).first()
        
        if not user_mfa or not user_mfa.is_enabled or not user_mfa.totp_secret_base32:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="MFA not properly configured"
            )
        
        # Verify TOTP code
        if not verify_totp(user_mfa.totp_secret_base32, mfa_data.otp_code):
            log_audit(db, str(user.id), "MFA_VERIFY_FAIL", None, request.client.host)
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid MFA code"
            )
        
        # Success - issue tokens
        reset_failed_attempts(user, db)
        access_token = create_access_token(data={"sub": str(user.id), "role": user.role.value})
        refresh_token = create_refresh_token(str(user.id), db)
        
        log_audit(db, str(user.id), "MFA_VERIFY_SUCCESS", None, request.client.host)
        
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token
        )
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired MFA ticket"
        )

@router.post("/mfa/enroll", response_model=MFAEnrollResponse)
async def enroll_mfa(
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Generate TOTP secret and QR code for enrollment"""
    # Generate new secret
    secret = generate_totp_secret()
    
    # Get or create MFA record
    user_mfa = db.query(UserMFA).filter(UserMFA.user_id == current_user.id).first()
    if not user_mfa:
        user_mfa = UserMFA(user_id=current_user.id)
        db.add(user_mfa)
    
    # Store secret temporarily (not enabled yet)
    user_mfa.totp_secret_base32 = secret
    db.commit()
    
    # Generate QR code
    uri = get_totp_uri(secret, current_user.email, settings.ISSUER)
    qr_code = generate_qr_code(uri)
    
    log_audit(db, str(current_user.id), "MFA_ENROLL_START", None, request.client.host)
    
    return MFAEnrollResponse(
        qr_code=qr_code,
        secret=secret,
        provisioning_uri=uri
    )

@router.post("/mfa/activate")
async def activate_mfa(
    mfa_data: MFAActivateRequest,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Activate MFA after verifying the first code"""
    user_mfa = db.query(UserMFA).filter(UserMFA.user_id == current_user.id).first()
    
    if not user_mfa or not user_mfa.totp_secret_base32:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="MFA enrollment not started"
        )
    
    # Verify the code
    if not verify_totp(user_mfa.totp_secret_base32, mfa_data.otp_code):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid MFA code"
        )
    
    # Enable MFA
    user_mfa.is_enabled = True
    user_mfa.recovery_codes = generate_recovery_codes()
    user_mfa.updated_at = datetime.utcnow()
    db.commit()
    
    log_audit(db, str(current_user.id), "MFA_ACTIVATED", None, request.client.host)
    
    return {
        "message": "MFA activated successfully",
        "recovery_codes": user_mfa.recovery_codes
    }

@router.post("/refresh", response_model=TokenResponse)
async def refresh_tokens(
    refresh_data: RefreshRequest,
    db: Session = Depends(get_db)
):
    """Refresh access token using refresh token"""
    user = verify_refresh_token(refresh_data.refresh_token, db)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token"
        )
    
    # Revoke old refresh token
    revoke_refresh_token(refresh_data.refresh_token, db)
    
    # Issue new tokens
    access_token = create_access_token(data={"sub": str(user.id), "role": user.role.value})
    refresh_token = create_refresh_token(str(user.id), db)
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token
    )

@router.post("/logout")
async def logout(
    refresh_data: RefreshRequest,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Logout user by revoking refresh token"""
    revoke_refresh_token(refresh_data.refresh_token, db)
    log_audit(db, str(current_user.id), "LOGOUT", None, request.client.host)
    
    return {"message": "Logged out successfully"}

@router.get("/me", response_model=UserResponse)
async def get_current_user_info(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current user information"""
    user_mfa = db.query(UserMFA).filter(UserMFA.user_id == current_user.id).first()
    
    return UserResponse(
        id=current_user.id,
        email=current_user.email,
        role=current_user.role,
        is_active=current_user.is_active,
        created_at=current_user.created_at,
        last_login=current_user.last_login,
        mfa_enabled=user_mfa.is_enabled if user_mfa else False
    )

