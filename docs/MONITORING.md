# Monitoring - Prometheus & Grafana

## 📊 Stack de Monitoreo

```
┌─────────────┐
│  FastAPI    │ Expone métricas en /metrics
│  App :3000  │
└──────┬──────┘
       │
       │ Scrape cada 15s
       │
┌──────▼──────────┐
│  Prometheus    │ Recolecta y almacena
│  :9090         │ Series de tiempo
└──────┬──────────┘
       │
       │ Query
       │
┌──────▼──────────┐
│  Grafana       │ Visualiza
│  :3001         │ Dashboards
└────────────────┘
```

## 📈 Métricas Disponibles

### Aplicación

| Métrica | Tipo | Descripción |
|---------|------|-------------|
| `http_requests_total` | Counter | Total de requests por ruta y código |
| `http_request_duration_ms` | Histogram | Duración de requests |
| `up` | Gauge | 1 si up, 0 si down |

### Ejemplo de Query

```promql
# Requests por segundo
rate(http_requests_total[1m])

# P95 latencia
histogram_quantile(0.95, http_request_duration_ms)

# Errores 5xx
rate(http_requests_total{status_code="5xx"}[5m])
```

## 🔧 Prometheus

### URL
http://localhost:9090
**Local**: [http://localhost:9090](http://localhost:9090)  
**AWS (Producción)**: [http://devops-app-alb-1530031189.us-east-1.elb.amazonaws.com:9090](http://devops-app-alb-1530031189.us-east-1.elb.amazonaws.com:9090)

### Configuración
Archivo: `monitoring/prometheus.yml`

```yaml
scrape_configs:
  - job_name: 'devops-app'
    static_configs:
      - targets: ['app:3000']
    scrape_interval: 15s
```

### Queries Útiles

#### 📡 Tráfico en Tiempo Real
```promql
# Requests por segundo (RPS) promediado en 5m
sum(rate(http_requests_total[5m]))

# Latencia P95 actual (ms)
histogram_quantile(0.95, sum(rate(http_request_duration_ms_bucket[5m])) by (le))
```
```

```promql
# Estado del servicio
up{job="devops-app"}

# Requests totales
http_requests_total

# Requests por ruta
sum by (route) (rate(http_requests_total[5m]))

#### Análisis Histórico (24 Horas)
#### Auditoría de 24 Horas
```promql
# Total de llamadas en el último día
# Total de peticiones en el último día
sum(increase(http_requests_total[24h]))

# Desglose de errores (4xx y 5xx) del último día
sum by (status_code) (increase(http_requests_total{status_code=~"4..|5.."}[24h]))
# Éxitos vs Errores (4xx/5xx) acumulados
sum by (status_code) (increase(http_requests_total[24h]))

# Latencia P95 histórica (últimas 24h)
histogram_quantile(0.95, sum by (le) (increase(http_request_duration_ms_bucket[24h])))
```

# Errores
http_requests_total{status_code=~"4|5"}

# Latencia P50/P95/P99
histogram_quantile(0.50, http_request_duration_ms)
histogram_quantile(0.95, http_request_duration_ms)
histogram_quantile(0.99, http_request_duration_ms)
```

### Alertas

Para agregar alertas, editar `prometheus.yml`:

```yaml
rule_files:
  - 'rules/*.yml'

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']
```

## 📊 Grafana

### Acceso
- URL: http://localhost:3001
**Local**: http://localhost:3001  
**AWS (Producción)**: http://devops-app-alb-1530031189.us-east-1.elb.amazonaws.com:3001
- Usuario: admin
- Contraseña: admin123

### Dashboards Disponibles

#### DevOps App Dashboard
- Muestra en tiempo real:
  - Requests por segundo
  - Errores
  - P95 latencia
  - Uptime

### Crear Dashboard Personalizado

1. Ve a **Grafana → +New Dashboard**
2. Selecciona **Prometheus** como datasource
3. Crea panels:
   ```promql
   # Panel 1: Request Rate
   rate(http_requests_total[1m])
   
   # Panel 2: Error Rate
   rate(http_requests_total{status_code=~"4|5"}[1m])
   
   # Panel 3: Latency
   histogram_quantile(0.95, http_request_duration_ms)
   ```

### Variables de Dashboard

Crear variable para filtrar:
```
Name: service
Type: Query
Query: label_values(http_requests_total, job)
```

## 🔔 Alertas

### Configurar Alertas

1. En Prometheus, crear archivo `rules/alerts.yml`:

```yaml
groups:
  - name: devops-app
    interval: 30s
    rules:
      - alert: AppDown
        expr: up{job="devops-app"} == 0
        for: 1m
        annotations:
          summary: "App está down"
      
      - alert: HighErrorRate
        expr: rate(http_requests_total{status_code=~"5"}[5m]) > 0.05
        for: 5m
        annotations:
          summary: "Error rate > 5%"
      
      - alert: HighLatency
        expr: histogram_quantile(0.95, http_request_duration_ms) > 1000
        for: 5m
        annotations:
          summary: "P95 latency > 1s"
```

2. Recargar Prometheus:
```bash
docker-compose restart prometheus
```

## 📡 Exportar Métricas

### Prometheus Scrape

El servidor FastAPI expone métricas en formato Prometheus:

```bash
curl http://localhost:3000/metrics

# Output ejemplo:
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",route="/health",status_code="200"} 42.0
```

### Formato

```
HELP http_requests_total Total HTTP requests
TYPE http_requests_total counter
http_requests_total{labels...} value

HELP http_request_duration_ms HTTP request duration
TYPE http_request_duration_ms histogram
http_request_duration_ms_bucket{labels...,le="0.1"} count
http_request_duration_ms_bucket{labels...,le="5"} count
http_request_duration_ms_sum{labels...} total_ms
http_request_duration_ms_count{labels...} count
```

## 🔍 Debugging

### Ver scrapes
```bash
# En Prometheus web: Status → Targets
# Ver si endpoint accesible
curl http://app:3000/metrics
curl http://app.local:3000/metrics
```

### Ver logs Prometheus
```bash
docker logs prometheus
```

### Ver logs Grafana
```bash
docker logs grafana
```

### Verificar conectividad
```bash
docker exec prometheus ping app
curl http://app:3000/metrics
```

## 📊 Dashboards de Ejemplo

### Uptime Dashboard
```promql
(sum(rate(http_requests_total[5m])) / sum(rate(http_requests_total{status_code="200"}[5m]))) * 100
```

### Error Dashboard
```promql
sum by (status_code) (rate(http_requests_total[5m]))
```

### Performance Dashboard
```promql
histogram_quantile(0.95, rate(http_request_duration_ms_bucket[5m]))
```

## 🔧 Integración con AWS CloudWatch

Para enviar a CloudWatch:

1. Instalar CloudWatch exporter
2. Configurar en prometheus.yml:
```yaml
remote_write:
  - url: https://...cloudwatch
```

## 📚 Referencias

- [Prometheus Docs](https://prometheus.io/docs/)
- [Grafana Docs](https://grafana.com/docs/)
- [PromQL Examples](https://prometheus.io/docs/prometheus/latest/querying/examples/)

---

**Última actualización**: Mayo 2026
