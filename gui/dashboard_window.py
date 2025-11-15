"""
Main Dashboard Window for IDS/IDPS Desktop Application
Uses PyQt5 for GUI as specified in project requirements
"""
from PyQt5.QtWidgets import (
    QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QLabel,
    QPushButton, QTableWidget, QTableWidgetItem, QHeaderView,
    QComboBox, QMessageBox, QTabWidget, QGroupBox, QGridLayout,
    QSlider, QFrame, QDialog, QLineEdit, QTextEdit, QSpinBox,
    QScrollArea, QDesktopWidget
)
from PyQt5.QtCore import Qt, QTimer, pyqtSignal, QThread, QRect
from PyQt5.QtGui import QFont, QColor
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.figure import Figure
import matplotlib.pyplot as plt
from datetime import datetime, timezone
from api_client import APIClient


class KPICard(QFrame):
    """KPI Card Widget"""
    def __init__(self, title, value, icon, color):
        super().__init__()
        self.setFrameShape(QFrame.StyledPanel)
        self.setStyleSheet(f"""
            QFrame {{
                background-color: white;
                border: 1px solid #e2e8f0;
                border-radius: 8px;
                padding: 15px;
            }}
        """)
        
        layout = QVBoxLayout()
        
        # Title
        title_label = QLabel(title)
        title_label.setFont(QFont("Arial", 10))
        title_label.setStyleSheet("color: #64748b;")
        layout.addWidget(title_label)
        
        # Value
        self.value_label = QLabel(str(value))
        self.value_label.setFont(QFont("Arial", 24, QFont.Bold))
        self.value_label.setStyleSheet(f"color: {color};")
        layout.addWidget(self.value_label)
        
        # Icon/Subtitle
        icon_label = QLabel(icon)
        icon_label.setFont(QFont("Arial", 8))
        icon_label.setStyleSheet("color: #94a3b8;")
        layout.addWidget(icon_label)
        
        self.setLayout(layout)
    
    def update_value(self, value):
        self.value_label.setText(str(value))


class BlockIPDialog(QDialog):
    """Dialog for blocking an IP address"""
    def __init__(self, ip_address, parent=None):
        super().__init__(parent)
        self.ip_address = ip_address
        self.reason = ""
        self.setWindowTitle("Block IP Address")
        self.setFixedSize(400, 200)
        self.setup_ui()
    
    def setup_ui(self):
        layout = QVBoxLayout()
        
        # IP display
        ip_label = QLabel(f"Block IP: {self.ip_address}")
        ip_label.setFont(QFont("Arial", 12, QFont.Bold))
        layout.addWidget(ip_label)
        
        layout.addSpacing(10)
        
        # Reason input
        reason_label = QLabel("Reason:")
        layout.addWidget(reason_label)
        
        self.reason_input = QTextEdit()
        self.reason_input.setPlaceholderText("Enter reason for blocking this IP...")
        self.reason_input.setMaximumHeight(80)
        layout.addWidget(self.reason_input)
        
        layout.addSpacing(10)
        
        # Buttons
        btn_layout = QHBoxLayout()
        
        block_btn = QPushButton("Block IP")
        block_btn.clicked.connect(self.accept)
        block_btn.setStyleSheet("""
            QPushButton {
                background-color: #ef4444;
                color: white;
                border: none;
                padding: 8px 16px;
                border-radius: 5px;
                font-weight: bold;
            }
            QPushButton:hover {
                background-color: #dc2626;
            }
        """)
        btn_layout.addWidget(block_btn)
        
        cancel_btn = QPushButton("Cancel")
        cancel_btn.clicked.connect(self.reject)
        cancel_btn.setStyleSheet("""
            QPushButton {
                background-color: #f1f5f9;
                color: #475569;
                border: 1px solid #e2e8f0;
                padding: 8px 16px;
                border-radius: 5px;
            }
        """)
        btn_layout.addWidget(cancel_btn)
        
        layout.addLayout(btn_layout)
        self.setLayout(layout)
    
    def get_reason(self):
        return self.reason_input.toPlainText()


class CreateUserDialog(QDialog):
    """Dialog to create a new user (ADMIN only)"""
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Create New User")
        self.setModal(True)
        self.resize(420, 240)
        layout = QVBoxLayout(self)
        layout.setContentsMargins(20, 20, 20, 20)

        # Email
        email_row = QHBoxLayout()
        email_row.addWidget(QLabel("Email:"))
        self.email_input = QLineEdit()
        self.email_input.setPlaceholderText("analyst@ids-idps.com")
        email_row.addWidget(self.email_input)
        layout.addLayout(email_row)

        # Password
        pwd_row = QHBoxLayout()
        pwd_row.addWidget(QLabel("Password:"))
        self.pwd_input = QLineEdit()
        self.pwd_input.setEchoMode(QLineEdit.Password)
        self.pwd_input.setPlaceholderText("StrongPassword123!@#")
        pwd_row.addWidget(self.pwd_input)
        layout.addLayout(pwd_row)

        # Role
        role_row = QHBoxLayout()
        role_row.addWidget(QLabel("Role:"))
        self.role_combo = QComboBox()
        self.role_combo.addItems(["ANALYST", "ADMIN"])  # default ANALYST
        self.role_combo.setCurrentText("ANALYST")
        role_row.addWidget(self.role_combo)
        layout.addLayout(role_row)

        # Buttons
        btns = QHBoxLayout()
        btns.addStretch()
        create_btn = QPushButton("Create")
        cancel_btn = QPushButton("Cancel")
        create_btn.clicked.connect(self.accept)
        cancel_btn.clicked.connect(self.reject)
        create_btn.setStyleSheet("background-color: #10b981; color: white; border: none; padding: 8px 14px;")
        cancel_btn.setStyleSheet("padding: 8px 14px;")
        btns.addWidget(create_btn)
        btns.addWidget(cancel_btn)
        layout.addLayout(btns)

    def get_values(self):
        return self.email_input.text().strip(), self.pwd_input.text(), self.role_combo.currentText()


