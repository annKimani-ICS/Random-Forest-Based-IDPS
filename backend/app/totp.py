import pyotp
import qrcode
import io
import base64
from typing import Tuple

def generate_totp_secret() -> str:
    """Generate a random TOTP secret"""
    return pyotp.random_base32()

def get_totp_uri(secret: str, email: str, issuer: str = "IDS-IDPS") -> str:
    """Generate TOTP provisioning URI for QR code"""
    totp = pyotp.TOTP(secret)
    return totp.provisioning_uri(name=email, issuer_name=issuer)

def generate_qr_code(uri: str) -> str:
    """Generate QR code image as base64 string"""
    qr = qrcode.QRCode(version=1, box_size=10, border=5)
    qr.add_data(uri)
    qr.make(fit=True)
    
    img = qr.make_image(fill_color="black", back_color="white")
    
    # Convert to base64
    buffer = io.BytesIO()
    img.save(buffer, format="PNG")
    buffer.seek(0)
    img_base64 = base64.b64encode(buffer.getvalue()).decode()
    
    return f"data:image/png;base64,{img_base64}"

def verify_totp(secret: str, code: str, valid_window: int = 1) -> bool:
    """Verify a TOTP code with a time window"""
    totp = pyotp.TOTP(secret)
    return totp.verify(code, valid_window=valid_window)

def generate_recovery_codes(count: int = 10) -> list[str]:
    """Generate recovery codes for backup authentication"""
    import secrets
    return [secrets.token_hex(4).upper() for _ in range(count)]

