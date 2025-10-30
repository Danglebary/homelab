#!/usr/bin/env bash
set -euo pipefail

# Generic service stop script
# Usage: ./scripts/stop-service.sh <service-name>

if [ $# -ne 1 ]; then
    echo "Usage: $0 <service-name>"
    exit 1
fi

SERVICE_NAME="$1"

echo "Checking $SERVICE_NAME service status..."

# Check if container is running
if ! docker compose ls --format '{{.Name}}' | grep -qx "$SERVICE_NAME"; then
    echo "  $SERVICE_NAME is already stopped"
    exit 0
fi


echo "  $SERVICE_NAME is running - stopping service..."
cd "services/$SERVICE_NAME"
docker compose down -v --remove-orphans

echo "  $SERVICE_NAME stopped successfully"