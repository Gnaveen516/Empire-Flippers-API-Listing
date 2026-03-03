#!/bin/bash

# Quick Start Script for EF Challenge
# This script helps you run all required services

echo "🚀 Starting Empire Flippers Challenge Application"
echo ""

# Check if Redis is running
if ! pgrep -x "redis-server" > /dev/null; then
    echo "⚠️  Redis is not running!"
    echo "Please start Redis first:"
    echo "  macOS: brew services start redis"
    echo "  Linux: sudo service redis-server start"
    echo "  Or run: redis-server"
    exit 1
fi

echo "✅ Redis is running"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found!"
    echo "Creating .env file..."
    echo "HUBSPOT_ACCESS_TOKEN=your_token_here" > .env
    echo "Please update .env with your HubSpot token"
fi

echo "✅ Environment configured"
echo ""

echo "Starting Sidekiq..."
echo "Sidekiq will run the sync job daily at midnight"
echo ""
echo "To manually trigger sync, run in another terminal:"
echo "  rails runner 'EfSyncService.sync'"
echo ""

bundle exec sidekiq
