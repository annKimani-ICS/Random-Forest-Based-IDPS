# Complete project setup script for Windows PowerShell
# Usage: .\setup.ps1

param(
    [switch]$Force
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"
$Magenta = "Magenta"

Write-Host "🚀 IDS/IDPS Project Setup (Windows)" -ForegroundColor $Magenta
Write-Host "==================================" -ForegroundColor $Magenta

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectDir = $ScriptDir

Write-Host "📁 Project directory: $ProjectDir" -ForegroundColor $Blue

# Check Python version
Write-Host "🐍 Checking Python version..." -ForegroundColor $Blue
try {
    $PythonVersion = python --version 2>&1
    Write-Host "✅ Python found: $PythonVersion" -ForegroundColor $Green
} catch {
    Write-Host "❌ Python not found. Please install Python 3.8+" -ForegroundColor $Red
    exit 1
}

# Check if git repository
if (-not (Test-Path ".git")) {
    Write-Host "⚠️ Not a git repository" -ForegroundColor $Yellow
    Write-Host "Consider running: git init" -ForegroundColor $Yellow
}

# Create virtual environment
Write-Host "📦 Setting up virtual environment..." -ForegroundColor $Blue
if (Test-Path "venv") {
    if ($Force) {
        Write-Host "🗑️ Removing existing virtual environment..." -ForegroundColor $Yellow
        Remove-Item -Recurse -Force venv
        python -m venv venv
        Write-Host "✅ Virtual environment recreated" -ForegroundColor $Green
    } else {
        Write-Host "⚠️ Virtual environment already exists" -ForegroundColor $Yellow
        $Recreate = Read-Host "Recreate? (y/N)"
        if ($Recreate -eq 'y' -or $Recreate -eq 'Y') {
            Remove-Item -Recurse -Force venv
            python -m venv venv
            Write-Host "✅ Virtual environment recreated" -ForegroundColor $Green
        }
    }
} else {
    python -m venv venv
    Write-Host "✅ Virtual environment created" -ForegroundColor $Green
}

# Activate virtual environment
Write-Host "🔌 Activating virtual environment..." -ForegroundColor $Blue
& ".\venv\Scripts\Activate.ps1"

# Upgrade pip
Write-Host "⬆️ Upgrading pip..." -ForegroundColor $Blue
python -m pip install --upgrade pip

# Install backend requirements
Write-Host "📥 Installing backend dependencies..." -ForegroundColor $Blue
Set-Location backend
pip install -r requirements.txt
Write-Host "✅ Backend dependencies installed" -ForegroundColor $Green

# Install GUI requirements
Write-Host "📥 Installing GUI dependencies..." -ForegroundColor $Blue
Set-Location ..\gui
pip install -r requirements.txt
Write-Host "✅ GUI dependencies installed" -ForegroundColor $Green

Set-Location ..

# Test imports
Write-Host "🧪 Testing installation..." -ForegroundColor $Blue
Set-Location backend
try {
    python -c "import fastapi, uvicorn, sqlalchemy, pyotp; print('✅ Backend imports OK')"
} catch {
    Write-Host "❌ Backend import test failed" -ForegroundColor $Red
}

Set-Location ..\gui
try {
    python -c "import PyQt5, qrcode, requests; print('✅ GUI imports OK')"
} catch {
    Write-Host "❌ GUI import test failed" -ForegroundColor $Red
}

Set-Location ..

Write-Host ""
Write-Host "🎉 Setup Complete!" -ForegroundColor $Green
Write-Host "==================================" -ForegroundColor $Green
Write-Host ""
Write-Host "🚀 Quick Start Commands:" -ForegroundColor $Magenta
Write-Host ""
Write-Host "Start Backend:" -ForegroundColor $Blue
Write-Host "  .\run_backend.ps1" -ForegroundColor $Blue
Write-Host ""
Write-Host "Start GUI (in new terminal):" -ForegroundColor $Blue
Write-Host "  .\run_gui.ps1" -ForegroundColor $Blue
Write-Host ""
Write-Host "Manual activation:" -ForegroundColor $Blue
Write-Host "  .\venv\Scripts\Activate.ps1" -ForegroundColor $Blue
Write-Host ""
Write-Host "📚 Documentation:" -ForegroundColor $Magenta
Write-Host "  README.md - Main project documentation" -ForegroundColor $Magenta
Write-Host "  README_MFA.md - MFA setup guide" -ForegroundColor $Magenta
Write-Host "  QUICK_START_MFA.md - Quick MFA guide" -ForegroundColor $Magenta
Write-Host ""
Write-Host "Happy coding! 🎊" -ForegroundColor $Green

