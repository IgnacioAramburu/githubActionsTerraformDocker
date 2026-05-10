# Guía de Despliegue Local con Docker Compose

## Opción 1: Docker Compose (Recomendado para desarrollo)

### Inicio rápido
```bash
docker-compose up -d
```

### Verificar servicios
```bash
docker-compose ps
```

### Ver logs
```bash
docker-compose logs -f app
docker-compose logs -f prometheus
docker-compose logs -f grafana
```

### Parar servicios
```bash
docker-compose down
```

### Parar y borrar volúmenes
```bash
docker-compose down -v
```

## URLs Disponibles

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| Aplicación | http://localhost:3000 | - |
| Health Check | http://localhost:3000/health | - |
| Métricas | http://localhost:3000/metrics | - |
| Prometheus | http://localhost:9090 | - |
| Grafana | http://localhost:3001 | admin / admin123 |

## Troubleshooting

### Puerto ya en uso
```bash
# Encontrar proceso usando el puerto
lsof -i :3000

# Cambiar puerto en docker-compose.yml
# Modificar: "3000:3000" a "8000:3000"
```

### Contenedor no inicia
```bash
# Ver logs de error
docker-compose logs app

# Reconstruir imagen
docker-compose build --no-cache app

# Reintentar
docker-compose up -d
```

### Prometheus no recolecta métricas
```bash
# Verificar conectividad
docker-compose exec prometheus curl http://app:3000/metrics

# Verificar config
docker-compose exec prometheus cat /etc/prometheus/prometheus.yml
```
