"""
API endpoints for traffic monitoring control
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User
from app.auth import get_current_user, require_role, UserRole
from app.traffic_monitor import TrafficMonitor
from typing import Optional

router = APIRouter(prefix="/api/monitor", tags=["monitor"])

# Global monitor instance
_monitor_instance: Optional[TrafficMonitor] = None

@router.post("/start")
async def start_monitoring(
    interface: Optional[str] = None,
    threshold: float = 0.50,
    current_user: User = Depends(require_role([UserRole.ADMIN])),
    db: Session = Depends(get_db)
):
    """
    Start traffic monitoring (ADMIN only)
    
    Args:
        interface: Network interface name (e.g., eth0, enp0s3). Auto-detected if None.
        threshold: Detection threshold (0.0-1.0). Default 0.50.
    """
    global _monitor_instance
    
    if _monitor_instance and _monitor_instance.is_monitoring:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Monitoring is already active"
        )
    
    try:
        _monitor_instance = TrafficMonitor(interface=interface, threshold=threshold)
        _monitor_instance.start_monitoring_async()
        
        return {
            "message": "Monitoring started",
            "interface": _monitor_instance.interface,
            "threshold": threshold
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to start monitoring: {str(e)}"
        )

@router.post("/stop")
async def stop_monitoring(
    current_user: User = Depends(require_role([UserRole.ADMIN])),
    db: Session = Depends(get_db)
):
    """Stop traffic monitoring (ADMIN only)"""
    global _monitor_instance
    
    if not _monitor_instance or not _monitor_instance.is_monitoring:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Monitoring is not active"
        )
    
    try:
        _monitor_instance.stop_monitoring()
        return {"message": "Monitoring stopped"}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to stop monitoring: {str(e)}"
        )

@router.get("/status")
async def get_monitoring_status(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current monitoring status"""
    global _monitor_instance
    
    if not _monitor_instance:
        return {
            "is_monitoring": False,
            "interface": None,
            "threshold": None
        }
    
    return {
        "is_monitoring": _monitor_instance.is_monitoring,
        "interface": _monitor_instance.interface,
        "threshold": _monitor_instance.threshold
    }

