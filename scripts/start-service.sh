#!/usr/bin/env bash
set -euo pipefail

# Generic service deployment script
# Usage: ./scripts/start-service.sh <service-name>

if [ $# -ne 1 ]; then
    echo "Usage: $0 <service-name>"
    exit 1
fi

SERVICE_NAME="$1"

echo "Checking $SERVICE_NAME service status..."

# Check if container is already running
if docker compose ls --format '{{.Name}}' | grep -qx "$SERVICE_NAME"; then
    echo "  $SERVICE_NAME is already running"
    exit 0
fi

echo "  $SERVICE_NAME is not running - starting service..."
cd "services/$SERVICE_NAME"
docker compose up -d --wait

echo "  $SERVICE_NAME started successfully"