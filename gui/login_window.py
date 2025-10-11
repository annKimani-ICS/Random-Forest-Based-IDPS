"""
Login Window for IDS/IDPS Desktop Application
"""
from PyQt5.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel, QLineEdit,
    QPushButton, QMessageBox, QFrame, QDialog, QGroupBox, QScrollArea
)
from PyQt5.QtCore import Qt, pyqtSignal
from PyQt5.QtGui import QFont, QPixmap
from api_client import APIClient
from dashboard_window import DashboardWindow
import io
import base64


class MFADialog(QDialog):
    """MFA verification dialog"""
    def __init__(self, ticket: str, api_client: APIClient, parent=None):
        super().__init__(parent)
        self.ticket = ticket
        self.api_client = api_client
        self.setWindowTitle("Two-Factor Authentication")
        self.setFixedSize(400, 200)
        self.setup_ui()
    
    def setup_ui(self):
        layout = QVBoxLayout()
        
        # Title
        title = QLabel("Enter 6-Digit Code")
        title.setFont(QFont("Arial", 14, QFont.Bold))
        title.setAlignment(Qt.AlignCenter)
        layout.addWidget(title)
        
        # Instruction
        instruction = QLabel("Open Google Authenticator and enter the code")
        instruction.setAlignment(Qt.AlignCenter)
        layout.addWidget(instruction)
        
        layout.addSpacing(20)
        
        # Code input
        self.code_input = QLineEdit()
        self.code_input.setMaxLength(6)
        self.code_input.setPlaceholderText("000000")
        self.code_input.setFont(QFont("Courier", 24))
        self.code_input.setAlignment(Qt.AlignCenter)
        self.code_input.textChanged.connect(self.on_code_changed)
        layout.addWidget(self.code_input)
        
        layout.addSpacing(20)
        
        # Verify button
        self.verify_btn = QPushButton("Verify")
        self.verify_btn.setEnabled(False)
        self.verify_btn.clicked.connect(self.verify)
        self.verify_btn.setStyleSheet("""
            QPushButton {
                background-color: #2563eb;
                color: white;
                border: none;
                padding: 10px;
                border-radius: 5px;
                font-size: 14px;
                font-weight: bold;
            }
            QPushButton:hover {
                background-color: #1e40af;
            }
            QPushButton:disabled {
                background-color: #94a3b8;
            }
        """)
        layout.addWidget(self.verify_btn)
        
        self.setLayout(layout)
    
    def on_code_changed(self, text):
        # Only allow digits
        filtered = ''.join(filter(str.isdigit, text))
        if filtered != text:
            self.code_input.setText(filtered)
        self.verify_btn.setEnabled(len(filtered) == 6)
    
    def verify(self):
        code = self.code_input.text()
        try:
            self.api_client.verify_mfa(self.ticket, code)
            self.accept()
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Invalid MFA code: {str(e)}")
            self.code_input.clear()


