#!/usr/bin/env python3
"""
Simple database setup script for Ubuntu VM
This creates the database and user if they don't exist
"""
import subprocess
import sys
import os

def run_command(cmd, check=True):
    """Run a shell command"""
    print(f"Running: {cmd}")
    try:
        result = subprocess.run(cmd, shell=True, check=check, capture_output=True, text=True)
        if result.stdout:
            print(result.stdout)
        return result
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")
        if e.stderr:
            print(f"Stderr: {e.stderr}")
        return e

def setup_database():
    """Setup PostgreSQL database and user"""
    print("🔧 Setting up PostgreSQL database...")
    
    # Check if PostgreSQL is installed
    result = run_command("which psql", check=False)
    if result.returncode != 0:
        print("❌ PostgreSQL not found. Installing...")
        run_command("sudo apt update")
        run_command("sudo apt install -y postgresql postgresql-contrib")
    
    # Start PostgreSQL service
    print("🚀 Starting PostgreSQL service...")
    run_command("sudo systemctl start postgresql")
    run_command("sudo systemctl enable postgresql")
    
    # Create database and user
    print("📊 Creating database and user...")
    
    # Switch to postgres user and create database
    commands = [
        "sudo -u postgres psql -c \"CREATE DATABASE ids_db;\"",
        "sudo -u postgres psql -c \"CREATE USER ids_user WITH PASSWORD 'ids_password';\"",
        "sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE ids_db TO ids_user;\"",
        "sudo -u postgres psql -c \"ALTER USER ids_user CREATEDB;\""
    ]
    
    for cmd in commands:
        result = run_command(cmd, check=False)
        if result.returncode != 0 and "already exists" not in str(result.stderr):
            print(f"⚠️  Command failed (may already exist): {cmd}")
    
    print("✅ Database setup complete!")
    print("\n📋 Database credentials:")
    print("   - Database: ids_db")
    print("   - User: ids_user")
    print("   - Password: ids_password")
    print("   - Host: localhost")
    print("   - Port: 5432")

if __name__ == "__main__":
    setup_database()
