from fastapi import APIRouter
from datetime import datetime
import redis
import psycopg2

router = APIRouter()

@router.get("/healthz")
async def health_check():
    checks = {}

    # Database check
    try:
        conn = psycopg2.connect(os.environ["DATABASE_URL"])
        conn.close()
        checks["database"] = "ok"
    except Exception as e:
        checks["database"] = f"error: {str(e)}"

    # Redis check
    try:
        r = redis.from_url(os.environ["REDIS_URL"])
        r.ping()
        checks["redis"] = "ok"
    except Exception as e:
        checks["redis"] = f"error: {str(e)}"

    all_healthy = all(v == "ok" for v in checks.values())

    return {
        "status": "healthy" if all_healthy else "degraded",
        "timestamp": datetime.utcnow().isoformat(),
        "checks": checks,
        "version": os.environ.get("APP_VERSION", "unknown")
    }
