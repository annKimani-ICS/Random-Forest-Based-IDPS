from sqlalchemy import Column, String, Boolean, DateTime, Enum, Text, ARRAY, UUID, BigInteger, ForeignKey, Numeric, Integer, func, select
from sqlalchemy.dialects.postgresql import INET, JSONB
from sqlalchemy.orm import relationship
from datetime import datetime
import uuid
import enum
from .database import Base

class UserRole(str, enum.Enum):
    ADMIN = "ADMIN"
    ANALYST = "ANALYST"

class AlertStatus(str, enum.Enum):
    NEW = "NEW"
    ACK = "ACK"
    BLOCKED = "BLOCKED"
    CLOSED = "CLOSED"

class User(Base):
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(120), unique=True, nullable=False, index=True)
    password_hash = Column(Text, nullable=False)
    role = Column(Enum(UserRole), default=UserRole.ANALYST, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    last_login = Column(DateTime, nullable=True)
    failed_login_attempts = Column(Integer, default=0, nullable=False)
    locked_until = Column(DateTime, nullable=True)
    
    # Relationships
    mfa = relationship("UserMFA", back_populates="user", uselist=False, cascade="all, delete-orphan")
    refresh_tokens = relationship("RefreshToken", back_populates="user", cascade="all, delete-orphan")
    threshold_updates = relationship("Threshold", back_populates="updated_by_user")
    block_rules = relationship("BlockRule", back_populates="created_by_user")
    audit_logs = relationship("AuditLog", back_populates="user")

class UserMFA(Base):
    __tablename__ = "user_mfa"
    
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    totp_secret_base32 = Column(Text, nullable=True)
    is_enabled = Column(Boolean, default=False, nullable=False)
    recovery_codes = Column(ARRAY(Text), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Relationships
    user = relationship("User", back_populates="mfa")

class RefreshToken(Base):
    __tablename__ = "refresh_tokens"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    token_hash = Column(Text, nullable=False, unique=True, index=True)
    expires_at = Column(DateTime, nullable=False)
    revoked = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Relationships
    user = relationship("User", back_populates="refresh_tokens")

class Model(Base):
    __tablename__ = "models"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    version = Column(String(40), unique=True, nullable=False)
    trained_at = Column(DateTime, nullable=False)
    metrics = Column(JSONB, nullable=False)
    notes = Column(Text, nullable=True)

class Threshold(Base):
    __tablename__ = "thresholds"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    current_value = Column(Numeric(4, 2), nullable=False)
    updated_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Relationships
    updated_by_user = relationship("User", back_populates="threshold_updates")

class Alert(Base):
    __tablename__ = "alerts"
    
    id = Column(BigInteger, primary_key=True, autoincrement=True)
    event_ts = Column(DateTime, nullable=False, index=True)
    src_ip = Column(INET, nullable=False, index=True)
    dst_ip = Column(INET, nullable=False)
    attack_type = Column(String(50), nullable=False, index=True)
    score = Column(Numeric(5, 4), nullable=False)
    is_malicious = Column(Boolean, nullable=False)  # Computed in application logic
    status = Column(Enum(AlertStatus), default=AlertStatus.NEW, nullable=False, index=True)
    model_version = Column(String(40), nullable=False)
    payload = Column(JSONB, nullable=True)

class BlockRule(Base):
    __tablename__ = "block_rules"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    applied_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    src_ip = Column(INET, nullable=False, index=True)
    reason = Column(Text, nullable=True)
    active = Column(Boolean, default=True, nullable=False, index=True)
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    
    # Relationships
    created_by_user = relationship("User", back_populates="block_rules")

class AuditLog(Base):
    __tablename__ = "audit_logs"
    
    id = Column(BigInteger, primary_key=True, autoincrement=True)
    ts = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    action = Column(String(60), nullable=False, index=True)
    details = Column(JSONB, nullable=True)
    ip_address = Column(String(45), nullable=True)
    
    # Relationships
    user = relationship("User", back_populates="audit_logs")

