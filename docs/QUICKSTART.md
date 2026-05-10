# Quick Start Guide

## 🚀 5 Minutos: Primer Deploy

### Opción 1: Docker Compose (Más Fácil)

```bash
# 1. Clonar
git clone <repo>
cd GitHub\ Actions+Terraform+Docker

# 2. Iniciar servicios
docker-compose up -d

# 3. Esperar 30 segundos
sleep 30

# 4. Verificar
curl http://localhost:3000

# Ver URLs:
# App: http://localhost:3000
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3001 (admin/admin123)
```

### Opción 2: Terraform (Más Profesional)

```bash
# 1. Clonar
git clone <repo>
cd GitHub\ Actions+Terraform+Docker

# 2. Instalar deps
npm install

# 3. Deploy
cd terraform
terraform init
terraform apply -auto-approve

# 4. Ver outputs
terraform output

# Acceder igual que opción 1
```

## 🧪 Testing Local

```bash
npm install
npm run lint
npm test
npm run sbom:generate
```

## 📊 Acceder a Dashboards

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| API | http://localhost:3000 | - |
| API Healthcheck | http://localhost:3000/health | - |
| API Métricas | http://localhost:3000/metrics | - |
| Prometheus | http://localhost:9090 | - |
| Grafana | http://localhost:3001 | admin / admin123 |

## 🛑 Detener Servicios

```bash
# Docker Compose
docker-compose down

# Terraform
cd terraform
terraform destroy -auto-approve
```

## 📚 Documentación Completa

- [README.md](../README.md) - Overview general
- [docs/DEPLOYMENT_DOCKER_COMPOSE.md](./DEPLOYMENT_DOCKER_COMPOSE.md) - Deploy con Docker Compose
- [docs/DEPLOYMENT_TERRAFORM.md](./DEPLOYMENT_TERRAFORM.md) - Deploy con Terraform
- [docs/MONITORING.md](./MONITORING.md) - Prometheus & Grafana
- [docs/CI_CD_GUIDE.md](./CI_CD_GUIDE.md) - GitHub Actions detalles
- [docs/SECURITY_COMPLIANCE.md](./SECURITY_COMPLIANCE.md) - Seguridad

## ⚠️ Requisitos Mínimos

- Docker Engine (opcional si solo eres dev)
- Node.js 18+
- npm 8+
- Terraform 1.0+ (solo si usas TF)

## 🆘 Problemas Comunes

| Problema | Solución |
|----------|----------|
| Puerto 3000 en uso | `lsof -i :3000` y matar proceso |
| Docker daemon no corre | `sudo service docker start` o `open /Applications/Docker.app` |
| npm audit falla | `npm audit fix` o `npm audit fix --force` |
| Terraform error | `rm -rf terraform/.terraform` y reintentar |

## 📞 Soporte

Ver [README.md](../README.md#-troubleshooting) para troubleshooting detallado.
