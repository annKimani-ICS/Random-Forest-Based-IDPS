#!/bin/bash
# Quick Fix for BaseModel Import Error
# This script quickly fixes the specific ImportError: cannot import name 'BaseModel' from 'pydantic'

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}🚨 Quick Fix for BaseModel Import Error${NC}"
echo "=============================================="

# Get current directory
CURRENT_DIR="$(pwd)"
echo -e "${BLUE}📁 Current directory: $CURRENT_DIR${NC}"

# Check if backend directory exists
if [ ! -d "backend" ]; then
    echo -e "${RED}❌ Backend directory not found${NC}"
    exit 1
fi

cd backend

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo -e "${RED}❌ Virtual environment not found${NC}"
    exit 1
fi

# Activate virtual environment
source .venv/bin/activate

echo -e "${YELLOW}🔧 Quick Fix: Downgrading Pydantic to v1...${NC}"

# Uninstall current pydantic
echo -e "${BLUE}Uninstalling current Pydantic...${NC}"
pip uninstall -y pydantic pydantic-settings || true

# Install Pydantic v1
echo -e "${BLUE}Installing Pydantic v1...${NC}"
pip install "pydantic<2.0.0"

# Test the fix
echo -e "${BLUE}Testing BaseModel import...${NC}"
if python -c "from pydantic import BaseModel; print('✅ BaseModel imported successfully')" 2>/dev/null; then
    echo -e "${GREEN}✅ Fix successful! BaseModel can now be imported${NC}"
else
    echo -e "${RED}❌ Fix failed${NC}"
    exit 1
fi

# Test FastAPI import
echo -e "${BLUE}Testing FastAPI import...${NC}"
if python -c "from fastapi import FastAPI; print('✅ FastAPI imported successfully')" 2>/dev/null; then
    echo -e "${GREEN}✅ FastAPI import works${NC}"
else
    echo -e "${RED}❌ FastAPI import failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Quick Fix Complete!${NC}"
echo "=================================="
echo -e "${BLUE}📋 What was fixed:${NC}"
echo "   ✅ Pydantic downgraded to v1"
echo "   ✅ BaseModel import works"
echo "   ✅ FastAPI import works"
echo ""
echo -e "${BLUE}🚀 Now you can start the backend:${NC}"
echo "  uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"
echo ""
echo -e "${GREEN}🎯 BaseModel import error resolved!${NC}"
