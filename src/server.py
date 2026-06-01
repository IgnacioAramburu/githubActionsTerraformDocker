"""
DevOps Pipeline - Aplicación FastAPI con Prometheus
Autor: DevOps Team
Versión: 1.0.0
"""

from datetime import datetime
import logging
import os
import sys
import time

from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from prometheus_client import CollectorRegistry, Counter, Histogram, generate_latest

# Logging setup
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

# Prometheus metrics setup
registry = CollectorRegistry()

http_request_counter = Counter(
    "http_requests_total",
    "Total number of HTTP requests",
    ["method", "route", "status_code"],
    registry=registry,
)

http_request_duration = Histogram(
    "http_request_duration_ms",
    "Duration of HTTP requests in ms",
    ["method", "route", "status_code"],
    buckets=[0.1, 5, 15, 50, 100, 500],
    registry=registry,
)

# FastAPI app setup
app = FastAPI(
    title="DevOps Pipeline API",
    description="Aplicación DevOps con GitHub Actions, Terraform y Docker",
    version="1.0.0",
)


# Middleware para metricas
@app.middleware("http")
async def metrics_middleware(request, call_next):
    """Middleware para recolectar métricas de Prometheus"""
    start_time = time.time()

    try:
        response = await call_next(request)
        status_code = response.status_code
    except Exception as e:
        logger.error("Error procesando request: %s", e)
        status_code = 500
        raise

    # Calcular duración
    process_time = (time.time() - start_time) * 1000

    # Registrar métricas
    http_request_counter.labels(
        method=request.method, route=request.url.path, status_code=status_code
    ).inc()

    http_request_duration.labels(
        method=request.method, route=request.url.path, status_code=status_code
    ).observe(process_time)

    # Log request details
    logger.info("%s %s - %d - %.2fms", request.method, request.url.path, status_code, process_time)

    return response


# Rutas API
@app.get("/")
async def root():
    """Ruta principal - Health check"""
    return {
        "message": "DevOps Pipeline - GitHub Actions + Terraform + Docker",
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "version": "1.0.0",
    }


@app.get("/health")
async def health():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "uptime": time.time(),
        "timestamp": datetime.utcnow().isoformat(),
    }


@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    return generate_latest(registry).decode("utf-8")


@app.get("/api/info")
@app.get("/info")
async def info():
    """Información de la aplicación y sistema"""
    return {
        "app": "DevOps Pipeline",
        "environment": os.getenv("ENV", "development"),
        "python_version": (
            f"{sys.version_info.major}.{sys.version_info.minor}." f"{sys.version_info.micro}"
        ),
        "timestamp": datetime.utcnow().isoformat(),
    }


@app.post("/api/echo")
async def echo(data: dict):
    """Echo endpoint - Retorna los datos recibidos"""
    if not data:
        raise HTTPException(status_code=400, detail="Empty body")

    return {
        "received": data,
        "timestamp": datetime.utcnow().isoformat(),
    }


@app.get("/api/status/{service}")
async def service_status(service: str):
    """Status de un servicio específico"""
    valid_services = ["app", "prometheus", "grafana"]

    if service not in valid_services:
        error_detail = f"Servicio '{service}' no válido. " f"Opciones: {valid_services}"
        raise HTTPException(status_code=400, detail=error_detail)

    return {
        "service": service,
        "status": "operational",
        "timestamp": datetime.utcnow().isoformat(),
    }


# Error handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(_request, exc):
    """Manejador de excepciones HTTP"""
    logger.warning("HTTP Exception: %s", exc.detail)
    return JSONResponse(status_code=exc.status_code, content={"error": exc.detail})


@app.exception_handler(Exception)
async def general_exception_handler(_request, exc):
    """Manejador general de excepciones"""
    logger.error("General Exception: %s", str(exc), exc_info=True)
    return JSONResponse(status_code=500, content={"error": "Internal Server Error"})


# Startup events
@app.on_event("startup")
async def startup_event():
    """Event ejecutado al iniciar la aplicación"""
    logger.info("✓ Aplicación iniciada")
    logger.info("✓ Métricas disponibles en /metrics")
    logger.info("✓ Documentación en /docs")


@app.on_event("shutdown")
async def shutdown_event():
    """Event ejecutado al cerrar la aplicación"""
    logger.info("✓ Aplicación cerrada")


if __name__ == "__main__":
    import uvicorn

    port = int(os.getenv("PORT", "3000"))
    host = os.getenv("HOST", "0.0.0.0")

    uvicorn.run(app, host=host, port=port, log_level="info")
