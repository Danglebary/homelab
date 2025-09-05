#!/usr/bin/env bash
set -euo pipefail

# Generic service deployment script
# Usage: ./scripts/ensure-service.sh <service-name> <service-path>

if [ $# -ne 2 ]; then
    echo "Usage: $0 <service-name> <service-path>"
    exit 1
fi

SERVICE_NAME="$1"
SERVICE_PATH="$2"

echo "Checking $SERVICE_NAME service status..."

# Check if container is already running
if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "^$SERVICE_NAME\s.*Up"; then
    echo "  $SERVICE_NAME is already running"
    exit 0
fi

echo "  $SERVICE_NAME is not running - starting service..."
cd "$SERVICE_PATH"
docker compose up -d --wait

echo "  $SERVICE_NAME started successfully"