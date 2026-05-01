#!/bin/bash

# NoteFlow Backend Startup Script

echo "=================================="
echo "NoteFlow Backend Startup"
echo "=================================="
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.8 or higher."
    exit 1
fi

echo "✓ Python 3 found"

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 is not installed. Please install pip."
    exit 1
fi

echo "✓ pip3 found"

# Install dependencies
echo ""
echo "Installing dependencies..."
pip3 install -r requirements.txt

# Check if MongoDB is accessible
echo ""
echo "Checking MongoDB connection..."
python3 -c "from motor.motor_asyncio import AsyncIOMotorClient; import asyncio; asyncio.run(AsyncIOMotorClient('mongodb://localhost:27017/').admin.command('ping'))" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✓ MongoDB is accessible"
else
    echo "⚠️  Warning: Could not connect to MongoDB at localhost:27017"
    echo "   Make sure MongoDB is running or set MONGODB_URL environment variable"
fi

# Initialize database
echo ""
echo "Initializing database..."
python3 init_db.py

# Start the server
echo ""
echo "=================================="
echo "Starting FastAPI server..."
echo "=================================="
echo ""
echo "API will be available at:"
echo "  - Local: http://localhost:8000"
echo "  - Android Emulator: http://10.0.2.2:8000"
echo "  - API Docs: http://localhost:8000/docs"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

uvicorn main:app --reload --host 0.0.0.0 --port 8000
