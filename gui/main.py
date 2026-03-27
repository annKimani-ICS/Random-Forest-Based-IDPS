#!/usr/bin/env python3
"""
IDS/IDPS Desktop GUI Application
Main entry point
"""
import sys
from PyQt5.QtWidgets import QApplication
from PyQt5.QtCore import Qt
from login_window import LoginWindow

def main():
    # Enable High DPI scaling
    QApplication.setAttribute(Qt.AA_EnableHighDpiScaling, True)
    QApplication.setAttribute(Qt.AA_UseHighDpiPixmaps, True)
    
    app = QApplication(sys.argv)
    app.setApplicationName("IDS/IDPS Admin")
    app.setOrganizationName("IDS-IDPS")
    
    # Set application style
    app.setStyle("Fusion")
    
    # Show login window
    login_window = LoginWindow()
    login_window.show()
    
    sys.exit(app.exec_())

if __name__ == "__main__":
    main()

