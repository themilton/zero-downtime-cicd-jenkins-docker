#!/bin/bash
# scripts/rollback.sh

set -euo pipefail

echo "[$(date)] ROLLBACK INITIATED"

NGINX_CONF="/etc/nginx/conf.d/app.conf"
CURRENT=$(grep -oP 'upstream_\K(blue|green)' $NGINX_CONF | head -1)

if [ "$CURRENT" = "blue" ]; then
    ROLLBACK_TO="green"
else
    ROLLBACK_TO="blue"
fi

# Check if the previous container is still running
if docker ps --format '{{.Names}}' | grep -q "app_${ROLLBACK_TO}"; then
    echo "Previous container app_${ROLLBACK_TO} is still running. Quick rollback!"
    sed -i "s/upstream_${CURRENT}/upstream_${ROLLBACK_TO}/g" $NGINX_CONF
    nginx -t && nginx -s reload
    echo "[$(date)] Rolled back to app_${ROLLBACK_TO} in <5 seconds"
else
    echo "Previous container stopped. Starting from last known good image..."
    docker compose -f docker-compose.prod.yml up -d "app_${ROLLBACK_TO}"
    sleep 10
    sed -i "s/upstream_${CURRENT}/upstream_${ROLLBACK_TO}/g" $NGINX_CONF
    nginx -t && nginx -s reload
    echo "[$(date)] Rolled back to app_${ROLLBACK_TO} (cold start: ~15 seconds)"
fi