class MFAEnrollDialog(QDialog):
    """MFA enrollment dialog with QR code"""
    def __init__(self, api_client: APIClient, parent=None):
        super().__init__(parent)
        self.api_client = api_client
        self.qr_data = None
        self.secret = None
        self.recovery_codes = None
        self.setWindowTitle("Enable Two-Factor Authentication")
        self.setFixedSize(500, 700)
        self.setup_ui()
        self.load_qr_code()
    
    def setup_ui(self):
        layout = QVBoxLayout()
        
        # Title
        title = QLabel("🔐 Enable Two-Factor Authentication")
        title.setFont(QFont("Arial", 16, QFont.Bold))
        title.setAlignment(Qt.AlignCenter)
        layout.addWidget(title)
        
        layout.addSpacing(10)
        
        # Instructions
        instructions = QLabel(
            "Follow these steps to enable 2FA:\n"
            "1. Install Google Authenticator on your phone\n"
            "2. Scan the QR code below\n"
            "3. Enter the 6-digit code to verify"
        )
        instructions.setWordWrap(True)
        instructions.setAlignment(Qt.AlignCenter)
        instructions.setStyleSheet("color: #64748b;")
        layout.addWidget(instructions)
        
        layout.addSpacing(20)
        
        # QR Code container
        qr_frame = QFrame()
        qr_frame.setStyleSheet("""
            QFrame {
                background-color: white;
                border: 2px solid #e2e8f0;
                border-radius: 8px;
                padding: 20px;
            }
        """)
        qr_layout = QVBoxLayout()
        
        self.qr_label = QLabel("Loading QR Code...")
        self.qr_label.setAlignment(Qt.AlignCenter)
        self.qr_label.setMinimumSize(300, 300)
        qr_layout.addWidget(self.qr_label)
        
        # Manual entry label
        self.secret_label = QLabel("Loading secret...")
        self.secret_label.setFont(QFont("Courier", 10))
        self.secret_label.setAlignment(Qt.AlignCenter)
        self.secret_label.setStyleSheet("color: #64748b;")
        self.secret_label.setWordWrap(True)
        qr_layout.addWidget(self.secret_label)
        
        qr_frame.setLayout(qr_layout)
        layout.addWidget(qr_frame)
        
        layout.addSpacing(20)
        
        # Verification section
        verify_label = QLabel("Enter the 6-digit code from your app:")
        verify_label.setFont(QFont("Arial", 11, QFont.Bold))
        verify_label.setAlignment(Qt.AlignCenter)
        layout.addWidget(verify_label)
        
        self.code_input = QLineEdit()
        self.code_input.setMaxLength(6)
        self.code_input.setPlaceholderText("000000")
        self.code_input.setFont(QFont("Courier", 20))
        self.code_input.setAlignment(Qt.AlignCenter)
        self.code_input.textChanged.connect(self.on_code_changed)
        layout.addWidget(self.code_input)
        
        layout.addSpacing(20)
        
        # Buttons
        btn_layout = QHBoxLayout()
        
        self.activate_btn = QPushButton("✓ Activate 2FA")
        self.activate_btn.setEnabled(False)
        self.activate_btn.clicked.connect(self.activate_mfa)
        self.activate_btn.setStyleSheet("""
            QPushButton {
                background-color: #10b981;
                color: white;
                border: none;
                padding: 12px;
                border-radius: 5px;
                font-size: 14px;
                font-weight: bold;
            }
            QPushButton:hover {
                background-color: #059669;
            }
            QPushButton:disabled {
                background-color: #94a3b8;
            }
        """)
        btn_layout.addWidget(self.activate_btn)
        
        cancel_btn = QPushButton("Cancel")
        cancel_btn.clicked.connect(self.reject)
        cancel_btn.setStyleSheet("""
            QPushButton {
                background-color: #f1f5f9;
                color: #475569;
                border: 1px solid #e2e8f0;
                padding: 12px;
                border-radius: 5px;
                font-size: 14px;
            }
        """)
        btn_layout.addWidget(cancel_btn)
        
        layout.addLayout(btn_layout)
        
        self.setLayout(layout)
    
    def load_qr_code(self):
        """Load QR code from backend"""
        try:
            data = self.api_client.enroll_mfa()
            self.qr_data = data.get("qr_code")
            self.secret = data.get("secret")
            
            # Display QR code
            if self.qr_data and self.qr_data.startswith("data:image/png;base64,"):
                img_data = self.qr_data.split(",")[1]
                img_bytes = base64.b64decode(img_data)
                
                pixmap = QPixmap()
                pixmap.loadFromData(img_bytes)
                scaled_pixmap = pixmap.scaled(280, 280, Qt.KeepAspectRatio, Qt.SmoothTransformation)
                self.qr_label.setPixmap(scaled_pixmap)
            else:
                self.qr_label.setText("Failed to load QR code")
            
            # Display secret for manual entry
            if self.secret:
                self.secret_label.setText(f"Manual entry: {self.secret}")
        
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Failed to generate QR code: {str(e)}")
            self.reject()
    
    def on_code_changed(self, text):
        # Only allow digits
        filtered = ''.join(filter(str.isdigit, text))
        if filtered != text:
            self.code_input.setText(filtered)
        self.activate_btn.setEnabled(len(filtered) == 6)
    
    def activate_mfa(self):
        """Activate MFA after verifying code"""
        code = self.code_input.text()
        try:
            result = self.api_client.activate_mfa(code)
            self.recovery_codes = result.get("recovery_codes", [])
            
            # Show recovery codes
            recovery_msg = "✓ Two-Factor Authentication Enabled!\n\n"
            recovery_msg += "Save these recovery codes in a safe place.\n"
            recovery_msg += "You can use them to access your account if you lose your phone:\n\n"
            recovery_msg += "\n".join(self.recovery_codes)
            
            QMessageBox.information(self, "Success", recovery_msg)
            self.accept()
        
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Failed to activate 2FA: {str(e)}")
            self.code_input.clear()


