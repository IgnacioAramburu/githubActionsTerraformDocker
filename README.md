# DevOps Pipeline: GitHub Actions + Terraform + Docker (Python)

[![CI/CD Pipeline](https://github.com/your-repo/actions/workflows/ci-cd-pipeline.yml/badge.svg)](https://github.com/your-repo/actions/workflows/ci-cd-pipeline.yml)
[![Terraform Validation](https://github.com/your-repo/actions/workflows/terraform-validation.yml/badge.svg)](https://github.com/your-repo/actions/workflows/terraform-validation.yml)

## 📋 Descripción

Pipeline CI/CD completo que automatiza la compilación, testing, análisis de seguridad y despliegue de una **aplicación Python con FastAPI** en contenedores Docker. Infrastructure as Code (IaC) con Terraform para gestionar la infraestructura en **AWS (ECS Fargate)**.

**Herramientas utilizadas:**
- 🔄 **CI/CD**: GitHub Actions
- 🏗️ **IaC**: Terraform
- 🐳 **Contenedores**: Docker (Python 3.10)
- 🔒 **Seguridad**: PyLint, Black, Trivy, Bandit, CycloneDX (SBOM)
- 📊 **Observabilidad**: Prometheus + Grafana
- 🧪 **Testing**: pytest + pytest-asyncio
- ⚡ **Framework**: FastAPI + Uvicorn

## 🚀 Requisitos Previos

### Opción Local (VirtualBox)
```bash
# Requisitos mínimos:
- Docker Desktop o Docker Engine
- Docker Compose
- Terraform >= 1.0
- Python 3.10+
- AWS CLI configurado
```

### Configuración de AWS
Es necesario configurar las credenciales de AWS y crear el bucket S3 para el backend de Terraform:
- **Bucket**: `devops-app-terraform-state-1780247597`
- **Región**: `us-east-1`
```bash
# En macOS:
brew install docker docker-compose terraform python@3.10
```

### Configuración de Docker (si es necesario)
```bash
# Permitir usuario actual usar Docker sin sudo:
sudo usermod -aG docker $USER
newgrp docker
```

## 📁 Estructura del Proyecto

```
.
├── .github/workflows/          # Workflows de GitHub Actions
│   ├── ci-cd-pipeline.yml     # Pipeline principal CI/CD
│   └── terraform-validation.yml # Validación de Terraform
├── src/                        # Código fuente de la aplicación
│   ├── server.py              # App FastAPI con métricas Prometheus
│   └── test_server.py         # Suite de pruebas unitarias
├── docker/                     # Configuración Docker
│   └── Dockerfile             # Multi-stage Dockerfile
├── terraform/                 # Configuración Infrastructure as Code
│   ├── main.tf               # Recursos AWS (ECS, VPC, ALB)
│   ├── init.sh               # Script de inicialización de infraestructura
│   └── destroy.sh            # Script de destrucción
├── monitoring/               # Configuración de monitoreo
│   ├── prometheus.yml        # Configuración de Prometheus
│   └── grafana-provisioning/ # Dashboards de Grafana
├── security/                 # Seguridad y Cumplimiento
│   └── sbom-template.xml     # Plantilla base CycloneDX
├── docs/                     # Documentación técnica detallada
│   ├── CI_CD_GUIDE.md        # Guía del pipeline
│   ├── DEPLOYMENT_TERRAFORM.md # Guía de Infraestructura
│   ├── MONITORING.md         # Manual de Observabilidad
│   └── SECURITY_COMPLIANCE.md # Detalles de Controles de Seguridad
├── docker-compose.yml        # Orquestación local
├── pyproject.toml            # Configuración de herramientas Python
├── requirements.txt          # Dependencias del proyecto
├── setup.sh                  # Script de configuración inicial
├── validate.sh               # Script de validación de salud del proyecto
└── README.md                 # Este archivo
```

## 🏃 Guía Rápida de Inicio

### 1. Clonar el repositorio
```bash
git clone <repository-url>
cd GitHub Actions+Terraform+Docker
```

### 2. Opción A: Docker Compose (Recomendado para desarrollo local)

```bash
# Iniciar todos los servicios
docker-compose up -d

# Esperar a que los servicios se inicien (30 segundos)
sleep 30

# Verificar servicios
docker-compose ps

# Acceder a los servicios:
# - App: http://localhost:3000
# - Prometheus: http://localhost:9090
# - Grafana: http://localhost:3001 (admin/admin123)
```

### 2. Opción B: Terraform + Docker (Para infraestructura IaC)

```bash
# Inicializar Terraform
cd terraform
bash init.sh

# Revisar cambios propuestos
terraform plan

# Aplicar configuración
terraform apply -auto-approve

# Verificar outputs
terraform output

# Para destruir:
bash destroy.sh
cd ..
```

### 3. Ejecutar tests localmente
```bash
pip install -r requirements.txt
pylint src/server.py
pytest src/test_server.py
black --check src/
```

## 📊 Dashboard de Monitoreo

### Prometheus
**Local**: [http://localhost:9090](http://localhost:9090)  
**AWS (Producción)**: [http://devops-app-alb-1530031189.us-east-1.elb.amazonaws.com:9090](http://devops-app-alb-1530031189.us-east-1.elb.amazonaws.com:9090)

Métricas disponibles:
- `http_requests_total` - Total de requests HTTP
- `http_request_duration_ms` - Duración de requests
- `python_info` - Información del runtime Python

### Grafana
**Local**: http://localhost:3001  
**AWS (Producción)**: http://devops-app-alb-1530031189.us-east-1.elb.amazonaws.com:3001  
**Credenciales**: `admin` / `admin123`

Dashboards disponibles:
- DevOps Application Metrics
- System Performance
- Request Analytics

## 🔄 CI/CD Pipeline

### Job 1: Lint & Code Analysis
- ✅ PyLint analysis
- ✅ Black formatting check
- ✅ pip check (Dependency audit)
- ⏱️ ~2 minutos

### Job 2: Test & Coverage
- ✅ Unit tests con pytest
- ✅ Coverage reporting (XML/HTML)
- ✅ Codecov integration (Upload)
- ⏱️ ~3 minutos

### Job 3: Generate SBOM
- ✅ CycloneDX SBOM generation
- ✅ Exportación de `dependencies.txt`
- ⏱️ ~1 minuto

### Job 4: Build Docker Image
- ✅ Multi-stage docker build
- ✅ Push a Amazon ECR
- ✅ Trivy vulnerability scan (SARIF report)
- ⏱️ ~5-10 minutos

### Job 5: Deploy
- ✅ Terraform Apply (Infraestructura AWS)
- ✅ Verificación de Health Check en ALB

## 🔒 Seguridad

### Controles Implementados

1. **Análisis Estático de Código**
   - PyLint: Validación de estándares Python
   - Ubicación: `.pylintrc`

2. **Auditoría de Dependencias**
   - pip check: Verificación de paquetes
   - Escaneo de requirements.txt

3. **Software Bill of Materials (SBOM)**
   - Formato: CycloneDX XML
   - Ubicación: `security/sbom-template.xml`
   - Generación automática en pipeline

4. **Análisis de Imágenes Docker**
   - Trivy: Escaneo de vulnerabilidades
   - Genera reportes SARIF
   - Integración con GitHub Security

5. **Buenas Prácticas**
   - User no-root en Dockerfile
   - Health checks
   - Variables de entorno seguros
   - Versiones pinned de dependencias

### Configurar Snyk

```bash
# Obtener token en https://snyk.io
# Añadir a GitHub Secrets como SNYK_TOKEN

# Ejecutar localmente:
npm install -g snyk
snyk auth           # Authenticate with Snyk
snyk test           # Test for vulnerabilities
```

## 🐳 Docker

### Build local
```bash
docker build -f docker/Dockerfile -t devops-app:latest .

# Build con variables
docker build --build-arg ENV=production -f docker/Dockerfile -t devops-app:1.0.0 .
```

### Ejecutar contenedor
```bash
docker run -p 3000:3000 \
  -e ENV=production \
  -e PYTHONUNBUFFERED=1 \
  --health-cmd='curl -f http://localhost:3000/health' \
  devops-app:latest
```

### Escanear imagen con Trivy
```bash
trivy image devops-app:latest
```

## 🏗️ Terraform

### Variables disponibles
```hcl
app_name          = "devops-app"
docker_image_name = "devops-app:latest"
container_port    = 3000
host_port         = 3000
environment       = "production"
prometheus_port   = 9090
grafana_port      = 3001
```

### Comandos Terraform
```bash
cd terraform

# Inicializar
terraform init

# Validar configuración
terraform validate

# Generar plan
terraform plan -out=tfplan

# Aplicar cambios
terraform apply tfplan

# Ver outputs
terraform output

# Destruir infraestructura
terraform destroy -auto-approve
```

### Outputs
```
app_url = "http://localhost:3000"
prometheus_url = "http://localhost:9090"
grafana_url = "http://localhost:3001"
container_id = "abc123..."
image_id = "sha256:..."
```

## 📈 Monitoreo y Observabilidad

### Métricas Expuestas
La aplicación expone métricas en `/metrics` en formato Prometheus:
- `http_requests_total` - Total de requests
- `http_request_duration_ms` - Latencia de requests
- Métricas del runtime **Python**

### Crear Dashboard Personalizado en Grafana

1. Acceder a http://localhost:3001
2. Ir a Dashboards → New Dashboard
3. Añadir Panel → Prometheus
4. Queries ejemplo:
   ```
   rate(http_requests_total[5m])  # Requests por segundo
   histogram_quantile(0.95, http_request_duration_ms)  # P95 latencia
   ```

## 🧪 Testing

### Ejecutar tests
```bash
pip install -r requirements.txt
pytest src/test_server.py -v                  # Run all tests
pytest src/test_server.py -v --cov=src       # With coverage report
pytest src/test_server.py -v --cov=src --cov-report=html  # HTML coverage
pytest src/test_server.py -k test_root       # Run specific test
```

### Linting y Code Quality
```bash
pylint src/server.py                 # PyLint analysis
black --check src/                   # Black format check
black src/                           # Black auto-fix
pip check                            # Dependency vulnerabilities
```

### Coverage Threshold
- Per Test Suite: Minimum 70%
- Use `--cov-fail-under=70` para enforcement

## 🔧 Troubleshooting

### Docker no puede conectar a Prometheus
```bash
# Verificar network
docker network ls
docker network inspect devops-app-network
```

### Terraform init falla
```bash
# Limpiar caché
rm -rf terraform/.terraform
rm -f terraform/.terraform.lock.hcl

# Reintentar
cd terraform && terraform init
```

### Tests fallan localmente
```bash
# Limpiar cache y reinstalar
rm -rf __pycache__ .pytest_cache
rm -rf venv/  # si usas venv
python3 -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate
pip install -r requirements.txt
pytest src/test_server.py -v
```

### Permiso denegado en scripts
```bash
chmod +x terraform/*.sh
chmod +x security/*.sh
```

## 🚢 Despliegue en Producción

### Pre-requisitos
1. Configurar secretos en GitHub:
   - `AWS_ACCESS_KEY_ID`: Credenciales de IAM
   - `AWS_SECRET_ACCESS_KEY`: Secreto de IAM
   - `AWS_ACCOUNT_ID`: ID de cuenta de 12 dígitos
   - `SNYK_TOKEN`: Token de seguridad de Snyk

2. Configurar ramas protegidas:
   - Requerir checks del pipeline
   - Requerir revisiones

### Proceso CI/CD
1. Push a `main` branch
2. Pipeline ejecuta automáticamente
3. Si todo pasa, imagen se pushea a registry
4. Desplegar manualmente o con CD automation

## 📝 Cambios Tipicos

### Añadir nueva ruta en FastAPI
```python
@app.get("/api/nuevo")
async def nueva_ruta():
    return {"message": "Nueva ruta"}

@app.post("/api/crear")
async def crear(data: dict):
    return {"created": data}
```

### Añadir nueva métrica Prometheus
```python
from prometheus_client import Counter

mi_metrica = Counter('mi_metrica_total', 'Descripción')
mi_metrica.inc()  # Incrementar contador
```

### Modificar variables Terraform
```bash
terraform apply -var="host_port=8080" -var="grafana_port=3002"
```

### Añadir nueva dependencia
```bash
pip install nuevo-paquete
pip freeze > requirements.txt
```

## 📚 Documentación Adicional

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Docker Documentation](https://docs.docker.com/)
- [Prometheus Documentation](https://prometheus.io/docs)
- [Grafana Documentation](https://grafana.com/docs)
- [CycloneDX Specification](https://cyclonedx.org/)

## 🤝 Contribuciones

1. Crear rama: `git checkout -b feature/nueva-feature`
2. Hacer cambios y commitear: `git commit -am 'Add nueva-feature'`
3. Push a rama: `git push origin feature/nueva-feature`
4. Crear Pull Request

Los PRs ejecutarán el pipeline automáticamente.

## 📄 Licencia

MIT License - Ver LICENSE file para más detalles.

## ✅ Checklist de Entrega

- [x] Workflow .yml de GitHub Actions
- [x] Archivos Terraform para infraestructura
- [x] Dockerfile multi-stage con buenas prácticas
- [x] Tests unitarios con pytest
- [x] Análisis de código (PyLint)
- [x] Análisis de seguridad (Trivy, pip check)
- [x] SBOM (CycloneDX)
- [x] Monitoreo (Prometheus + Grafana)
- [x] Documentación completa
- [x] Docker Compose para desarrollo local

## 🎓 Información del Proyecto

- **Nombre**: GitHub Actions + Terraform + Docker (Local CI/CD)
- **Versión**: 1.0.0
- **Fecha**: May 2026

---

**Preguntas o problemas?** Crear un issue en el repositorio.
