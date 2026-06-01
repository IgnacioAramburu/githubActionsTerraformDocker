# Docker Compose Deployment - Local Development

## 📦 Servicios Incluidos

| Servicio | Puerto | Descripción |
|----------|--------|-------------|
| FastAPI App | 3000 | API Python FastAPI |
| Prometheus | 9090 | Métricas/Scraping |
| Grafana | 3001 | Dashboards |

## 🚀 Quick Start

```bash
# Clonar
git clone https://github.com/IgnacioAramburu/githubActionsTerraformDocker.git
cd githubActionsTerraformDocker

# Iniciar
docker-compose up -d

# Verificar
docker-compose ps
curl http://localhost:3000/health

# Ver logs
docker-compose logs -f app
```

## 🏗️ Arquitectura docker-compose.yml

```yaml
version: '3.8'
services:
  app:
    build: ./docker/Dockerfile
    ports:
      - "3000:3000"
    environment:
      - ENV=development
  
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
  
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
```

## 🔧 Operaciones Comunes

### Ver logs
```bash
# Todo
docker-compose logs

# Específico
docker-compose logs app
docker-compose logs prometheus
docker-compose logs grafana
```

### Reiniciar servicios
```bash
docker-compose restart app
docker-compose restart prometheus
docker-compose restart grafana
```

### Detener
```bash
docker-compose stop
```

### Eliminar
```bash
docker-compose down
# Con volúmenes
docker-compose down -v
```

### Rebuild
```bash
docker-compose build --no-cache app
docker-compose up -d app
```

## 📊 Acceso a Servicios

### FastAPI
- URL: http://localhost:3000
- Docs: http://localhost:3000/docs
- ReDoc: http://localhost:3000/redoc

### Prometheus
- URL: http://localhost:9090
- Queries: `http_requests_total`, `http_request_duration_ms`

### Grafana
- URL: http://localhost:3001
- User: admin
- Password: admin123
- Dashboards: DevOps App

## 🧪 Probar Endpoints

```bash
# Health
curl http://localhost:3000/health | jq

# Info
curl http://localhost:3000/api/info | jq

# Echo
curl -X POST http://localhost:3000/api/echo \
  -H "Content-Type: application/json" \
  -d '{"message":"test"}'

# Métricas
curl http://localhost:3000/metrics | head -20

# Prometheus scrape
curl http://localhost:9090/api/v1/query?query=up
```

## 💾 Persistencia

Los volúmenes se almacenan en:
- `prometheus_data/` - Datos de Prometheus
- `grafana_data/` - Datos de Grafana

Para resetear:
```bash
docker-compose down -v
```

## 🆘 Troubleshooting

### Puerto ya en uso
```bash
# Ver qué ocupa el puerto
lsof -i :3000
# Matar proceso
kill -9 <PID>
# O cambiar puerto en docker-compose.yml
ports:
  - "3001:3000"
```

### Container no inicia
```bash
docker-compose logs app
docker-compose build --no-cache app
docker-compose up app
```

### Error de conexión
```bash
# Verificar red
docker network ls
docker network inspect devops_app_default

# Reiniciar servicios
docker-compose restart
```

## 📝 Configuración Personalizada

### Cambiar puerto de FastAPI
En `docker-compose.yml`:
```yaml
ports:
  - "8000:3000"  # Cambiar a 8000
```

### Cambiar contraseña Grafana
```yaml
environment:
  - GF_SECURITY_ADMIN_PASSWORD=new_password
```

### Agregar variables de entorno
```yaml
app:
  environment:
    - ENV=production
    - DEBUG=false
```

## 📚 Docker CLI Útiles

```bash
# Ver contenedores activos
docker ps

# Ver todos
docker ps -a

# Ver logs en tiempo real
docker logs -f <container_id>

# Ejecutar comando en contenedor
docker exec -it <container_id> bash

# Obtener IP del contenedor
docker inspect <container_id> | grep IPAddress
```

---

**Última actualización**: Mayo 2026
