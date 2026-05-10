# Guía de Configuración de Monitoreo

## Prometheus

### Acceso
**URL**: http://localhost:9090

### Métricas Disponibles

#### Métricas de Aplicación
```promql
# Total de requests HTTP
http_requests_total{service="devops-app"}

# Duración promedio de requests (95 percentil)
histogram_quantile(0.95, http_request_duration_ms)

# Requests por segundo
rate(http_requests_total[5m])

# Tasa de errores (5xx)
rate(http_requests_total{status_code="500"}[5m])
```

#### Métricas del Runtime Node.js
```promql
# Uso de memoria
nodejs_external_memory_bytes
nodejs_heap_size_total_bytes
nodejs_heap_size_used_bytes

# Event loop lag
nodejs_eventloop_lag_seconds

# Descriptores de archivo abiertos
process_open_fds
```

### Alertas (Ejemplos)

Crear alertas en `prometheus.yml`:

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - localhost:9093

rule_files:
  - 'alerts.yml'
```

Archivo `alerts.yml`:

```yaml
groups:
  - name: app_alerts
    interval: 30s
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status_code="500"}[5m]) > 0.05
        for: 5m
        annotations:
          summary: "Tasa de errores alta"
          
      - alert: AppDown
        expr: up{job="devops-app"} == 0
        for: 1m
        annotations:
          summary: "Aplicación no responde"
```

## Grafana

### Acceso
**URL**: http://localhost:3001
**Usuario**: admin
**Contraseña**: admin123

### Crear un Dashboard

1. Click en "+" → Dashboard
2. Seleccionar "Add a new panel"
3. En Query, seleccionar Prometheus como datasource
4. Escribir una query PromQL
5. Click en "Apply"

### Panels Recomendados

#### Panel 1: Requests por Segundo
```promql
rate(http_requests_total[1m])
```
- Type: Graph
- Title: "Request Rate"

#### Panel 2: Latencia P95
```promql
histogram_quantile(0.95, rate(http_request_duration_ms_bucket[5m]))
```
- Type: Gauge
- Title: "95th Percentile Latency (ms)"

#### Panel 3: Error Rate
```promql
rate(http_requests_total{status_code=~"5.."}[5m]) / rate(http_requests_total[5m])
```
- Type: Percentage Gauge
- Title: "Error Rate (%)"

#### Panel 4: Memory Usage
```promql
nodejs_heap_size_used_bytes / 1024 / 1024
```
- Type: Gauge
- Title: "Heap Memory (MB)"
- Unit: short

#### Panel 5: Active Connections
```promql
http_requests_total - http_requests_total offset 5m
```
- Type: Stat
- Title: "Requests (Last 5m)"

### Guardar Dashboard

1. Click en el ícono de disco (Save)
2. Dar nombre: "DevOps App Dashboard"
3. Click Save

### Exportar Dashboard
1. Abrir dashboard
2. Menu (tres líneas) → Export
3. Seleccionar "Export for sharing externally"
4. Copiar JSON

## Alertas en Grafana

1. Abrir Panel → Edit
2. Tab "Alert" (si no aparece, ver Alerting → Notification channels)
3. Configurar condición de alerta
4. Seleccionar notification channel

Ejemplo:
- Condition: `WHEN last() OF query(A) IS ABOVE 100`
- For: `5 minutes`
- Message: `High latency detected`

## Prometheus + Grafana con Docker Compose

Los servicios se inician automáticamente:
```bash
docker-compose up -d prometheus grafana
```

#### Verificar conectividad entre servicios
```bash
docker-compose exec grafana curl http://prometheus:9090/-/healthy
```

#### Reset de Grafana
```bash
# Borrar volumen de datos
docker-compose down -v

# Reiniciar
docker-compose up -d grafana
```

## Scrape Intervals

En `monitoring/prometheus.yml`:

```yaml
global:
  scrape_interval: 15s        # Cada cuánto scrape
  evaluation_interval: 15s    # Cada cuánto evalúe reglas
  external_labels:
    monitor: 'devops-app'
```

Valores comunes:
- Desarrollo: 15s - 30s
- Producción: 30s - 60s
- High-frequency metrics: 5s

## Retention Policy

Prometheus mantiene datos por defecto por 15 días. Para cambiar:

```bash
docker-compose run --rm prometheus \
  --storage.tsdb.retention.time=30d
```

## Backup de Métricas

```bash
# Backup manual
docker-compose exec prometheus tar -czf - /prometheus > prometheus-backup.tar.gz

# Restore
tar -xzf prometheus-backup.tar.gz
```

## Troubleshooting

### Prometheus no scrape la app
```bash
# Verificar targets
curl http://localhost:9090/api/v1/targets | jq

# Revisar logs
docker-compose logs prometheus

# Verificar conectividad
docker-compose exec prometheus curl http://app:3000/metrics
```

### Grafana sin datasource
```bash
# Reiniciar Grafana
docker-compose restart grafana

# O recrear volumen
docker-compose down -v
docker-compose up -d grafana
```

### Métricas no aparecen en Grafana
1. Verificar datasource está configured (Settings → Data sources)
2. Test connection en el datasource
3. Esperar a que Prometheus scrape (15s default)
4. Escribir una query simple: `up`
