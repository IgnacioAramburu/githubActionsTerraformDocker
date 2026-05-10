# Build stage
FROM python:3.10-alpine AS builder

WORKDIR /app

# Instalar dependencias del sistema
RUN apk add --no-cache \
    gcc \
    musl-dev \
    linux-headers

# Copiar archivos de dependencias
COPY requirements.txt .
COPY pyproject.toml .

# Instalar dependencias Python
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir pytest pytest-asyncio pylint black

# Copiar código fuente
COPY src/ ./src/

# Linting y tests
RUN pylint src/server.py --disable=C0103,R0913 || true && \
    black --check src/ 2>/dev/null || true && \
    pytest src/test_server.py -v

# Production stage
FROM python:3.10-alpine

WORKDIR /app

# Instalar dependencias del sistema para runtime
RUN apk add --no-cache \
    ca-certificates \
    curl

# Crear usuario no-root
RUN addgroup -g 1001 -S appuser && \
    adduser -S appuser -u 1001

# Copiar dependencias desde builder
COPY --from=builder /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copiar código fuente
COPY src/ ./src/

# Cambiar permisos y usuario
RUN chown -R appuser:appuser /app
USER appuser

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Exponer puerto
EXPOSE 3000

# Variables de entorno
ENV PYTHONUNBUFFERED=1
ENV ENV=production
ENV PORT=3000
ENV HOST=0.0.0.0

# Iniciar aplicación
CMD ["python", "-m", "uvicorn", "src.server:app", "--host", "0.0.0.0", "--port", "3000"]
