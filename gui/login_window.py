"""
Login Window for IDS/IDPS Desktop Application
"""
from PyQt5.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel, QLineEdit,
    QPushButton, QMessageBox, QFrame, QDialog, QGroupBox
)
from PyQt5.QtCore import Qt, pyqtSignal
from PyQt5.QtGui import QFont, QPixmap
from api_client import APIClient
from dashboard_window import DashboardWindow
import io


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
        self.email_input.setPlaceholderText("admin@ids-idps.com")
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
        
        demo_admin = QLabel("Admin: admin@ids-idps.com / [Generated during setup]")
        demo_admin.setFont(QFont("Courier", 8))
        demo_layout.addWidget(demo_admin)
        
        demo_analyst = QLabel("Analyst: analyst@ids-idps.com / [Generated during setup]")
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

