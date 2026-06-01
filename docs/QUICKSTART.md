# DevOps Pipeline - Quick Start Guide

## 🚀 Cómo Empezar (3 Opciones)

### 1. Correr Localmente con Python

```bash
# Clonar y configurar
git clone https://github.com/IgnacioAramburu/githubActionsTerraformDocker.git
cd githubActionsTerraformDocker

# Entorno virtual
python -m venv .venv
source .venv/bin/activate

# Instalar e iniciar
pip install -r requirements.txt
python src/server.py

# Verificar
curl http://localhost:3000/health
```

### 2. Docker Compose (Local Completo)

```bash
git clone https://github.com/IgnacioAramburu/githubActionsTerraformDocker.git
cd githubActionsTerraformDocker

docker-compose up -d
sleep 30

# Servicios
curl http://localhost:3000/health      # API
# http://localhost:9090                # Prometheus
# http://localhost:3001                # Grafana (admin/admin123)
```

### 3. AWS ECS + Terraform

```bash
git clone https://github.com/IgnacioAramburu/githubActionsTerraformDocker.git
cd githubActionsTerraformDocker

export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."

cd terraform
terraform init
terraform apply

# Obtener URL
terraform output app_url
```

## 📡 Endpoints

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/api/info` | Info de la app |
| GET | `/metrics` | Prometheus metrics |
| POST | `/api/echo` | Echo de datos |
| GET | `/api/status/{service}` | Estado del servicio |

## 🧪 Pruebas

```bash
# Interactivo local
bash test-endpoints.sh

# Interactivo AWS
bash test-aws-endpoints.sh

# Manual
curl http://devops-app-alb-1530031189.us-east-1.elb.amazonaws.com/health
```

## 📚 Docs

- Swagger: http://localhost:3000/docs
- ReDoc: http://localhost:3000/redoc

---

**v1.0.0** | Mayo 2026
