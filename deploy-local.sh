#!/bin/bash

# SkySense Local Development Deployment
echo "🚀 Deploying SkySense locally with Docker Compose..."

# Build and start services
docker-compose down
docker-compose up --build -d

echo "✅ Deployment completed!"
echo ""
echo "📊 Access your application:"
echo "   Frontend: http://localhost:4200"
echo "   Backend API: http://localhost:8000"
echo "   Backend WebSocket: ws://localhost:8000/ws/sensors"
echo ""
echo "🔍 View logs:"
echo "   docker-compose logs -f frontend"
echo "   docker-compose logs -f backend"