"""
API Client for IDS/IDPS Desktop Application
"""
import requests
from typing import Optional, Dict, Any
import json


class APIClient:
    def __init__(self, base_url: str = "http://localhost:8000", timeout_seconds: int = 10):
        self.base_url = base_url
        self.access_token: Optional[str] = None
        self.refresh_token: Optional[str] = None
        self.session = requests.Session()
        self.timeout = timeout_seconds
    
    def _get_headers(self) -> Dict[str, str]:
        headers = {"Content-Type": "application/json"}
        if self.access_token:
            headers["Authorization"] = f"Bearer {self.access_token}"
        return headers
    
    def _handle_response(self, response: requests.Response) -> Dict[str, Any]:
        """Handle API response and raise errors if needed"""
        try:
            data = response.json()
        except:
            data = {"detail": response.text}
        
        if response.status_code >= 400:
            raise Exception(data.get("detail", f"HTTP {response.status_code}"))
        
        return data
    
    # Authentication
    def login(self, email: str, password: str) -> Dict[str, Any]:
        """Login with email and password"""
        response = self.session.post(
            f"{self.base_url}/auth/login",
            json={"email": email, "password": password},
            timeout=self.timeout
        )
        data = self._handle_response(response)
        
        if not data.get("mfa_required"):
            self.access_token = data.get("access_token")
            self.refresh_token = data.get("refresh_token")
        
        return data
    
    def verify_mfa(self, ticket: str, otp_code: str) -> Dict[str, Any]:
        """Verify MFA code"""
        response = self.session.post(
            f"{self.base_url}/auth/mfa/verify",
            json={"ticket": ticket, "otp_code": otp_code},
            timeout=self.timeout
        )
        data = self._handle_response(response)
        
        self.access_token = data.get("access_token")
        self.refresh_token = data.get("refresh_token")
        
        return data
    
    def get_current_user(self) -> Dict[str, Any]:
        """Get current user info"""
        response = self.session.get(
            f"{self.base_url}/auth/me",
            headers=self._get_headers(),
            timeout=self.timeout
        )
        return self._handle_response(response)
    
    def logout(self):
        """Logout and clear all session data"""
        if self.refresh_token:
            try:
                self.session.post(
                    f"{self.base_url}/auth/logout",
                    json={"refresh_token": self.refresh_token},
                    headers=self._get_headers(),
                    timeout=self.timeout
                )
            except:
                pass
        
        # Clear tokens
        self.access_token = None
        self.refresh_token = None
        
        # Clear all cookies and session data
        self.session.cookies.clear()
        # Create a new session to ensure it's completely fresh
        self.session = requests.Session()
    
    # MFA Enrollment
    def enroll_mfa(self) -> Dict[str, Any]:
        """Start MFA enrollment"""
        response = self.session.post(
            f"{self.base_url}/auth/mfa/enroll",
            headers=self._get_headers(),
            timeout=self.timeout
        )
        return self._handle_response(response)
    
    def activate_mfa(self, otp_code: str) -> Dict[str, Any]:
        """Activate MFA"""
        response = self.session.post(
            f"{self.base_url}/auth/mfa/activate",
            json={"otp_code": otp_code},
            headers=self._get_headers(),
            timeout=self.timeout
        )
        return self._handle_response(response)
    
    # Dashboard APIs
    def get_metrics(self) -> Dict[str, Any]:
        """Get model metrics"""
        response = self.session.get(
            f"{self.base_url}/api/metrics",
            headers=self._get_headers(),
            timeout=self.timeout
        )
        return self._handle_response(response)
    
    def get_kpis(self) -> Dict[str, Any]:
        """Get dashboard KPIs"""
        response = self.session.get(
            f"{self.base_url}/api/kpis",
            headers=self._get_headers(),
            timeout=self.timeout
        )
        return self._handle_response(response)
    
    def get_alerts(self, page: int = 1, page_size: int = 50, **filters) -> Dict[str, Any]:
        """Get alerts with filters"""
        params = {"page": page, "page_size": page_size, **filters}
        response = self.session.get(
            f"{self.base_url}/api/alerts",
            params=params,
            headers=self._get_headers(),
            timeout=self.timeout
        )
        return self._handle_response(response)
    
    def get_alert_analytics(self, **filters) -> Dict[str, Any]:
        """Get alert analytics including distributions and statistics"""
        response = self.session.get(
            f"{self.base_url}/api/alerts/analytics",
            params=filters,
            headers=self._get_headers(),
            timeout=self.timeout
        )
        return self._handle_response(response)

    def download_alerts_csv(self, **filters) -> bytes:
        """Download alerts CSV with filters. Returns raw bytes."""
        response = self.session.get(
            f"{self.base_url}/api/alerts/export",
            params=filters,
            headers=self._get_headers(),
            timeout=self.timeout
        )
        if response.status_code >= 400:
            return self._handle_response(response)  # will raise
        return response.content
    
    def update_alert_status(self, alert_id: int, status: str) -> Dict[str, Any]:
        """Update alert status"""
        response = self.session.patch(
            f"{self.base_url}/api/alerts/{alert_id}/status",
            json={"status": status},
            headers=self._get_headers(),
            timeout=self.timeout
        )
        return self._handle_response(response)
    
    def get_threshold(self) -> Dict[str, Any]:
        """Get current threshold"""
        response = self.session.get(
            f"{self.base_url}/api/threshold",
            headers=self._get_headers(),
            timeout=self.timeout
        )
        return self._handle_response(response)
    
    def update_threshold(self, new_value: float) -> Dict[str, Any]:
        """Update threshold"""
        response = self.session.put(
            f"{self.base_url}/api/threshold",
            json={"new_value": new_value},
            headers=self._get_headers(),
            timeout=self.timeout
        )
        return self._handle_response(response)
    
    def get_active_blocks(self) -> list:
        """Get active block rules"""
        response = self.session.get(
            f"{self.base_url}/api/blocks/active",
            headers=self._get_headers(),
            timeout=self.timeout
        )
        return self._handle_response(response)
    
    def create_block(self, src_ip: str, reason: str) -> Dict[str, Any]:
        """Create block rule"""
        response = self.session.post(
            f"{self.base_url}/api/blocks",
            json={"src_ip": src_ip, "reason": reason},
            headers=self._get_headers(),
            timeout=self.timeout
        )
        return self._handle_response(response)
    
    def deactivate_block(self, block_id: str) -> Dict[str, Any]:
        """Deactivate block rule"""
        response = self.session.patch(
            f"{self.base_url}/api/blocks/{block_id}/deactivate",
            headers=self._get_headers(),
            timeout=self.timeout
        )
        return self._handle_response(response)
    
    # User Management
    def list_users(self, query: str = "") -> list:
        """List users"""
        params = {"query": query} if query else {}
        response = self.session.get(
            f"{self.base_url}/users",
            params=params,
            headers=self._get_headers(),
            timeout=self.timeout
        )
        return self._handle_response(response)
    
    def create_user(self, email: str, password: str, role: str) -> Dict[str, Any]:
        """Create user"""
        response = self.session.post(
            f"{self.base_url}/users",
            json={"email": email, "password": password, "role": role},
            headers=self._get_headers(),
            timeout=self.timeout
        )
        return self._handle_response(response)
    
    def update_user(self, user_id: str, **updates) -> Dict[str, Any]:
        """Update user"""
        response = self.session.patch(
            f"{self.base_url}/users/{user_id}",
            json=updates,
            headers=self._get_headers(),
            timeout=self.timeout
        )
        return self._handle_response(response)
    
    def delete_user(self, user_id: str) -> None:
        """Delete a user (ADMIN only)"""
        response = self.session.delete(
            f"{self.base_url}/users/{user_id}",
            headers=self._get_headers(),
            timeout=self.timeout
        )
        # Expect 204 No Content; still run through handler for consistency
        if response.status_code >= 400:
            self._handle_response(response)
        return None
    
    # Monitoring APIs
    def start_monitoring(self, interface: str = "eth0", threshold: float = 0.50) -> Dict[str, Any]:
        """Start traffic monitoring"""
        response = self.session.post(
            f"{self.base_url}/api/monitor/start",
            json={"interface": interface, "threshold": threshold},
            headers=self._get_headers(),
            timeout=self.timeout
        )
        return self._handle_response(response)
    
    def stop_monitoring(self) -> Dict[str, Any]:
        """Stop traffic monitoring"""
        response = self.session.post(
            f"{self.base_url}/api/monitor/stop",
            headers=self._get_headers(),
            timeout=self.timeout
        )
        return self._handle_response(response)
    
    def get_monitoring_status(self) -> Dict[str, Any]:
        """Get monitoring status"""
        response = self.session.get(
            f"{self.base_url}/api/monitor/status",
            headers=self._get_headers(),
            timeout=self.timeout
        )
        return self._handle_response(response)

