# CI/CD Pipeline - GitHub Actions Guide

## 📋 Pipeline Overview

El proyecto usa **GitHub Actions** para automatizar:
1. Linting de código (PyLint)
2. Ejecución de tests (pytest)
3. Generación de SBOM
4. Build y push de Docker image a ECR
5. Deploy con Terraform a AWS ECS

## 🔄 Flujo de Ejecución

### Triggers

El pipeline se ejecuta en:
- Push a `main` o `develop`
- Pull Requests a `main` o `develop`  
- Manualmente (workflow_dispatch)

### Trabajos del Pipeline

#### 1. **Lint & Code Analysis** (2 min)
```bash
pylint src/
```
- Valida sintaxis y estándares Python
- Estado: ⚠️ `continue-on-error: true` (no bloquea)

#### 2. **Tests** (2 min)
```bash
pytest src/test_server.py -v
```
- 21 test cases
- Validar endpoints, errores, concurrencia
- Estado: 🔴 Crítico (bloquea si falla)

#### 3. **SBOM Generation** (1 min)
```bash
sbom-tool generate -d src -o spdx
```
- Software Bill of Materials
- Documentar dependencias

#### 4. **Docker Build & Push** (3 min)
```docker
# Multi-stage build
FROM python:3.10-alpine as builder
FROM python:3.10-alpine
```
- Build image optimizada
- Push a AWS ECR
- Tags: `latest` y commit SHA

#### 5. **Terraform Deploy** (5 min)
```hcl
terraform init
terraform plan
terraform apply
```
- Crear/actualizar infraestructura ECS
- ALB, VPC, subnets, security groups
- Desplegar contenedor

## 🔐 Secretos Requeridos

En **GitHub → Settings → Secrets and variables → Actions**:

```
AWS_ACCESS_KEY_ID           # IAM user access key
AWS_SECRET_ACCESS_KEY       # IAM user secret
AWS_ACCOUNT_ID              # 867344458893
```

## 📊 Monitoreo del Pipeline

1. Ve a **GitHub → Actions**
2. Selecciona el workflow
3. Haz clic en el commit/PR
4. Expande cada job para ver logs

## 🆘 Troubleshooting

### ❌ Falla en Lint
```bash
# Revisar localmente
pylint src/
```

### ❌ Falla en Tests
```bash
# Revisar localmente
pytest src/test_server.py -v
```

### ❌ Falla en Docker Build
- Revisar logs en GitHub Actions
- Validar Dockerfile
- Revisar requirements.txt

### ❌ Falla en Terraform Deploy
- Revisar IAM permisos
- **Error AccessDenied (ECR):** Asegúrate de que el usuario tenga `ecr:CreateRepository`.
- Validar terraform: `terraform validate`
- Revisar estado de S3

## 🔑 Variables de Entorno

Pipeline establece:
```bash
AWS_REGION=us-east-1
ECR_REPOSITORY=devops-app
AWS_ACCOUNT_ID=867344458893
```

## 💡 Tips

- Ver estado: `terraform state list`
- Destroy: `terraform destroy`
- Plan: `terraform plan -out=tfplan`
- Debug: Ejecutar manualmente en Actions

---

**Última actualización**: Mayo 2026
