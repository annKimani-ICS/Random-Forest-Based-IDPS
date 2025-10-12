# Backend startup script for Windows PowerShell
# Usage: .\run_backend.ps1

$ErrorActionPreference = "Stop"

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"

Write-Host "🚀 Starting IDS/IDPS Backend Server" -ForegroundColor $Blue
Write-Host "==================================" -ForegroundColor $Blue

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectDir = $ScriptDir

# Check if we're in the right directory
if (-not (Test-Path "$ProjectDir\backend\app\main.py")) {
    Write-Host "❌ Error: backend\app\main.py not found" -ForegroundColor $Red
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
Write-Host "📦 Checking dependencies..." -ForegroundColor $Blue
Set-Location "$ProjectDir\backend"

try {
    python -c "import fastapi" 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "FastAPI not installed"
    }
} catch {
    Write-Host "⚠️ Dependencies not installed. Installing..." -ForegroundColor $Yellow
    pip install -r requirements.txt
    Write-Host "✅ Dependencies installed" -ForegroundColor $Green
}

# Start the backend server
Write-Host "🌟 Starting FastAPI backend server..." -ForegroundColor $Green
Write-Host "Server will be available at: http://localhost:8000" -ForegroundColor $Blue
Write-Host "API documentation: http://localhost:8000/docs" -ForegroundColor $Blue
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor $Yellow
Write-Host "==================================" -ForegroundColor $Blue

# Start uvicorn
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