class DashboardWindow(QMainWindow):
    """Main Dashboard Window"""
    def __init__(self, api_client: APIClient, user: dict):
        super().__init__()
        self.api_client = api_client
        self.user = user
        self.is_admin = user.get("role") == "ADMIN"
        
        self.setWindowTitle("IDS/IDPS Admin Dashboard")
        
        # Get screen dimensions and set appropriate window size
        desktop = QDesktopWidget()
        screen_geometry = desktop.availableGeometry()
        screen_width = screen_geometry.width()
        screen_height = screen_geometry.height()
        
        # Use 90% of screen size, but cap at reasonable maximums
        window_width = min(int(screen_width * 0.9), 1600)
        window_height = min(int(screen_height * 0.9), 1000)
        
        # Set minimum size to prevent window from being too small
        self.setMinimumSize(1200, 700)
        
        # Set maximum size to screen size
        self.setMaximumSize(screen_width, screen_height)
        
        # Center the window on screen
        x = (screen_width - window_width) // 2
        y = (screen_height - window_height) // 2
        self.setGeometry(x, y, window_width, window_height)
        
        # Auto-refresh timer
        self.refresh_timer = QTimer()
        self.refresh_timer.timeout.connect(self.refresh_data)
        self.refresh_timer.start(30000)  # Refresh every 30 seconds
        
        self.setup_ui()
        self.load_data()
        
        # Update monitoring status on startup (if admin)
        # Buttons will be initialized after setup_ui creates them
        if self.is_admin:
            QTimer.singleShot(1000, self.update_monitoring_status)  # Delay 1 second for UI to render
    
    def setup_ui(self):
        """Setup main UI"""
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        
        main_layout = QVBoxLayout()
        main_layout.setContentsMargins(0, 0, 0, 0)
        
        # Header
        header = self.create_header()
        main_layout.addWidget(header)
        
        # Tab Widget
        self.tabs = QTabWidget()
        self.tabs.setStyleSheet("""
            QTabWidget::pane {
                border: 1px solid #e2e8f0;
                background: #f8fafc;
            }
            QTabBar::tab {
                background: #f1f5f9;
                padding: 10px 20px;
                margin-right: 2px;
                border-top-left-radius: 5px;
                border-top-right-radius: 5px;
            }
            QTabBar::tab:selected {
                background: white;
                color: #2563eb;
                font-weight: bold;
            }
        """)
        
        # Dashboard tab (with scroll area)
        dashboard_tab = self.create_dashboard_tab()
        self.tabs.addTab(dashboard_tab, "📊 Dashboard")
        
        # Alerts tab (with scroll area)
        alerts_tab = self.create_alerts_tab()
        self.tabs.addTab(alerts_tab, "🚨 Alerts")
        
        # Analytics tab (no scroll - fits on one page) - Available for all users
        analytics_tab = self.create_analytics_tab()
        self.tabs.addTab(analytics_tab, "📈 Analytics")
        
        # Security tab (with scroll area)
        security_tab = self.create_security_tab()
        self.tabs.addTab(security_tab, "🔐 Security")
        
        # Settings tab (Admin only, with scroll area)
        if self.is_admin:
            settings_tab = self.create_settings_tab()
            self.tabs.addTab(settings_tab, "⚙️ Settings")
            
            users_tab = self.create_users_tab()
            self.tabs.addTab(users_tab, "👥 Users")
        
        main_layout.addWidget(self.tabs)
        
        central_widget.setLayout(main_layout)
        
        # Apply global stylesheet
        self.setStyleSheet("""
            QMainWindow {
                background-color: #f8fafc;
            }
            QLabel {
                color: #1e293b;
            }
            QPushButton {
                padding: 8px 16px;
                border-radius: 5px;
                font-size: 12px;
            }
        """)
    
    def create_header(self):
        """Create header bar"""
        header = QFrame()
        header.setStyleSheet("""
            QFrame {
                background-color: white;
                border-bottom: 1px solid #e2e8f0;
                padding: 15px;
            }
        """)
        header.setMaximumHeight(80)
        
        layout = QHBoxLayout()
        
        # Left side - Title
        title_layout = QVBoxLayout()
        title = QLabel("🛡 IDS/IDPS Dashboard")
        title.setFont(QFont("Arial", 16, QFont.Bold))
        title_layout.addWidget(title)
        
        self.model_version_label = QLabel("Model: Loading...")
        self.model_version_label.setFont(QFont("Arial", 9))
        self.model_version_label.setStyleSheet("color: #64748b;")
        title_layout.addWidget(self.model_version_label)
        
        layout.addLayout(title_layout)
        layout.addStretch()
        
        # Right side - User info and logout
        user_label = QLabel(f"👤 {self.user['email']} ({self.user['role']})")
        user_label.setFont(QFont("Arial", 10))
        user_label.setStyleSheet("""
            background-color: #f1f5f9;
            padding: 8px 16px;
            border-radius: 5px;
        """)
        layout.addWidget(user_label)
        
        logout_btn = QPushButton("Logout")
        logout_btn.clicked.connect(self.logout)
        logout_btn.setStyleSheet("""
            QPushButton {
                background-color: #ef4444;
                color: white;
                border: none;
            }
            QPushButton:hover {
                background-color: #dc2626;
            }
        """)
        layout.addWidget(logout_btn)
        
        header.setLayout(layout)
        return header
    
    def create_dashboard_tab(self):
        """Create main dashboard tab with KPIs and charts"""
        # Create scroll area for dashboard content
        scroll_area = QScrollArea()
        scroll_area.setWidgetResizable(True)
        scroll_area.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        scroll_area.setVerticalScrollBarPolicy(Qt.ScrollBarAsNeeded)
        scroll_area.setStyleSheet("""
            QScrollArea {
                border: none;
                background-color: #f8fafc;
            }
        """)
        
        # Content widget
        content_widget = QWidget()
        layout = QVBoxLayout()
        layout.setContentsMargins(20, 20, 20, 20)
        layout.setSpacing(20)
        
        # KPI Cards
        kpi_layout = QHBoxLayout()
        
        self.alerts_24h_card = KPICard("Alerts (24h)", "0", "Last 24 hours", "#2563eb")
        kpi_layout.addWidget(self.alerts_24h_card)
        
        self.active_blocks_card = KPICard("Active Blocks", "0", "IP addresses blocked", "#ef4444")
        kpi_layout.addWidget(self.active_blocks_card)
        
        self.precision_card = KPICard("Precision", "0%", "Model accuracy", "#10b981")
        kpi_layout.addWidget(self.precision_card)
        
        self.threshold_card = KPICard("Threshold", "0.00", "Detection threshold", "#f59e0b")
        kpi_layout.addWidget(self.threshold_card)
        
        layout.addLayout(kpi_layout)
        
        layout.addSpacing(20)
        
        # Traffic Monitoring Control (Admin only)
        if self.is_admin:
            monitoring_group = QGroupBox("🔍 Traffic Monitoring")
            monitoring_group.setStyleSheet("""
                QGroupBox {
                    font-weight: bold;
                    border: 2px solid #2563eb;
                    border-radius: 8px;
                    margin-top: 10px;
                    padding-top: 10px;
                    background-color: white;
                }
                QGroupBox::title {
                    subcontrol-origin: margin;
                    left: 10px;
                    padding: 0 5px;
                    color: #2563eb;
                }
            """)
            
            monitoring_layout = QVBoxLayout()
            
            # Status display
            status_layout = QHBoxLayout()
            self.monitoring_status_label = QLabel("Status: Checking...")
            self.monitoring_status_label.setFont(QFont("Arial", 12, QFont.Bold))
            self.monitoring_status_label.setStyleSheet("color: #64748b;")
            status_layout.addWidget(self.monitoring_status_label)
            
            status_layout.addStretch()
            
            # Info labels
            self.monitoring_interface_label = QLabel()
            self.monitoring_interface_label.setFont(QFont("Arial", 10))
            self.monitoring_interface_label.setStyleSheet("color: #64748b;")
            status_layout.addWidget(self.monitoring_interface_label)
            
            self.monitoring_threshold_label = QLabel()
            self.monitoring_threshold_label.setFont(QFont("Arial", 10))
            self.monitoring_threshold_label.setStyleSheet("color: #64748b;")
            status_layout.addWidget(self.monitoring_threshold_label)
            
            monitoring_layout.addLayout(status_layout)
            monitoring_layout.addSpacing(15)
            
            # Control buttons
            button_layout = QHBoxLayout()
            
            self.start_monitoring_btn = QPushButton("▶ Start Monitoring")
            self.start_monitoring_btn.clicked.connect(self.start_monitoring)
            self.start_monitoring_btn.setEnabled(True)  # Enabled by default
            self.start_monitoring_btn.setStyleSheet("""
                QPushButton {
                    background-color: #10b981;
                    color: white;
                    border: none;
                    padding: 12px 24px;
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
            button_layout.addWidget(self.start_monitoring_btn)
            
            self.stop_monitoring_btn = QPushButton("⏹ Stop Monitoring")
            self.stop_monitoring_btn.clicked.connect(self.stop_monitoring)
            self.stop_monitoring_btn.setEnabled(False)  # Disabled by default
            self.stop_monitoring_btn.setStyleSheet("""
                QPushButton {
                    background-color: #ef4444;
                    color: white;
                    border: none;
                    padding: 12px 24px;
                    border-radius: 5px;
                    font-size: 14px;
                    font-weight: bold;
                }
                QPushButton:hover {
                    background-color: #dc2626;
                }
                QPushButton:disabled {
                    background-color: #94a3b8;
                }
            """)
            button_layout.addWidget(self.stop_monitoring_btn)
            
            refresh_status_btn = QPushButton("🔄 Refresh Status")
            refresh_status_btn.clicked.connect(self.update_monitoring_status)
            refresh_status_btn.setStyleSheet("""
                QPushButton {
                    background-color: #2563eb;
                    color: white;
                    border: none;
                    padding: 12px 24px;
                    border-radius: 5px;
                    font-size: 14px;
                    font-weight: bold;
                }
                QPushButton:hover {
                    background-color: #1e40af;
                }
            """)
            button_layout.addWidget(refresh_status_btn)
            
            monitoring_layout.addLayout(button_layout)
            
            # Info text
            info_label = QLabel(
                "💡 When monitoring is active, the system will detect DDoS attacks in real-time. "
                "Start monitoring, then launch attacks from your Kali VM to test."
            )
            info_label.setWordWrap(True)
            info_label.setStyleSheet("color: #64748b; padding: 10px; background-color: #f1f5f9; border-radius: 5px;")
            monitoring_layout.addWidget(info_label)
            
            monitoring_group.setLayout(monitoring_layout)
            layout.addWidget(monitoring_group)
            
            layout.addSpacing(20)
        
        # Model Metrics Section
        metrics_group = QGroupBox("Model Performance (Random Forest)")
        metrics_group.setStyleSheet("""
            QGroupBox {
                font-weight: bold;
                border: 1px solid #e2e8f0;
                border-radius: 8px;
                margin-top: 10px;
                padding-top: 10px;
                background-color: white;
            }
            QGroupBox::title {
                subcontrol-origin: margin;
                left: 10px;
                padding: 0 5px;
            }
        """)
        
        metrics_layout = QGridLayout()
        
        self.recall_label = QLabel("Recall: Loading...")
        self.f1_label = QLabel("F1 Score: Loading...")
        self.auc_label = QLabel("AUC: Loading...")
        self.trained_date_label = QLabel("Trained: Loading...")
        
        for label in [self.recall_label, self.f1_label, self.auc_label, self.trained_date_label]:
            label.setFont(QFont("Arial", 11))
        
        metrics_layout.addWidget(self.recall_label, 0, 0)
        metrics_layout.addWidget(self.f1_label, 0, 1)
        metrics_layout.addWidget(self.auc_label, 1, 0)
        metrics_layout.addWidget(self.trained_date_label, 1, 1)
        
        metrics_group.setLayout(metrics_layout)
        layout.addWidget(metrics_group)
        
        layout.addSpacing(20)
        
        # Recent Alerts Preview
        alerts_preview_group = QGroupBox("Recent Alerts (Top 10)")
        alerts_preview_group.setStyleSheet(metrics_group.styleSheet())
        
        preview_layout = QVBoxLayout()
        
        self.preview_table = QTableWidget()
        self.preview_table.setColumnCount(6)
        self.preview_table.setHorizontalHeaderLabels(["Time", "Source IP", "Dest IP", "Attack Type", "Score", "Status"])
        self.preview_table.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
        self.preview_table.setEditTriggers(QTableWidget.NoEditTriggers)
        self.preview_table.setSelectionBehavior(QTableWidget.SelectRows)
        self.preview_table.setAlternatingRowColors(True)
        self.preview_table.setMinimumHeight(200)
        self.preview_table.setMaximumHeight(400)
        
        preview_layout.addWidget(self.preview_table)
        
        alerts_preview_group.setLayout(preview_layout)
        layout.addWidget(alerts_preview_group)
        
        # No stretch - let content determine size for scrolling
        content_widget.setLayout(layout)
        scroll_area.setWidget(content_widget)
        
        return scroll_area
    
    def create_analytics_tab(self):
        """Create analytics tab with charts"""
        widget = QWidget()
        layout = QVBoxLayout()
        layout.setContentsMargins(15, 15, 15, 15)
        layout.setSpacing(15)
        
        # Title
        title = QLabel("Alert Analytics")
        title.setFont(QFont("Arial", 16, QFont.Bold))
        title.setStyleSheet("color: #1e293b; margin-bottom: 5px;")
        layout.addWidget(title)
        
        # Summary Stats
        summary_group = QGroupBox("Summary Statistics")
        summary_group.setStyleSheet("""
            QGroupBox {
                font-weight: bold;
                border: 1px solid #e2e8f0;
                border-radius: 8px;
                margin-top: 10px;
                padding: 15px;
                background-color: white;
            }
        """)
        summary_layout = QHBoxLayout()
        self.total_alerts_label = QLabel("Total Alerts: 0")
        self.malicious_label = QLabel("Malicious: 0")
        self.benign_label = QLabel("Benign: 0")
        for label in [self.total_alerts_label, self.malicious_label, self.benign_label]:
            label.setFont(QFont("Arial", 11, QFont.Bold))
            label.setStyleSheet("padding: 8px 15px;")
        self.total_alerts_label.setStyleSheet("padding: 8px 15px; color: #2563eb;")
        self.malicious_label.setStyleSheet("padding: 8px 15px; color: #ef4444; font-weight: bold;")
        self.benign_label.setStyleSheet("padding: 8px 15px; color: #10b981; font-weight: bold;")
        summary_layout.addWidget(self.total_alerts_label)
        summary_layout.addWidget(self.malicious_label)
        summary_layout.addWidget(self.benign_label)
        summary_layout.addStretch()
        summary_group.setLayout(summary_layout)
        layout.addWidget(summary_group)
        
        # Charts Grid - Larger charts that fit on one page
        charts_layout = QGridLayout()
        charts_layout.setSpacing(15)
        charts_layout.setContentsMargins(0, 0, 0, 0)
        
        # Chart style
        chart_style = """
            QGroupBox {
                font-weight: bold;
                border: 2px solid #e2e8f0;
                border-radius: 10px;
                margin-top: 10px;
                padding: 10px;
                background-color: white;
            }
            QGroupBox::title {
                subcontrol-origin: margin;
                left: 10px;
                padding: 0 5px;
                color: #1e293b;
                font-size: 13px;
            }
        """
        
        # Attack Type Distribution Chart - Top Left (larger)
        attack_type_group = QGroupBox("Attack Type Distribution")
        attack_type_group.setStyleSheet(chart_style)
        attack_type_layout = QVBoxLayout()
        attack_type_layout.setContentsMargins(5, 5, 5, 5)
        self.attack_type_chart = FigureCanvas(Figure(figsize=(8, 5)))
        self.attack_type_chart.setMinimumHeight(400)
        attack_type_layout.addWidget(self.attack_type_chart)
        attack_type_group.setLayout(attack_type_layout)
        charts_layout.addWidget(attack_type_group, 0, 0)
        
        # Status Distribution Chart - Top Right (larger)
        status_group = QGroupBox("Status Distribution")
        status_group.setStyleSheet(chart_style)
        status_layout = QVBoxLayout()
        status_layout.setContentsMargins(5, 5, 5, 5)
        self.status_chart = FigureCanvas(Figure(figsize=(8, 5)))
        self.status_chart.setMinimumHeight(400)
        status_layout.addWidget(self.status_chart)
        status_group.setLayout(status_layout)
        charts_layout.addWidget(status_group, 0, 1)
        
        # Top Source IPs Chart - Bottom Left (larger)
        top_ips_group = QGroupBox("Top Source IPs")
        top_ips_group.setStyleSheet(chart_style)
        top_ips_layout = QVBoxLayout()
        top_ips_layout.setContentsMargins(5, 5, 5, 5)
        self.top_ips_chart = FigureCanvas(Figure(figsize=(8, 5)))
        self.top_ips_chart.setMinimumHeight(400)
        top_ips_layout.addWidget(self.top_ips_chart)
        top_ips_group.setLayout(top_ips_layout)
        charts_layout.addWidget(top_ips_group, 1, 0)
        
        # Alerts Over Time Chart - Bottom (full width, larger)
        time_series_group = QGroupBox("Alerts Over Time")
        time_series_group.setStyleSheet(chart_style)
        time_series_layout = QVBoxLayout()
        time_series_layout.setContentsMargins(5, 5, 5, 5)
        self.time_series_chart = FigureCanvas(Figure(figsize=(18, 6)))
        self.time_series_chart.setMinimumHeight(500)
        time_series_layout.addWidget(self.time_series_chart)
        time_series_group.setLayout(time_series_layout)
        charts_layout.addWidget(time_series_group, 2, 0, 1, 2)  # Span both columns, row 2
        
        layout.addLayout(charts_layout)
        layout.addStretch()
        
        widget.setLayout(layout)
        return widget
    
    def create_alerts_tab(self):
        """Create alerts management tab"""
        # Create scroll area
        scroll_area = QScrollArea()
        scroll_area.setWidgetResizable(True)
        scroll_area.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        scroll_area.setVerticalScrollBarPolicy(Qt.ScrollBarAsNeeded)
        scroll_area.setStyleSheet("""
            QScrollArea {
                border: none;
                background-color: #f8fafc;
            }
        """)
        
        widget = QWidget()
        layout = QVBoxLayout()
        layout.setContentsMargins(20, 20, 20, 20)
        
        # Filters
        filter_layout = QHBoxLayout()
        
        filter_layout.addWidget(QLabel("Filter by:"))
        
        self.malicious_filter = QComboBox()
        self.malicious_filter.addItems(["All Alerts", "Malicious Only", "Benign Only"])
        self.malicious_filter.currentIndexChanged.connect(self.load_alerts)
        filter_layout.addWidget(self.malicious_filter)
        
        self.status_filter = QComboBox()
        self.status_filter.addItems(["All Status", "NEW", "ACK", "BLOCKED", "CLOSED"])
        self.status_filter.currentIndexChanged.connect(self.load_alerts)
        filter_layout.addWidget(self.status_filter)
        
        refresh_btn = QPushButton("🔄 Refresh")
        refresh_btn.clicked.connect(self.load_alerts)
        refresh_btn.setStyleSheet("""
            QPushButton {
                background-color: #2563eb;
                color: white;
                border: none;
            }
            QPushButton:hover {
                background-color: #1e40af;
            }
        """)
        filter_layout.addWidget(refresh_btn)
        
        filter_layout.addStretch()
        
        layout.addLayout(filter_layout)
        
        layout.addSpacing(10)
        
        # Alerts table
        # Export button (available to all roles)
        export_btn = QPushButton("⬇️ Export CSV")
        export_btn.clicked.connect(self.export_alerts_csv)
        export_btn.setStyleSheet("background-color: #2563eb; color: white; border: none; padding: 8px;")
        filter_layout.addWidget(export_btn)

        self.alerts_table = QTableWidget()
        self.alerts_table.setColumnCount(8)
        self.alerts_table.setHorizontalHeaderLabels([
            "ID", "Time", "Source IP", "Dest IP", "Attack Type", "Score", "Status", "Actions"
        ])
        self.alerts_table.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeToContents)
        self.alerts_table.horizontalHeader().setSectionResizeMode(4, QHeaderView.Stretch)
        self.alerts_table.setEditTriggers(QTableWidget.NoEditTriggers)
        self.alerts_table.setSelectionBehavior(QTableWidget.SelectRows)
        self.alerts_table.setAlternatingRowColors(True)
        
        layout.addWidget(self.alerts_table)
        
        widget.setLayout(layout)
        scroll_area.setWidget(widget)
        return scroll_area
    
    def create_security_tab(self):
        """Create security tab for MFA management"""
        # Create scroll area
        scroll_area = QScrollArea()
        scroll_area.setWidgetResizable(True)
        scroll_area.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        scroll_area.setVerticalScrollBarPolicy(Qt.ScrollBarAsNeeded)
        scroll_area.setStyleSheet("""
            QScrollArea {
                border: none;
                background-color: #f8fafc;
            }
        """)
        
        widget = QWidget()
        layout = QVBoxLayout()
        layout.setContentsMargins(20, 20, 20, 20)
        
        # Account Security Section
        security_group = QGroupBox("Account Security")
        security_group.setStyleSheet("""
            QGroupBox {
                font-weight: bold;
                border: 1px solid #e2e8f0;
                border-radius: 8px;
                margin-top: 10px;
                padding: 20px;
                background-color: white;
            }
        """)
        
        security_layout = QVBoxLayout()
        
        # Account info
        account_label = QLabel(f"Account: {self.user['email']}")
        account_label.setFont(QFont("Arial", 12))
        security_layout.addWidget(account_label)
        
        security_layout.addSpacing(20)
        
        # MFA Section
        mfa_title = QLabel("Two-Factor Authentication (2FA)")
        mfa_title.setFont(QFont("Arial", 14, QFont.Bold))
        security_layout.addWidget(mfa_title)
        
        mfa_desc = QLabel(
            "Two-factor authentication adds an extra layer of security to your account. "
            "When enabled, you'll need to enter a code from your authenticator app in addition "
            "to your password when logging in."
        )
        mfa_desc.setWordWrap(True)
        mfa_desc.setStyleSheet("color: #64748b;")
        security_layout.addWidget(mfa_desc)
        
        security_layout.addSpacing(15)
        
        # MFA Status
        self.mfa_status_label = QLabel()
        self.mfa_status_label.setFont(QFont("Arial", 12))
        security_layout.addWidget(self.mfa_status_label)
        
        security_layout.addSpacing(10)
        
        # MFA Action Button
        self.mfa_action_btn = QPushButton()
        self.mfa_action_btn.clicked.connect(self.toggle_mfa)
        self.mfa_action_btn.setFixedHeight(45)
        self.mfa_action_btn.setCursor(Qt.PointingHandCursor)
        security_layout.addWidget(self.mfa_action_btn)
        
        security_layout.addSpacing(20)
        
        # Info box
        info_frame = QFrame()
        info_frame.setStyleSheet("""
            QFrame {
                background-color: #eff6ff;
                border: 1px solid #bfdbfe;
                border-radius: 5px;
                padding: 15px;
            }
        """)
        info_layout = QVBoxLayout()
        
        info_title = QLabel("ℹ️ How to set up 2FA:")
        info_title.setFont(QFont("Arial", 11, QFont.Bold))
        info_layout.addWidget(info_title)
        
        info_text = QLabel(
            "1. Download Google Authenticator on your phone (iOS or Android)\n"
            "2. Click 'Enable 2FA' and scan the QR code with the app\n"
            "3. Enter the 6-digit code from the app to complete setup\n"
            "4. Save your recovery codes in a safe place"
        )
        info_text.setStyleSheet("color: #1e40af;")
        info_layout.addWidget(info_text)
        
        info_frame.setLayout(info_layout)
        security_layout.addWidget(info_frame)
        
        security_group.setLayout(security_layout)
        layout.addWidget(security_group)
        
        layout.addStretch()
        
        # Update MFA status
        self.update_mfa_status()
        
        widget.setLayout(layout)
        scroll_area.setWidget(widget)
        return scroll_area
    
    def update_mfa_status(self):
        """Update MFA status display"""
        mfa_enabled = self.user.get("mfa_enabled", False)
        
        if mfa_enabled:
            self.mfa_status_label.setText("Status: ✓ Enabled")
            self.mfa_status_label.setStyleSheet("color: #10b981; font-weight: bold;")
            self.mfa_action_btn.setText("🔐 2FA is Enabled")
            self.mfa_action_btn.setEnabled(False)
            self.mfa_action_btn.setStyleSheet("""
                QPushButton {
                    background-color: #10b981;
                    color: white;
                    border: none;
                    border-radius: 5px;
                    font-size: 14px;
                    font-weight: bold;
                }
            """)
        else:
            self.mfa_status_label.setText("Status: ✗ Not Enabled (Recommended)")
            self.mfa_status_label.setStyleSheet("color: #ef4444; font-weight: bold;")
            self.mfa_action_btn.setText("🔐 Enable Two-Factor Authentication")
            self.mfa_action_btn.setEnabled(True)
            self.mfa_action_btn.setStyleSheet("""
                QPushButton {
                    background-color: #2563eb;
                    color: white;
                    border: none;
                    border-radius: 5px;
                    font-size: 14px;
                    font-weight: bold;
                }
                QPushButton:hover {
                    background-color: #1e40af;
                }
            """)
    
    def toggle_mfa(self):
        """Open MFA enrollment dialog"""
        try:
            # Import here to avoid circular import
            from login_window import MFAEnrollDialog
            
            dialog = MFAEnrollDialog(self.api_client, self)
            if dialog.exec_() == QDialog.Accepted:
                # Refresh user data
                self.user = self.api_client.get_current_user()
                self.update_mfa_status()
                QMessageBox.information(
                    self, 
                    "Success", 
                    "Two-Factor Authentication has been enabled for your account!"
                )
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Failed to enable 2FA: {str(e)}")
    
    def create_settings_tab(self):
        """Create settings tab (Admin only)"""
        # Create scroll area
        scroll_area = QScrollArea()
        scroll_area.setWidgetResizable(True)
        scroll_area.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        scroll_area.setVerticalScrollBarPolicy(Qt.ScrollBarAsNeeded)
        scroll_area.setStyleSheet("""
            QScrollArea {
                border: none;
                background-color: #f8fafc;
            }
        """)
        
        widget = QWidget()
        layout = QVBoxLayout()
        layout.setContentsMargins(20, 20, 20, 20)
        
        # Threshold Control
        threshold_group = QGroupBox("Detection Threshold Configuration")
        threshold_group.setStyleSheet("""
            QGroupBox {
                font-weight: bold;
                border: 1px solid #e2e8f0;
                border-radius: 8px;
                margin-top: 10px;
                padding: 20px;
                background-color: white;
            }
        """)
        
        threshold_layout = QVBoxLayout()
        
        desc = QLabel(
            "Adjust the detection threshold to control the sensitivity of malicious traffic detection.\n"
            "Higher values reduce false positives but may miss some attacks."
        )
        desc.setWordWrap(True)
        desc.setStyleSheet("color: #64748b;")
        threshold_layout.addWidget(desc)
        
        threshold_layout.addSpacing(20)
        
        # Current threshold display
        self.threshold_value_label = QLabel("Current Threshold: 0.50")
        self.threshold_value_label.setFont(QFont("Arial", 18, QFont.Bold))
        self.threshold_value_label.setAlignment(Qt.AlignCenter)
        self.threshold_value_label.setStyleSheet("color: #2563eb;")
        threshold_layout.addWidget(self.threshold_value_label)
        
        # Slider
        self.threshold_slider = QSlider(Qt.Horizontal)
        self.threshold_slider.setMinimum(0)
        self.threshold_slider.setMaximum(100)
        self.threshold_slider.setValue(50)
        self.threshold_slider.setTickPosition(QSlider.TicksBelow)
        self.threshold_slider.setTickInterval(10)
        self.threshold_slider.valueChanged.connect(self.on_threshold_changed)
        self.threshold_slider.setStyleSheet("""
            QSlider::groove:horizontal {
                height: 8px;
                background: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                    stop:0 #dcfce7, stop:0.5 #fef3c7, stop:1 #fee2e2);
                border-radius: 4px;
            }
            QSlider::handle:horizontal {
                background: #2563eb;
                border: 2px solid #1e40af;
                width: 20px;
                margin: -6px 0;
                border-radius: 10px;
            }
        """)
        threshold_layout.addWidget(self.threshold_slider)
        
        # Range labels
        range_layout = QHBoxLayout()
        range_layout.addWidget(QLabel("0.00 (More Sensitive)"))
        range_layout.addStretch()
        range_layout.addWidget(QLabel("1.00 (Less Sensitive)"))
        threshold_layout.addLayout(range_layout)
        
        threshold_layout.addSpacing(20)
        
        # Save button
        save_threshold_btn = QPushButton("💾 Save Threshold")
        save_threshold_btn.clicked.connect(self.save_threshold)
        save_threshold_btn.setStyleSheet("""
            QPushButton {
                background-color: #2563eb;
                color: white;
                border: none;
                padding: 12px;
                font-size: 14px;
                font-weight: bold;
            }
            QPushButton:hover {
                background-color: #1e40af;
            }
        """)
        threshold_layout.addWidget(save_threshold_btn)
        
        threshold_group.setLayout(threshold_layout)
        layout.addWidget(threshold_group)
        
        layout.addSpacing(20)
        
        # Active Block Rules
        blocks_group = QGroupBox("Active Block Rules")
        blocks_group.setStyleSheet(threshold_group.styleSheet())
        
        blocks_layout = QVBoxLayout()
        
        self.blocks_table = QTableWidget()
        self.blocks_table.setColumnCount(4)
        self.blocks_table.setHorizontalHeaderLabels(["IP Address", "Reason", "Applied At", "Action"])
        self.blocks_table.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
        self.blocks_table.setMaximumHeight(300)
        
        blocks_layout.addWidget(self.blocks_table)
        
        blocks_group.setLayout(blocks_layout)
        layout.addWidget(blocks_group)
        
        widget.setLayout(layout)
        scroll_area.setWidget(widget)
        return scroll_area
    
    def create_users_tab(self):
        """Create users management tab"""
        # Create scroll area
        scroll_area = QScrollArea()
        scroll_area.setWidgetResizable(True)
        scroll_area.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        scroll_area.setVerticalScrollBarPolicy(Qt.ScrollBarAsNeeded)
        scroll_area.setStyleSheet("""
            QScrollArea {
                border: none;
                background-color: #f8fafc;
            }
        """)
        
        widget = QWidget()
        layout = QVBoxLayout()
        layout.setContentsMargins(20, 20, 20, 20)
        
        # Create user button
        create_btn = QPushButton("➕ Create New User")
        create_btn.clicked.connect(self.create_user_dialog)
        create_btn.setStyleSheet("""
            QPushButton {
                background-color: #10b981;
                color: white;
                border: none;
                padding: 10px;
                font-weight: bold;
            }
            QPushButton:hover {
                background-color: #059669;
            }
        """)
        layout.addWidget(create_btn)
        
        layout.addSpacing(10)
        
        # Users table
        self.users_table = QTableWidget()
        # Add a hidden ID column at the end for operations
        self.users_table.setColumnCount(7)
        self.users_table.setHorizontalHeaderLabels([
            "Email", "Role", "2FA Status", "Active", "Last Login", "Actions", "_id"
        ])
        self.users_table.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
        # Hide the internal id column
        self.users_table.setColumnHidden(6, True)
        
        layout.addWidget(self.users_table)
        
        widget.setLayout(layout)
        scroll_area.setWidget(widget)
        return scroll_area
    
    def on_threshold_changed(self, value):
        """Update threshold display"""
        threshold = value / 100.0
        self.threshold_value_label.setText(f"Current Threshold: {threshold:.2f}")
    
    def load_data(self):
        """Load all dashboard data"""
        try:
            # Load KPIs
            kpis = self.api_client.get_kpis()
            self.alerts_24h_card.update_value(kpis["alerts_24h"])
            self.active_blocks_card.update_value(kpis["active_blocks"])
            self.threshold_card.update_value(f"{kpis['threshold']:.2f}")
            
            # Load metrics
            metrics = self.api_client.get_metrics()
            # Format model version to show Random Forest instead of voting ensemble
            model_version = metrics.get('model_version', 'Unknown')
            if 'random_forest' in model_version.lower() or 'Random Forest' in model_version:
                display_version = "Random Forest (Iteration 4)"
            elif 'voting_ensemble' in model_version.lower() or 'voting' in model_version.lower():
                display_version = "Random Forest (Iteration 4)"
            else:
                display_version = model_version.replace('iteration4_voting_ensemble', 'Random Forest (Iteration 4)')
            
            trained_date = datetime.fromisoformat(metrics['trained_at']).strftime('%Y-%m-%d') if metrics.get('trained_at') else 'Unknown'
            self.model_version_label.setText(f"Model: {display_version} • Trained: {trained_date}")
            self.precision_card.update_value(f"{metrics['precision']*100:.1f}%")
            self.recall_label.setText(f"Recall: {metrics['recall']*100:.2f}%")
            self.f1_label.setText(f"F1 Score: {metrics['f1']*100:.2f}%")
            self.auc_label.setText(f"AUC: {metrics['auc']*100:.2f}%")
            self.trained_date_label.setText(f"Trained: {datetime.fromisoformat(metrics['trained_at']).strftime('%Y-%m-%d %H:%M')}")
            
            # Set threshold slider (only if admin)
            if hasattr(self, 'threshold_slider'):
                self.threshold_slider.setValue(int(kpis['threshold'] * 100))
            
            # Load alerts preview
            self.load_alerts_preview()
            
            # Load alerts
            self.load_alerts()
            
            # Load analytics
            self.load_analytics()
            
            # Load blocks if admin
            if self.is_admin:
                self.load_blocks()
                self.load_users()
        
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Failed to load data: {str(e)}")
    
    def load_alerts_preview(self):
        """Load alerts preview for dashboard"""
        try:
            result = self.api_client.get_alerts(page=1, page_size=10)
            alerts = result.get("alerts", [])
            
            if not alerts:
                # Show message if no alerts
                self.preview_table.setRowCount(1)
                self.preview_table.setItem(0, 0, QTableWidgetItem("No alerts available"))
                self.preview_table.setItem(0, 0, QTableWidgetItem(""))
                self.preview_table.setItem(0, 1, QTableWidgetItem(""))
                self.preview_table.setItem(0, 2, QTableWidgetItem(""))
                self.preview_table.setItem(0, 3, QTableWidgetItem(""))
                self.preview_table.setItem(0, 4, QTableWidgetItem(""))
                self.preview_table.setItem(0, 5, QTableWidgetItem(""))
                # Merge cells for message
                self.preview_table.setSpan(0, 0, 1, 6)
                msg_item = QTableWidgetItem("No recent alerts found")
                msg_item.setTextAlignment(Qt.AlignCenter)
                self.preview_table.setItem(0, 0, msg_item)
                return
            
            self.preview_table.setRowCount(len(alerts))
            
            for row, alert in enumerate(alerts):
                # Convert backend UTC timestamp to local time for preview table
                try:
                    ts = datetime.fromisoformat(alert["event_ts"]).replace(tzinfo=timezone.utc).astimezone()
                    ts_str = ts.strftime("%Y-%m-%d %H:%M")
                except Exception:
                    ts_str = str(alert["event_ts"])  # fallback
                self.preview_table.setItem(row, 0, QTableWidgetItem(ts_str))
                self.preview_table.setItem(row, 1, QTableWidgetItem(alert.get("src_ip", "N/A")))
                self.preview_table.setItem(row, 2, QTableWidgetItem(alert.get("dst_ip", "N/A")))
                self.preview_table.setItem(row, 3, QTableWidgetItem(alert.get("attack_type", "Unknown")))
                
                score = alert.get("score", 0.0)
                score_item = QTableWidgetItem(f"{score:.4f}")
                if alert.get("is_malicious", False):
                    score_item.setForeground(QColor("#ef4444"))
                else:
                    score_item.setForeground(QColor("#10b981"))
                self.preview_table.setItem(row, 4, score_item)
                
                self.preview_table.setItem(row, 5, QTableWidgetItem(alert.get("status", "NEW")))
            
            # Resize columns to fit content
            self.preview_table.resizeColumnsToContents()
        
        except Exception as e:
            print(f"Error loading alerts preview: {e}")
            import traceback
            traceback.print_exc()
            # Show error in table
            self.preview_table.setRowCount(1)
            self.preview_table.setSpan(0, 0, 1, 6)
            error_item = QTableWidgetItem(f"Error loading alerts: {str(e)}")
            error_item.setForeground(QColor("#ef4444"))
            error_item.setTextAlignment(Qt.AlignCenter)
            self.preview_table.setItem(0, 0, error_item)
    
    def load_alerts(self):
        """Load alerts table"""
        try:
            # Get filter values
            malicious_filter = self.malicious_filter.currentText()
            status_filter = self.status_filter.currentText()
            
            filters = {}
            if malicious_filter == "Malicious Only":
                filters["malicious"] = "true"
            elif malicious_filter == "Benign Only":
                filters["malicious"] = "false"
            
            if status_filter != "All Status":
                filters["status"] = status_filter
            
            result = self.api_client.get_alerts(page=1, page_size=50, **filters)
            alerts = result["alerts"]
            
            self.alerts_table.setRowCount(len(alerts))
            
            for row, alert in enumerate(alerts):
                self.alerts_table.setItem(row, 0, QTableWidgetItem(str(alert["id"])))
                # Treat backend timestamps as UTC and convert to local time for display
                try:
                    ts = datetime.fromisoformat(alert["event_ts"]).replace(tzinfo=timezone.utc).astimezone()
                    ts_str = ts.strftime("%Y-%m-%d %H:%M")
                except Exception:
                    ts_str = str(alert["event_ts"])  # fallback
                self.alerts_table.setItem(row, 1, QTableWidgetItem(ts_str))
                self.alerts_table.setItem(row, 2, QTableWidgetItem(alert["src_ip"]))
                self.alerts_table.setItem(row, 3, QTableWidgetItem(alert["dst_ip"]))
                self.alerts_table.setItem(row, 4, QTableWidgetItem(alert["attack_type"]))
                
                score_item = QTableWidgetItem(f"{alert['score']:.4f}")
                if alert["is_malicious"]:
                    score_item.setForeground(QColor("#ef4444"))
                    score_item.setFont(QFont("Arial", 10, QFont.Bold))
                self.alerts_table.setItem(row, 5, score_item)
                
                self.alerts_table.setItem(row, 6, QTableWidgetItem(alert["status"]))
                
                # Action buttons - Role-based access control
                # Analysts: Read-only access (view alerts only)
                # Admins: Full access (ACK, Block, modify status)
                btn_widget = QWidget()
                btn_layout = QHBoxLayout()
                btn_layout.setContentsMargins(5, 2, 5, 2)
                
                # Acknowledge button - Admin only (Security: Only admins can modify alert status)
                if self.is_admin and alert["status"] == "NEW":
                    ack_btn = QPushButton("ACK")
                    ack_btn.clicked.connect(lambda checked, a=alert: self.acknowledge_alert(a["id"]))
                    ack_btn.setStyleSheet("background-color: #f59e0b; color: white; border: none; padding: 5px;")
                    btn_layout.addWidget(ack_btn)
                
                # Block button - Admin only
                if self.is_admin and alert["is_malicious"] and alert["status"] in ["NEW", "ACK"]:
                    block_btn = QPushButton("Block")
                    block_btn.clicked.connect(lambda checked, a=alert: self.block_ip(a["src_ip"]))
                    block_btn.setStyleSheet("background-color: #ef4444; color: white; border: none; padding: 5px;")
                    btn_layout.addWidget(block_btn)
                
                # For analysts, show read-only indicator instead of action buttons
                if not self.is_admin:
                    read_only_label = QLabel("👁️ View Only")
                    read_only_label.setStyleSheet("color: #64748b; font-style: italic; padding: 5px;")
                    read_only_label.setAlignment(Qt.AlignCenter)
                    btn_widget.setLayout(QHBoxLayout())
                    btn_widget.layout().addWidget(read_only_label)
                else:
                    btn_widget.setLayout(btn_layout)
                
                self.alerts_table.setCellWidget(row, 7, btn_widget)
        
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Failed to load alerts: {str(e)}")

    def export_alerts_csv(self):
        """Export alerts as CSV using current filters"""
        try:
            malicious_filter = self.malicious_filter.currentText()
            status_filter = self.status_filter.currentText()
            filters = {}
            if malicious_filter == "Malicious Only":
                filters["malicious"] = "true"
            elif malicious_filter == "Benign Only":
                filters["malicious"] = "false"
            if status_filter != "All Status":
                filters["status"] = status_filter

            from PyQt5.QtWidgets import QFileDialog
            path, _ = QFileDialog.getSaveFileName(self, "Save Alerts CSV", "alerts_export.csv", "CSV Files (*.csv)")
            if not path:
                return

            try:
                data = self.api_client.download_alerts_csv(**filters)
                with open(path, "wb") as f:
                    f.write(data)
                QMessageBox.information(self, "Success", f"Saved CSV to {path}")
                return
            except Exception as e:
                # Fallback: fetch pages via API and generate CSV locally
                print(f"[Export Fallback] Server export failed: {e}. Generating client-side CSV...")
                import csv
                page = 1
                page_size = 100
                rows = []
                while True:
                    result = self.api_client.get_alerts(page=page, page_size=page_size, **filters)
                    alerts = result.get("alerts", [])
                    total = result.get("total", 0)
                    for a in alerts:
                        rows.append([
                            a.get("id"),
                            a.get("event_ts"),
                            a.get("src_ip"),
                            a.get("dst_ip"),
                            a.get("attack_type"),
                            f"{a.get('score', 0):.4f}",
                            a.get("is_malicious"),
                            a.get("status"),
                            a.get("model_version"),
                        ])
                    if len(rows) >= total or not alerts:
                        break
                    page += 1
                with open(path, "w", newline="") as f:
                    writer = csv.writer(f)
                    writer.writerow(["id","event_ts","src_ip","dst_ip","attack_type","score","is_malicious","status","model_version"])
                    writer.writerows(rows)
                QMessageBox.information(self, "Success", f"Saved CSV to {path}")
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Failed to export CSV: {str(e)}")
    
    def load_analytics(self):
        """Load and display analytics charts"""
        try:
            analytics = self.api_client.get_alert_analytics()
            print(f"Analytics data received: {analytics}")
            
            # Update summary stats
            total = analytics.get('total_alerts', 0)
            malicious = analytics.get('malicious_count', 0)
            benign = analytics.get('benign_count', 0)
            
            self.total_alerts_label.setText(f"Total Alerts: {total}")
            self.malicious_label.setText(f"Malicious: {malicious}")
            self.benign_label.setText(f"Benign: {benign}")
            
            # Attack Type Distribution (Bar Chart)
            attack_types = analytics.get('attack_type_distribution', {})
            print(f"Attack types: {attack_types}")
            if attack_types and len(attack_types) > 0:
                self.attack_type_chart.figure.clear()
                ax = self.attack_type_chart.figure.add_subplot(111)
                # Sort by count descending
                sorted_types = sorted(attack_types.items(), key=lambda x: x[1], reverse=True)
                types = [t[0] for t in sorted_types]
                counts = [t[1] for t in sorted_types]
                bars = ax.bar(range(len(types)), counts, color='#2563eb', edgecolor='#1e40af', linewidth=1.5)
                ax.set_xlabel('Attack Type', fontsize=11, fontweight='bold')
                ax.set_ylabel('Count', fontsize=11, fontweight='bold')
                ax.set_title('Attack Type Distribution', fontsize=12, fontweight='bold', pad=15)
                ax.set_xticks(range(len(types)))
                ax.set_xticklabels(types, rotation=45, ha='right', fontsize=9)
                ax.grid(axis='y', alpha=0.3, linestyle='--')
                # Add value labels on bars
                for i, (bar, count) in enumerate(zip(bars, counts)):
                    height = bar.get_height()
                    ax.text(bar.get_x() + bar.get_width()/2., height,
                           f'{count}', ha='center', va='bottom', fontsize=9, fontweight='bold')
                self.attack_type_chart.figure.tight_layout()
                self.attack_type_chart.draw()
            else:
                print("No attack type data available")
            
            # Status Distribution (Pie Chart)
            statuses = analytics.get('status_distribution', {})
            print(f"Statuses: {statuses}")
            if statuses and len(statuses) > 0:
                self.status_chart.figure.clear()
                ax = self.status_chart.figure.add_subplot(111)
                labels = list(statuses.keys())
                sizes = [statuses[k] for k in labels]
                colors = ['#ef4444', '#10b981', '#f59e0b', '#6366f1', '#8b5cf6']
                # Filter out zero values
                filtered_data = [(l, s) for l, s in zip(labels, sizes) if s > 0]
                if filtered_data:
                    labels, sizes = zip(*filtered_data)
                    wedges, texts, autotexts = ax.pie(
                        sizes, 
                        labels=labels, 
                        autopct='%1.1f%%', 
                        colors=colors[:len(labels)], 
                        startangle=90,
                        textprops={'fontsize': 10, 'fontweight': 'bold'}
                    )
                    ax.set_title('Status Distribution', fontsize=12, fontweight='bold', pad=15)
                    self.status_chart.figure.tight_layout()
                    self.status_chart.draw()
            else:
                print("No status data available")
            
            # Top Source IPs (Horizontal Bar Chart)
            top_ips = analytics.get('top_source_ips', [])
            print(f"Top IPs: {top_ips}")
            if top_ips and len(top_ips) > 0:
                self.top_ips_chart.figure.clear()
                ax = self.top_ips_chart.figure.add_subplot(111)
                # Take top 10
                top_ips_data = top_ips[:10]
                ips = [item['ip'] for item in top_ips_data]
                counts = [item['count'] for item in top_ips_data]
                bars = ax.barh(ips, counts, color='#10b981', edgecolor='#059669', linewidth=1.5)
                ax.set_xlabel('Alert Count', fontsize=11, fontweight='bold')
                ax.set_ylabel('Source IP', fontsize=11, fontweight='bold')
                ax.set_title('Top Source IPs', fontsize=12, fontweight='bold', pad=15)
                ax.grid(axis='x', alpha=0.3, linestyle='--')
                # Add value labels on bars
                for i, (bar, count) in enumerate(zip(bars, counts)):
                    width = bar.get_width()
                    ax.text(width, bar.get_y() + bar.get_height()/2.,
                           f' {count}', ha='left', va='center', fontsize=9, fontweight='bold')
                self.top_ips_chart.figure.tight_layout()
                self.top_ips_chart.draw()
            else:
                print("No top IPs data available")
            
            # Alerts Over Time (Line Chart)
            time_series = analytics.get('alerts_over_time', [])
            print(f"Time series: {time_series}")
            if time_series and len(time_series) > 0:
                self.time_series_chart.figure.clear()
                ax = self.time_series_chart.figure.add_subplot(111)
                dates = [item['date'] for item in time_series]
                totals = [item['count'] for item in time_series]
                malicious = [item['malicious'] for item in time_series]
                benign = [item['benign'] for item in time_series]
                ax.plot(dates, totals, label='Total', color='#2563eb', linewidth=2.5, marker='o', markersize=4)
                ax.plot(dates, malicious, label='Malicious', color='#ef4444', linewidth=2.5, marker='s', markersize=4)
                ax.plot(dates, benign, label='Benign', color='#10b981', linewidth=2.5, marker='^', markersize=4)
                ax.set_xlabel('Date', fontsize=11, fontweight='bold')
                ax.set_ylabel('Alert Count', fontsize=11, fontweight='bold')
                ax.set_title('Alerts Over Time', fontsize=12, fontweight='bold', pad=15)
                ax.legend(loc='upper left', fontsize=10)
                ax.grid(alpha=0.3, linestyle='--')
                ax.tick_params(axis='x', rotation=45, labelsize=9)
                # Set horizontal alignment for rotated labels
                for label in ax.get_xticklabels():
                    label.set_ha('right')
                self.time_series_chart.figure.tight_layout()
                self.time_series_chart.draw()
            else:
                print("No time series data available")
                
        except Exception as e:
            print(f"Error loading analytics: {e}")
            import traceback
            traceback.print_exc()
            # Show error message to user
            QMessageBox.warning(self, "Analytics Error", f"Failed to load analytics: {str(e)}")
    
    def acknowledge_alert(self, alert_id):
        """Acknowledge an alert"""
        try:
            self.api_client.update_alert_status(alert_id, "ACK")
            QMessageBox.information(self, "Success", "Alert acknowledged")
            self.load_alerts()
            self.load_alerts_preview()
            self.load_analytics()
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Failed to acknowledge alert: {str(e)}")
    
    def block_ip(self, src_ip):
        """Block an IP address"""
        dialog = BlockIPDialog(src_ip, self)
        if dialog.exec_() == QDialog.Accepted:
            reason = dialog.get_reason()
            if not reason:
                QMessageBox.warning(self, "Error", "Please enter a reason")
                return
            
            try:
                self.api_client.create_block(src_ip, reason)
                QMessageBox.information(self, "Success", f"IP {src_ip} has been blocked")
                self.load_data()
            except Exception as e:
                QMessageBox.critical(self, "Error", f"Failed to block IP: {str(e)}")
    
    def save_threshold(self):
        """Save threshold value"""
        threshold = self.threshold_slider.value() / 100.0
        
        reply = QMessageBox.question(
            self, "Confirm",
            f"Change detection threshold to {threshold:.2f}?\n\nThis will affect which alerts are marked as malicious.",
            QMessageBox.Yes | QMessageBox.No
        )
        
        if reply == QMessageBox.Yes:
            try:
                self.api_client.update_threshold(threshold)
                QMessageBox.information(self, "Success", "Threshold updated successfully")
                self.load_data()
            except Exception as e:
                QMessageBox.critical(self, "Error", f"Failed to update threshold: {str(e)}")
    
    def load_blocks(self):
        """Load active block rules"""
        try:
            blocks = self.api_client.get_active_blocks()
            
            self.blocks_table.setRowCount(len(blocks))
            
            for row, block in enumerate(blocks):
                self.blocks_table.setItem(row, 0, QTableWidgetItem(block["src_ip"]))
                self.blocks_table.setItem(row, 1, QTableWidgetItem(block["reason"] or "N/A"))
                self.blocks_table.setItem(row, 2, QTableWidgetItem(
                    datetime.fromisoformat(block["applied_at"]).strftime("%Y-%m-%d %H:%M")
                ))
                
                # Deactivate button
                btn = QPushButton("Deactivate")
                btn.clicked.connect(lambda checked, b=block: self.deactivate_block(b["id"]))
                btn.setStyleSheet("background-color: #ef4444; color: white; border: none; padding: 5px;")
                self.blocks_table.setCellWidget(row, 3, btn)
        
        except Exception as e:
            print(f"Error loading blocks: {e}")
    
    def deactivate_block(self, block_id):
        """Deactivate a block rule"""
        reply = QMessageBox.question(
            self, "Confirm",
            "Deactivate this block rule?",
            QMessageBox.Yes | QMessageBox.No
        )
        
        if reply == QMessageBox.Yes:
            try:
                self.api_client.deactivate_block(block_id)
                QMessageBox.information(self, "Success", "Block rule deactivated")
                self.load_blocks()
                self.load_data()
            except Exception as e:
                QMessageBox.critical(self, "Error", f"Failed to deactivate block: {str(e)}")
    
    def load_users(self):
        """Load users list"""
        try:
            users = self.api_client.list_users()
            
            self.users_table.setRowCount(len(users))
            
            for row, user in enumerate(users):
                self.users_table.setItem(row, 0, QTableWidgetItem(user["email"]))
                self.users_table.setItem(row, 1, QTableWidgetItem(user["role"]))
                self.users_table.setItem(row, 2, QTableWidgetItem("✓ Enabled" if user["mfa_enabled"] else "✗ Disabled"))
                self.users_table.setItem(row, 3, QTableWidgetItem("Active" if user["is_active"] else "Inactive"))
                
                last_login = user.get("last_login")
                if last_login:
                    self.users_table.setItem(row, 4, QTableWidgetItem(
                        datetime.fromisoformat(last_login).strftime("%Y-%m-%d %H:%M")
                    ))
                else:
                    self.users_table.setItem(row, 4, QTableWidgetItem("Never"))
                
                # Store id hidden for actions
                self.users_table.setItem(row, 6, QTableWidgetItem(str(user["id"])))

                # Build actions widget
                btn_widget = QWidget()
                btn_layout = QHBoxLayout()
                btn_layout.setContentsMargins(5, 2, 5, 2)

                # Delete button rules:
                # - Hide for self (same email as logged-in user)
                # - Show for analysts
                # - Show for other admins (backend still prevents deleting last admin)
                can_show_delete = (user["email"] != self.user.get("email")) and (
                    user["role"] == "ANALYST" or (user["role"] == "ADMIN" and user["email"] != self.user.get("email"))
                )
                if can_show_delete:
                    del_btn = QPushButton("Delete")
                    del_btn.setStyleSheet("background-color: #ef4444; color: white; border: none; padding: 6px 10px;")
                    # Capture user id/email in lambda default args
                    del_btn.clicked.connect(lambda checked, uid=str(user["id"]), uemail=user["email"]: self.delete_user(uid, uemail))
                    btn_layout.addWidget(del_btn)

                # Role select
                role_combo = QComboBox()
                role_combo.addItems(["ANALYST", "ADMIN"])
                role_combo.setCurrentText(user["role"])
                role_combo.currentTextChanged.connect(lambda new_role, uid=str(user["id"]): self.change_user_role(uid, new_role))
                btn_layout.addWidget(role_combo)

                # Activate/Deactivate
                act_btn = QPushButton("Deactivate" if user["is_active"] else "Activate")
                act_btn.setStyleSheet("background-color: #f59e0b; color: white; border: none; padding: 6px 10px;")
                act_btn.clicked.connect(lambda checked, uid=str(user["id"]), curr=user["is_active"]: self.toggle_user_active(uid, curr))
                btn_layout.addWidget(act_btn)

                btn_widget.setLayout(btn_layout)
                self.users_table.setCellWidget(row, 5, btn_widget)
        
        except Exception as e:
            print(f"Error loading users: {e}")

    def delete_user(self, user_id: str, email: str):
        """Delete a user after confirmation"""
        if email == self.user.get("email"):
            QMessageBox.warning(self, "Not Allowed", "You cannot delete your own account.")
            return
        reply = QMessageBox.question(
            self, "Confirm Delete",
            f"Delete user {email}? This action cannot be undone.",
            QMessageBox.Yes | QMessageBox.No
        )
        if reply == QMessageBox.Yes:
            try:
                self.api_client.delete_user(user_id)
                QMessageBox.information(self, "Success", f"User {email} deleted")
                self.load_users()
            except Exception as e:
                QMessageBox.critical(self, "Error", f"Failed to delete user: {str(e)}")

    def change_user_role(self, user_id: str, new_role: str):
        """Change a user's role"""
        try:
            self.api_client.update_user(user_id, role=new_role)
            self.load_users()
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Failed to update role: {str(e)}")

    def toggle_user_active(self, user_id: str, current_status: bool):
        """Toggle user active status"""
        try:
            self.api_client.update_user(user_id, is_active=(not current_status))
            self.load_users()
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Failed to update status: {str(e)}")
    
    def create_user_dialog(self):
        """Show create user dialog"""
        if not self.is_admin:
            QMessageBox.warning(self, "Permission Denied", "Only admins can create users")
            return
        dialog = CreateUserDialog(self)
        if dialog.exec_() == QDialog.Accepted:
            email, password, role = dialog.get_values()
            if not email or not password:
                QMessageBox.warning(self, "Error", "Email and password are required")
                return
            try:
                self.api_client.create_user(email=email, password=password, role=role)
                QMessageBox.information(self, "Success", f"User {email} created")
                self.load_users()
            except Exception as e:
                QMessageBox.critical(self, "Error", f"Failed to create user: {str(e)}")
    
    def update_monitoring_status(self):
        """Update monitoring status display"""
        if not self.is_admin:
            return
        
        # Check if monitoring UI elements exist
        if not hasattr(self, 'monitoring_status_label'):
            return  # UI not yet initialized
        
        try:
            status_data = self.api_client.get_monitoring_status()
            is_monitoring = status_data.get("is_monitoring", False)
            interface = status_data.get("interface", "N/A")
            threshold = status_data.get("threshold", 0.50)
            
            # Debug logging
            print(f"[DEBUG] Status check: is_monitoring={is_monitoring}, interface={interface}, threshold={threshold}")
            print(f"[DEBUG] Full status response: {status_data}")
            
            if is_monitoring:
                self.monitoring_status_label.setText("Status: ✅ ACTIVE")
                self.monitoring_status_label.setStyleSheet("color: #10b981; font-weight: bold;")
                if hasattr(self, 'start_monitoring_btn'):
                    self.start_monitoring_btn.setEnabled(False)
                if hasattr(self, 'stop_monitoring_btn'):
                    self.stop_monitoring_btn.setEnabled(True)
                print("[DEBUG] Status updated to ACTIVE")
            else:
                self.monitoring_status_label.setText("Status: ⏸ INACTIVE")
                self.monitoring_status_label.setStyleSheet("color: #64748b; font-weight: bold;")
                if hasattr(self, 'start_monitoring_btn'):
                    self.start_monitoring_btn.setEnabled(True)
                if hasattr(self, 'stop_monitoring_btn'):
                    self.stop_monitoring_btn.setEnabled(False)
                print("[DEBUG] Status updated to INACTIVE")
            
            if hasattr(self, 'monitoring_interface_label'):
                self.monitoring_interface_label.setText(f"Interface: {interface or 'N/A'}")
            if hasattr(self, 'monitoring_threshold_label'):
                try:
                    thr_value = float(threshold) if threshold is not None else None
                except Exception:
                    thr_value = None
                if thr_value is None:
                    self.monitoring_threshold_label.setText("Threshold: Unknown")
                else:
                    self.monitoring_threshold_label.setText(f"Threshold: {thr_value:.2f}")
            
        except Exception as e:
            # More graceful error handling
            error_msg = str(e)
            if "401" in error_msg or "Unauthorized" in error_msg:
                self.monitoring_status_label.setText("Status: ⚠️ Auth Required - Try Refreshing")
                self.monitoring_status_label.setStyleSheet("color: #f59e0b; font-weight: bold;")
            elif "Connection" in error_msg or "timeout" in error_msg.lower():
                self.monitoring_status_label.setText("Status: ⚠️ Backend Unavailable")
                self.monitoring_status_label.setStyleSheet("color: #f59e0b; font-weight: bold;")
            else:
                self.monitoring_status_label.setText("Status: ⚠️ Cannot Check Status")
                self.monitoring_status_label.setStyleSheet("color: #f59e0b; font-weight: bold;")
            
            # On error, allow user to try starting (may work even if status fails)
            # But disable stop since we don't know if monitoring is running
            if hasattr(self, 'start_monitoring_btn'):
                self.start_monitoring_btn.setEnabled(True)  # Allow attempting to start
            if hasattr(self, 'stop_monitoring_btn'):
                self.stop_monitoring_btn.setEnabled(False)  # Disable stop if status unknown
            
            # Clear interface/threshold on error
            if hasattr(self, 'monitoring_interface_label'):
                self.monitoring_interface_label.setText("Interface: Unknown")
            if hasattr(self, 'monitoring_threshold_label'):
                self.monitoring_threshold_label.setText("Threshold: Unknown")
            
            print(f"[ERROR] Error updating monitoring status: {e}")
            import traceback
            traceback.print_exc()
    
    def start_monitoring(self):
        """Start traffic monitoring"""
        # Get interface (default to eth0)
        import subprocess
        try:
            # Prefer capturing on all interfaces to avoid VM/NAT confusion
            default_iface = "any"
            # Fallback to detected default route interface if needed
            result = subprocess.run(['ip', 'route'], capture_output=True, text=True, timeout=2)
            for line in result.stdout.split('\n'):
                if 'default' in line and 'dev' in line:
                    parts = line.split()
                    if 'dev' in parts:
                        idx = parts.index('dev')
                        if idx + 1 < len(parts):
                            default_iface = parts[idx + 1] or default_iface
                            break
        except:
            default_iface = "any"
        
        # Get threshold from current threshold card
        current_threshold = 0.50
        try:
            threshold_text = self.threshold_card.value_label.text()
            current_threshold = float(threshold_text)
        except:
            pass
        
        reply = QMessageBox.question(
            self, "Start Monitoring",
            f"Start traffic monitoring?\n\n"
            f"Interface: {default_iface}\n"
            f"Threshold: {current_threshold:.2f}\n\n"
            f"This will begin real-time DDoS detection.",
            QMessageBox.Yes | QMessageBox.No
        )
        
        if reply == QMessageBox.Yes:
            try:
                self.api_client.start_monitoring(interface=default_iface, threshold=current_threshold)
                
                # Give backend a moment to start the monitoring thread
                # Retry status check a few times with delays (non-blocking)
                def check_status_attempt(attempt_num=1, max_attempts=6):
                    """Check status with retries (non-blocking)"""
                    print(f"[DEBUG] Status check attempt {attempt_num}/{max_attempts}")
                    try:
                        status_data = self.api_client.get_monitoring_status()
                        print(f"[DEBUG] Status response on attempt {attempt_num}: {status_data}")
                        if status_data.get("is_monitoring", False):
                            # Status is now active, update UI
                            print("[DEBUG] Monitoring is active, updating UI")
                            self.update_monitoring_status()
                            return
                    except Exception as e:
                        print(f"[DEBUG] Status check error on attempt {attempt_num}: {e}")
                    
                    # Schedule next attempt if not exceeded max attempts
                    if attempt_num < max_attempts:
                        QTimer.singleShot(1000, lambda: check_status_attempt(attempt_num + 1, max_attempts))
                    else:
                        # Final attempt after all retries
                        print("[DEBUG] Final status update after all retries")
                        self.update_monitoring_status()
                
                # Start retry checks after initial delay (increased to 1 second)
                QTimer.singleShot(1000, lambda: check_status_attempt(1, 6))  # 6 attempts with 1s delays
                
                QMessageBox.information(
                    self, 
                    "Success", 
                    f"Monitoring started successfully!\n\n"
                    f"Interface: {default_iface}\n"
                    f"Threshold: {current_threshold:.2f}\n\n"
                    f"You can now launch DDoS attacks from Kali VM to test detection."
                )
                
                # Also update immediately (optimistic update)
                self.update_monitoring_status()
                
            except Exception as e:
                QMessageBox.critical(self, "Error", f"Failed to start monitoring:\n{str(e)}")
                self.update_monitoring_status()
    
    def stop_monitoring(self):
        """Stop traffic monitoring"""
        reply = QMessageBox.question(
            self, "Stop Monitoring",
            "Stop traffic monitoring?",
            QMessageBox.Yes | QMessageBox.No
        )
        
        if reply == QMessageBox.Yes:
            try:
                self.api_client.stop_monitoring()
                
                # Stop should be immediate, but add small delay to ensure backend processes it
                QTimer.singleShot(300, self.update_monitoring_status)
                
                QMessageBox.information(self, "Success", "Monitoring stopped successfully")
                
                # Update immediately
                self.update_monitoring_status()
                
            except Exception as e:
                QMessageBox.critical(self, "Error", f"Failed to stop monitoring:\n{str(e)}")
                self.update_monitoring_status()
    
    def refresh_data(self):
        """Refresh all data (called by timer)"""
        try:
            self.load_data()
            if self.is_admin and hasattr(self, 'update_monitoring_status'):
                self.update_monitoring_status()
        except:
            pass
    
    def logout(self):
        """Logout user"""
        reply = QMessageBox.question(
            self, "Confirm Logout",
            "Are you sure you want to logout?",
            QMessageBox.Yes | QMessageBox.No
        )
        
        if reply == QMessageBox.Yes:
            self.api_client.logout()
            self.close()
            
            # Show login window again
            from login_window import LoginWindow
            self.login_window = LoginWindow()
            self.login_window.show()

