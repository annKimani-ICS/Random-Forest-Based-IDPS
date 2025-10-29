from fastapi import APIRouter, Depends, HTTPException, status, Query, Request
from sqlalchemy.orm import Session
from sqlalchemy import func, desc
from datetime import datetime, timedelta
from typing import Optional, List
from uuid import UUID
from app.database import get_db
from app.models import User, Alert, Model, Threshold, BlockRule, AuditLog, UserRole, AlertStatus
from app.schemas import (
    KPIResponse, MetricsResponse, AlertResponse, AlertListResponse,
    ThresholdResponse, ThresholdUpdate, BlockRuleCreate, BlockRuleResponse,
    AlertUpdateStatus, AuditLogResponse
)
from app.auth import get_current_user, require_role

router = APIRouter(prefix="/api", tags=["dashboard"])

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

def get_current_threshold(db: Session) -> float:
    """Get current threshold value"""
    threshold = db.query(Threshold).order_by(desc(Threshold.updated_at)).first()
    return float(threshold.current_value) if threshold else 0.50

@router.get("/metrics", response_model=MetricsResponse)
async def get_metrics(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current model metrics and threshold"""
    # Get latest model
    model = db.query(Model).order_by(desc(Model.trained_at)).first()
    
    if not model:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No model found"
        )
    
    # Get current threshold
    threshold = get_current_threshold(db)
    
    return MetricsResponse(
        model_version=model.version,
        trained_at=model.trained_at,
        precision=model.metrics.get("precision", 0.0),
        recall=model.metrics.get("recall", 0.0),
        f1=model.metrics.get("f1", 0.0),
        auc=model.metrics.get("auc", 0.0),
        threshold=threshold
    )

@router.get("/kpis", response_model=KPIResponse)
async def get_kpis(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get dashboard KPI metrics"""
    # Alerts in last 24 hours
    alerts_24h = db.query(func.count(Alert.id)).filter(
        Alert.event_ts >= datetime.utcnow() - timedelta(hours=24)
    ).scalar()
    
    # Active block rules
    active_blocks = db.query(func.count(BlockRule.id)).filter(
        BlockRule.active == True
    ).scalar()
    
    # Current threshold
    threshold = get_current_threshold(db)
    
    # Latest model
    model = db.query(Model).order_by(desc(Model.trained_at)).first()
    
    return KPIResponse(
        alerts_24h=alerts_24h or 0,
        active_blocks=active_blocks or 0,
        threshold=threshold,
        model_version=model.version if model else "unknown",
        trained_at=model.trained_at if model else datetime.utcnow()
    )

@router.get("/alerts", response_model=AlertListResponse)
async def get_alerts(
    from_date: Optional[datetime] = Query(None),
    to_date: Optional[datetime] = Query(None),
    attack_type: Optional[str] = Query(None),
    status: Optional[AlertStatus] = Query(None),
    malicious: Optional[bool] = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(25, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get paginated alerts with filters"""
    query = db.query(Alert)
    
    # Apply filters
    if from_date is None and to_date is None:
        # Default to last 7 days
        from_date = datetime.utcnow() - timedelta(days=7)
    
    if from_date:
        query = query.filter(Alert.event_ts >= from_date)
    if to_date:
        query = query.filter(Alert.event_ts <= to_date)
    if attack_type:
        query = query.filter(Alert.attack_type == attack_type)
    if status:
        query = query.filter(Alert.status == status)
    if malicious is not None:
        query = query.filter(Alert.is_malicious == malicious)
    
    # Get total count
    total = query.count()
    
    # Apply pagination and ordering
    alerts = query.order_by(desc(Alert.event_ts)).offset((page - 1) * page_size).limit(page_size).all()
    
    return AlertListResponse(
        alerts=[AlertResponse(
            id=alert.id,
            event_ts=alert.event_ts,
            src_ip=str(alert.src_ip),
            dst_ip=str(alert.dst_ip),
            attack_type=alert.attack_type,
            score=float(alert.score),
            is_malicious=alert.is_malicious,
            status=alert.status,
            model_version=alert.model_version,
            payload=alert.payload
        ) for alert in alerts],
        total=total,
        page=page,
        page_size=page_size
    )

@router.patch("/alerts/{alert_id}/status")
async def update_alert_status(
    alert_id: int,
    status_data: AlertUpdateStatus,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update alert status (ACK, BLOCKED, CLOSED)"""
    alert = db.query(Alert).filter(Alert.id == alert_id).first()
    
    if not alert:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Alert not found"
        )
    
    alert.status = status_data.status
    db.commit()
    
    log_audit(db, str(current_user.id), "ALERT_STATUS_UPDATE", {
        "alert_id": alert_id,
        "new_status": status_data.status.value
    }, request.client.host)
    
    return {"message": "Alert status updated"}

@router.get("/threshold", response_model=ThresholdResponse)
async def get_threshold(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current threshold configuration"""
    threshold = db.query(Threshold).order_by(desc(Threshold.updated_at)).first()
    
    if not threshold:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No threshold configured"
        )
    
    return threshold

@router.put("/threshold")
async def update_threshold(
    threshold_data: ThresholdUpdate,
    request: Request,
    current_user: User = Depends(require_role([UserRole.ADMIN])),
    db: Session = Depends(get_db)
):
    """Update detection threshold (ADMIN only)"""
    # Create new threshold record
    new_threshold = Threshold(
        current_value=threshold_data.new_value,
        updated_by=current_user.id,
        updated_at=datetime.utcnow()
    )
    db.add(new_threshold)
    db.commit()
    
    # Update is_malicious flag for all alerts
    current_threshold = threshold_data.new_value
    db.query(Alert).update({
        Alert.is_malicious: Alert.score >= current_threshold
    }, synchronize_session=False)
    db.commit()
    
    log_audit(db, str(current_user.id), "THRESHOLD_UPDATE", {
        "old_value": get_current_threshold(db),
        "new_value": threshold_data.new_value
    }, request.client.host)
    
    return {"message": "Threshold updated", "new_value": threshold_data.new_value}

@router.get("/blocks/active", response_model=List[BlockRuleResponse])
async def get_active_blocks(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all active block rules"""
    blocks = db.query(BlockRule).filter(BlockRule.active == True).order_by(desc(BlockRule.applied_at)).all()
    
    return [BlockRuleResponse(
        id=block.id,
        applied_at=block.applied_at,
        src_ip=str(block.src_ip),
        reason=block.reason,
        active=block.active,
        created_by=block.created_by
    ) for block in blocks]

@router.post("/blocks", response_model=BlockRuleResponse, status_code=status.HTTP_201_CREATED)
async def create_block_rule(
    block_data: BlockRuleCreate,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new block rule"""
    # Check if already blocked
    existing = db.query(BlockRule).filter(
        BlockRule.src_ip == block_data.src_ip,
        BlockRule.active == True
    ).first()
    
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="IP already blocked"
        )
    
    block_rule = BlockRule(
        src_ip=block_data.src_ip,
        reason=block_data.reason,
        created_by=current_user.id
    )
    db.add(block_rule)
    db.commit()
    db.refresh(block_rule)
    
    log_audit(db, str(current_user.id), "BLOCK_CREATE", {
        "src_ip": block_data.src_ip,
        "reason": block_data.reason
    }, request.client.host)
    
    return BlockRuleResponse(
        id=block_rule.id,
        applied_at=block_rule.applied_at,
        src_ip=str(block_rule.src_ip),
        reason=block_rule.reason,
        active=block_rule.active,
        created_by=block_rule.created_by
    )

@router.patch("/blocks/{block_id}/deactivate")
async def deactivate_block_rule(
    block_id: UUID,
    request: Request,
    current_user: User = Depends(require_role([UserRole.ADMIN])),
    db: Session = Depends(get_db)
):
    """Deactivate a block rule (ADMIN only)"""
    block = db.query(BlockRule).filter(BlockRule.id == block_id).first()
    
    if not block:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Block rule not found"
        )
    
    block.active = False
    db.commit()
    
    log_audit(db, str(current_user.id), "BLOCK_DEACTIVATE", {
        "block_id": str(block_id),
        "src_ip": str(block.src_ip)
    }, request.client.host)
    
    return {"message": "Block rule deactivated"}

@router.get("/audit", response_model=List[AuditLogResponse])
async def get_audit_logs(
    from_date: Optional[datetime] = Query(None),
    to_date: Optional[datetime] = Query(None),
    action: Optional[str] = Query(None),
    user_id: Optional[UUID] = Query(None),
    limit: int = Query(100, ge=1, le=1000),
    current_user: User = Depends(require_role([UserRole.ADMIN])),
    db: Session = Depends(get_db)
):
    """Get audit logs (ADMIN only)"""
    query = db.query(AuditLog)
    
    if from_date:
        query = query.filter(AuditLog.ts >= from_date)
    if to_date:
        query = query.filter(AuditLog.ts <= to_date)
    if action:
        query = query.filter(AuditLog.action == action)
    if user_id:
        query = query.filter(AuditLog.user_id == user_id)
    
    logs = query.order_by(desc(AuditLog.ts)).limit(limit).all()
    
    return [AuditLogResponse(
        id=log.id,
        ts=log.ts,
        user_id=log.user_id,
        action=log.action,
        details=log.details,
        ip_address=log.ip_address
    ) for log in logs]

