"""
API endpoints for traffic monitoring control
"""
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session
from typing import Optional

from app.database import get_db
from app.models import User
from app.auth import get_current_user, require_role, UserRole
from app.traffic_monitor import TrafficMonitor

router = APIRouter(prefix="/api/monitor", tags=["monitor"])

# Global monitor instance
_monitor_instance: Optional[TrafficMonitor] = None


class StartMonitoringRequest(BaseModel):
    interface: Optional[str] = None
    threshold: float = 0.50

@router.post("/start")
async def start_monitoring(
    request: StartMonitoringRequest,
    current_user: User = Depends(require_role([UserRole.ADMIN])),
    db: Session = Depends(get_db)
):
    """
    Start traffic monitoring (ADMIN only)
    
    Request body:
        interface: Network interface name (e.g., eth0, enp0s3). Auto-detected if None.
        threshold: Detection threshold (0.0-1.0). Default 0.50.
    """
    global _monitor_instance
    
    interface = request.interface
    threshold = request.threshold
    
    if _monitor_instance and _monitor_instance.is_monitoring:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Monitoring is already active"
        )
    
    try:
        print(f"[API] Creating TrafficMonitor instance with interface={interface}, threshold={threshold}")
        _monitor_instance = TrafficMonitor(interface=interface, threshold=threshold)
        print(f"[API] TrafficMonitor created, starting async monitoring...")
        
        result = _monitor_instance.start_monitoring_async()
        print(f"[API] start_monitoring_async() returned: {result}")
        print(f"[API] After async start, is_monitoring = {_monitor_instance.is_monitoring}")
        
        return {
            "message": "Monitoring started",
            "interface": _monitor_instance.interface,
            "threshold": threshold,
            "is_monitoring": _monitor_instance.is_monitoring  # Include status in response
        }
    except Exception as e:
        print(f"[API] ERROR starting monitoring: {e}")
        import traceback
        traceback.print_exc()
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