class LoginWindow(QWidget):
    """Main login window"""
    def __init__(self):
        super().__init__()
        self.api_client = APIClient()
        self.dashboard = None
        self.setWindowTitle("IDS/IDPS System - Login")
        self.setFixedSize(500, 600)
        self.setup_ui()
    
    def setup_ui(self):
        main_layout = QVBoxLayout()
        main_layout.setContentsMargins(40, 40, 40, 40)
        
        # Header
        header_layout = QVBoxLayout()
        header_layout.setSpacing(10)
        
        title = QLabel("🛡 IDS/IDPS")
        title.setFont(QFont("Arial", 28, QFont.Bold))
        title.setAlignment(Qt.AlignCenter)
        header_layout.addWidget(title)
        
        subtitle = QLabel("Intrusion Detection & Prevention System")
        subtitle.setFont(QFont("Arial", 12))
        subtitle.setAlignment(Qt.AlignCenter)
        subtitle.setStyleSheet("color: #64748b;")
        header_layout.addWidget(subtitle)
        
        main_layout.addLayout(header_layout)
        main_layout.addSpacing(40)
        
        # Login form
        form_group = QGroupBox()
        form_group.setStyleSheet("""
            QGroupBox {
                background-color: white;
                border: 1px solid #e2e8f0;
                border-radius: 8px;
                padding: 20px;
            }
        """)
        form_layout = QVBoxLayout()
        
        # Email field
        email_label = QLabel("Email Address")
        email_label.setFont(QFont("Arial", 10, QFont.Bold))
        form_layout.addWidget(email_label)
        
        self.email_input = QLineEdit()
        self.email_input.setPlaceholderText("Enter your email")
        self.email_input.setFixedHeight(40)
        self.email_input.setStyleSheet("""
            QLineEdit {
                border: 1px solid #e2e8f0;
                border-radius: 5px;
                padding: 8px;
                font-size: 14px;
            }
            QLineEdit:focus {
                border: 2px solid #2563eb;
            }
        """)
        form_layout.addWidget(self.email_input)
        
        form_layout.addSpacing(15)
        
        # Password field
        password_label = QLabel("Password")
        password_label.setFont(QFont("Arial", 10, QFont.Bold))
        form_layout.addWidget(password_label)
        
        self.password_input = QLineEdit()
        self.password_input.setPlaceholderText("••••••••")
        self.password_input.setEchoMode(QLineEdit.Password)
        self.password_input.setFixedHeight(40)
        self.password_input.setStyleSheet(self.email_input.styleSheet())
        self.password_input.returnPressed.connect(self.login)
        form_layout.addWidget(self.password_input)
        
        form_layout.addSpacing(20)
        
        # Login button
        self.login_btn = QPushButton("Login")
        self.login_btn.setFixedHeight(45)
        self.login_btn.setCursor(Qt.PointingHandCursor)
        self.login_btn.clicked.connect(self.login)
        self.login_btn.setStyleSheet("""
            QPushButton {
                background-color: #2563eb;
                color: white;
                border: none;
                border-radius: 5px;
                font-size: 16px;
                font-weight: bold;
            }
            QPushButton:hover {
                background-color: #1e40af;
            }
            QPushButton:pressed {
                background-color: #1e3a8a;
            }
        """)
        form_layout.addWidget(self.login_btn)
        
        form_group.setLayout(form_layout)
        main_layout.addWidget(form_group)
        
        main_layout.addSpacing(20)
        
        # Demo credentials
        demo_frame = QFrame()
        demo_frame.setStyleSheet("""
            QFrame {
                background-color: #f8fafc;
                border: 1px solid #e2e8f0;
                border-radius: 5px;
                padding: 10px;
            }
        """)
        demo_layout = QVBoxLayout()
        
        demo_title = QLabel("Demo Credentials:")
        demo_title.setFont(QFont("Arial", 9, QFont.Bold))
        demo_layout.addWidget(demo_title)
        
        demo_admin = QLabel("Admin: Check setup output for credentials")
        demo_admin.setFont(QFont("Courier", 8))
        demo_layout.addWidget(demo_admin)
        
        demo_analyst = QLabel("Analyst: Check setup output for credentials")
        demo_analyst.setFont(QFont("Courier", 8))
        demo_layout.addWidget(demo_analyst)
        
        demo_frame.setLayout(demo_layout)
        main_layout.addWidget(demo_frame)
        
        main_layout.addStretch()
        
        self.setLayout(main_layout)
        
        # Set window background
        self.setStyleSheet("QWidget { background-color: #f1f5f9; }")
    
    def login(self):
        email = self.email_input.text().strip()
        password = self.password_input.text()
        
        if not email or not password:
            QMessageBox.warning(self, "Error", "Please enter email and password")
            return
        
        self.login_btn.setEnabled(False)
        self.login_btn.setText("Logging in...")
        
        try:
            result = self.api_client.login(email, password)
            
            if result.get("mfa_required"):
                # Show MFA dialog
                mfa_dialog = MFADialog(result["mfa_ticket"], self.api_client, self)
                if mfa_dialog.exec_() == QDialog.Accepted:
                    self.open_dashboard()
                else:
                    self.login_btn.setEnabled(True)
                    self.login_btn.setText("Login")
            else:
                # No MFA required
                self.open_dashboard()
        
        except Exception as e:
            QMessageBox.critical(self, "Login Failed", str(e))
            self.login_btn.setEnabled(True)
            self.login_btn.setText("Login")
            self.password_input.clear()
    
    def open_dashboard(self):
        """Open dashboard window"""
        try:
            user = self.api_client.get_current_user()
            self.dashboard = DashboardWindow(self.api_client, user)
            self.dashboard.show()
            self.close()
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Failed to load dashboard: {str(e)}")
            self.login_btn.setEnabled(True)
            self.login_btn.setText("Login")

