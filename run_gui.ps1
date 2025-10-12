# GUI startup script for Windows PowerShell
# Usage: .\run_gui.ps1

$ErrorActionPreference = "Stop"

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"

Write-Host "🖥️ Starting IDS/IDPS Desktop GUI" -ForegroundColor $Blue
Write-Host "==================================" -ForegroundColor $Blue

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectDir = $ScriptDir

# Check if we're in the right directory
if (-not (Test-Path "$ProjectDir\gui\main.py")) {
    Write-Host "❌ Error: gui\main.py not found" -ForegroundColor $Red
    Write-Host "Please run this script from the project root directory" -ForegroundColor $Red
    exit 1
}

# Check if virtual environment exists
if (-not (Test-Path "$ProjectDir\venv")) {
    Write-Host "⚠️ Virtual environment not found. Creating one..." -ForegroundColor $Yellow
    python -m venv "$ProjectDir\venv"
    Write-Host "✅ Virtual environment created" -ForegroundColor $Green
}

# Activate virtual environment
Write-Host "🔌 Activating virtual environment..." -ForegroundColor $Blue
& "$ProjectDir\venv\Scripts\Activate.ps1"

# Check if requirements are installed
Write-Host "📦 Checking GUI dependencies..." -ForegroundColor $Blue
Set-Location "$ProjectDir\gui"

try {
    python -c "import PyQt5" 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "PyQt5 not installed"
    }
} catch {
    Write-Host "⚠️ GUI dependencies not installed. Installing..." -ForegroundColor $Yellow
    pip install -r requirements.txt
    Write-Host "✅ GUI dependencies installed" -ForegroundColor $Green
}

# Check if backend is running
Write-Host "🔍 Checking backend connection..." -ForegroundColor $Blue
try {
    $Response = Invoke-WebRequest -Uri "http://localhost:8000/docs" -TimeoutSec 5 -UseBasicParsing
    Write-Host "✅ Backend server detected" -ForegroundColor $Green
} catch {
    Write-Host "⚠️ Backend server not detected at http://localhost:8000" -ForegroundColor $Yellow
    Write-Host "Please start the backend first: .\run_backend.ps1" -ForegroundColor $Yellow
    Write-Host ""
    $Continue = Read-Host "Continue anyway? (y/N)"
    if ($Continue -ne 'y' -and $Continue -ne 'Y') {
        Write-Host "❌ Exiting. Start backend first with: .\run_backend.ps1" -ForegroundColor $Red
        exit 1
    }
}

# Start the GUI
Write-Host "🌟 Starting PyQt5 GUI application..." -ForegroundColor $Green
Write-Host "==================================" -ForegroundColor $Blue

python main.py

