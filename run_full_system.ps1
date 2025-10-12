# Full system startup script for Windows PowerShell
# Usage: .\run_full_system.ps1

$ErrorActionPreference = "Stop"

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"
$Magenta = "Magenta"

Write-Host "🚀 Starting Full IDS/IDPS System" -ForegroundColor $Magenta
Write-Host "==================================" -ForegroundColor $Magenta

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectDir = $ScriptDir

# Check if virtual environment exists
if (-not (Test-Path "$ProjectDir\venv")) {
    Write-Host "⚠️ Virtual environment not found. Run .\setup.ps1 first" -ForegroundColor $Yellow
    exit 1
}

# Function to cleanup on exit
function Cleanup {
    Write-Host "`n🛑 Shutting down..." -ForegroundColor $Yellow
    # Kill any running processes
    Get-Process | Where-Object {$_.ProcessName -eq "python" -and $_.CommandLine -like "*uvicorn*"} | Stop-Process -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Cleanup complete" -ForegroundColor $Green
    exit 0
}

# Set up signal handlers
Register-EngineEvent PowerShell.Exiting -Action { Cleanup }

# Start backend in background
Write-Host "🔧 Starting backend server..." -ForegroundColor $Blue
& "$ProjectDir\venv\Scripts\Activate.ps1"
Set-Location "$ProjectDir\backend"

# Start backend in background job
$BackendJob = Start-Job -ScriptBlock {
    Set-Location $args[0]
    & $args[1]
    uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
} -ArgumentList "$ProjectDir\backend", "$ProjectDir\venv\Scripts\Activate.ps1"

# Wait for backend to start
Write-Host "⏳ Waiting for backend to start..." -ForegroundColor $Yellow
$BackendStarted = $false
for ($i = 1; $i -le 30; $i++) {
    try {
        $Response = Invoke-WebRequest -Uri "http://localhost:8000/docs" -TimeoutSec 2 -UseBasicParsing
        Write-Host "✅ Backend started successfully" -ForegroundColor $Green
        $BackendStarted = $true
        break
    } catch {
        if ($i -eq 30) {
            Write-Host "❌ Backend failed to start" -ForegroundColor $Red
            Stop-Job $BackendJob -ErrorAction SilentlyContinue
            Remove-Job $BackendJob -ErrorAction SilentlyContinue
            exit 1
        }
        Start-Sleep -Seconds 1
    }
}

# Start GUI
Write-Host "🖥️ Starting GUI application..." -ForegroundColor $Blue
Set-Location "$ProjectDir\gui"
& "$ProjectDir\venv\Scripts\Activate.ps1"

Write-Host ""
Write-Host "🎉 Full system started!" -ForegroundColor $Green
Write-Host "==================================" -ForegroundColor $Green
Write-Host "Backend: http://localhost:8000" -ForegroundColor $Blue
Write-Host "API Docs: http://localhost:8000/docs" -ForegroundColor $Blue
Write-Host "GUI: Desktop application" -ForegroundColor $Blue
Write-Host ""
Write-Host "Press Ctrl+C to stop both services" -ForegroundColor $Yellow

# Start GUI (this will block)
python main.py

# Cleanup when GUI exits
Cleanup

