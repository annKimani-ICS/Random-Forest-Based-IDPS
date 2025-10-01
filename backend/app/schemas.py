from pydantic import BaseModel, EmailStr, Field, validator
from typing import Optional, List, Dict, Any
from datetime import datetime
from uuid import UUID
from .models import UserRole, AlertStatus

# Auth Schemas
class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8)
    role: UserRole = UserRole.ANALYST

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class LoginResponse(BaseModel):
    access_token: Optional[str] = None
    refresh_token: Optional[str] = None
    token_type: str = "bearer"
    mfa_required: bool = False
    mfa_ticket: Optional[str] = None

class MFAVerifyRequest(BaseModel):
    ticket: str
    otp_code: str = Field(..., min_length=6, max_length=6)

class MFAEnrollResponse(BaseModel):
    qr_code: str
    secret: str
    provisioning_uri: str

class MFAActivateRequest(BaseModel):
    otp_code: str = Field(..., min_length=6, max_length=6)

class RefreshRequest(BaseModel):
    refresh_token: str

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

# User Schemas
class UserResponse(BaseModel):
    id: UUID
    email: str
    role: UserRole
    is_active: bool
    created_at: datetime
    last_login: Optional[datetime] = None
    mfa_enabled: bool = False
    
    class Config:
        from_attributes = True

class UserUpdate(BaseModel):
    role: Optional[UserRole] = None
    is_active: Optional[bool] = None

# Alert Schemas
class AlertResponse(BaseModel):
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

class AlertListResponse(BaseModel):
    alerts: List[AlertResponse]
    total: int
    page: int
    page_size: int

class AlertUpdateStatus(BaseModel):
    status: AlertStatus

# Model Schemas
class ModelResponse(BaseModel):
    id: UUID
    version: str
    trained_at: datetime
    metrics: Dict[str, Any]
    notes: Optional[str] = None
    
    class Config:
        from_attributes = True

# Threshold Schemas
class ThresholdResponse(BaseModel):
    id: UUID
    current_value: float
    updated_by: UUID
    updated_at: datetime
    
    class Config:
        from_attributes = True

class ThresholdUpdate(BaseModel):
    new_value: float = Field(..., ge=0.0, le=1.0)

# Block Rule Schemas
class BlockRuleCreate(BaseModel):
    src_ip: str
    reason: Optional[str] = None

class BlockRuleResponse(BaseModel):
    id: UUID
    applied_at: datetime
    src_ip: str
    reason: Optional[str]
    active: bool
    created_by: UUID
    
    class Config:
        from_attributes = True

# KPI Schemas
class KPIResponse(BaseModel):
    alerts_24h: int
    active_blocks: int
    threshold: float
    model_version: str
    trained_at: datetime

# Metrics Schemas
class MetricsResponse(BaseModel):
    model_version: str
    trained_at: datetime
    precision: float
    recall: float
    f1: float
    auc: float
    threshold: float

# Audit Log Schemas
class AuditLogResponse(BaseModel):
    id: int
    ts: datetime
    user_id: Optional[UUID]
    action: str
    details: Optional[Dict[str, Any]]
    ip_address: Optional[str]
    
    class Config:
        from_attributes = True

