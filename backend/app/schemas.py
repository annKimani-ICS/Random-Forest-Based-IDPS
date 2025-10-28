from pydantic import BaseModel, EmailStr, Field, validator
from typing import Optional, List, Dict, Any
from datetime import datetime
from uuid import UUID
from .models import UserRole, AlertStatus


# NOTE: Pydantic v2 reserves the prefix "model_" for internal use. Our
# schemas legitimately use a field named `model_version`, which triggers a
# warning at app startup. To suppress this harmless warning globally for our
# API schemas, we define a project-specific base model that disables
# protected namespaces. All API schema classes should inherit from this base.
class AppBaseModel(BaseModel):
    model_config = {"protected_namespaces": ()}

# Auth Schemas
class UserCreate(AppBaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8)
    role: UserRole = UserRole.ANALYST

class LoginRequest(AppBaseModel):
    email: EmailStr
    password: str

class LoginResponse(AppBaseModel):
    access_token: Optional[str] = None
    refresh_token: Optional[str] = None
    token_type: str = "bearer"
    mfa_required: bool = False
    mfa_ticket: Optional[str] = None

class MFAVerifyRequest(AppBaseModel):
    ticket: str
    otp_code: str = Field(..., min_length=6, max_length=6)

class MFAEnrollResponse(AppBaseModel):
    qr_code: str
    secret: str
    provisioning_uri: str

class MFAActivateRequest(AppBaseModel):
    otp_code: str = Field(..., min_length=6, max_length=6)

class RefreshRequest(AppBaseModel):
    refresh_token: str

class TokenResponse(AppBaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

# User Schemas
class UserResponse(AppBaseModel):
    id: UUID
    email: str
    role: UserRole
    is_active: bool
    created_at: datetime
    last_login: Optional[datetime] = None
    mfa_enabled: bool = False
    
    class Config:
        from_attributes = True

class UserUpdate(AppBaseModel):
    role: Optional[UserRole] = None
    is_active: Optional[bool] = None

# Alert Schemas
class AlertResponse(AppBaseModel):
    id: int
    event_ts: datetime
    src_ip: str
    dst_ip: str
    attack_type: str
    score: float
    is_malicious: bool
    status: AlertStatus
    model_version: str
    payload: Optional[Dict[str, Any]] = None
    
    class Config:
        from_attributes = True

class AlertListResponse(AppBaseModel):
    alerts: List[AlertResponse]
    total: int
    page: int
    page_size: int

class AlertUpdateStatus(AppBaseModel):
    status: AlertStatus

# Model Schemas
class ModelResponse(AppBaseModel):
    id: UUID
    version: str
    trained_at: datetime
    metrics: Dict[str, Any]
    notes: Optional[str] = None
    
    class Config:
        from_attributes = True

# Threshold Schemas
class ThresholdResponse(AppBaseModel):
    id: UUID
    current_value: float
    updated_by: UUID
    updated_at: datetime
    
    class Config:
        from_attributes = True

class ThresholdUpdate(AppBaseModel):
    new_value: float = Field(..., ge=0.0, le=1.0)

# Block Rule Schemas
class BlockRuleCreate(AppBaseModel):
    src_ip: str
    reason: Optional[str] = None

class BlockRuleResponse(AppBaseModel):
    id: UUID
    applied_at: datetime
    src_ip: str
    reason: Optional[str]
    active: bool
    created_by: UUID
    
    class Config:
        from_attributes = True

# KPI Schemas
class KPIResponse(AppBaseModel):
    alerts_24h: int
    active_blocks: int
    threshold: float
    model_version: str
    trained_at: datetime

# Metrics Schemas
class MetricsResponse(AppBaseModel):
    model_version: str
    trained_at: datetime
    precision: float
    recall: float
    f1: float
    auc: float
    threshold: float

# Audit Log Schemas
class AuditLogResponse(AppBaseModel):
    id: int
    ts: datetime
    user_id: Optional[UUID]
    action: str
    details: Optional[Dict[str, Any]]
    ip_address: Optional[str]
    
    class Config:
        from_attributes = True

