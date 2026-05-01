#!/bin/bash
# scripts/blue-green-swap.sh

set -euo pipefail

NGINX_CONF="/etc/nginx/conf.d/app.conf"
CURRENT=$(grep -oP 'upstream_\K(blue|green)' $NGINX_CONF | head -1)

if [ "$CURRENT" = "blue" ]; then
    NEW="green"
else
    NEW="blue"
fi

echo "[$(date)] Swapping from $CURRENT to $NEW"

# Start the new container
docker compose -f docker-compose.prod.yml up -d "app_${NEW}"

# Wait for new container to be healthy
echo "Waiting for app_${NEW} to pass health check..."
for i in $(seq 1 20); do
    if curl -sf "http://localhost:${NEW_PORT}/healthz" > /dev/null 2>&1; then
        echo "app_${NEW} is healthy after ${i} attempts"
        break
    fi
    if [ "$i" -eq 20 ]; then
        echo "FATAL: app_${NEW} failed health check"
        docker compose -f docker-compose.prod.yml stop "app_${NEW}"
        exit 1
    fi
    sleep 2
done

# Swap Nginx upstream
sed -i "s/upstream_${CURRENT}/upstream_${NEW}/g" $NGINX_CONF
nginx -t && nginx -s reload

echo "[$(date)] Traffic now routing to app_${NEW}"

# Keep old container running for 60s in case we need quick rollback
echo "Keeping app_${CURRENT} alive for 60s as rollback safety net..."
sleep 60
docker compose -f docker-compose.prod.yml stop "app_${CURRENT}"
echo "[$(date)] Stopped app_${CURRENT}. Deployment complete."
