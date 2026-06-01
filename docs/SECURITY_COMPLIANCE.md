# Security & Compliance

## 🔐 Seguridad en el Pipeline

### 1. Validación de Código

**PyLint** - Análisis estático
```bash
pylint src/
```
- Detecta bugs
- Problemas de estilo
- Potenciales vulnerabilidades

### 2. Tests de Seguridad

**pytest** - Unit & Integration tests
```bash
pytest src/test_server.py
```
- 21 test cases
- Validar endpoints
- Error handling
- Concurrencia

### 3. SBOM (Software Bill of Materials)

**sbom-tool** - Lista de componentes
```bash
sbom-tool generate -d src -o spdx
```
- Documenta todas las dependencias
- Detección de vulnerabilidades conocidas

## 🐳 Seguridad de Docker

### Multi-stage Build

```dockerfile
# Stage 1: Builder
FROM python:3.10-alpine as builder
RUN apk add gcc musl-dev
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# Stage 2: Runtime (más pequeño)
FROM python:3.10-alpine
COPY --from=builder /root/.local /root/.local
COPY src/ /app/src/
WORKDIR /app
CMD ["python", "src/server.py"]
```

**Beneficios:**
- ✅ Imagen final 50% más pequeña
- ✅ Herramientas de build no incluidas
- ✅ Menos superficie de ataque

### Imagen Base

- `python:3.10-alpine` (50MB)
- Alpine Linux = mínimas dependencias
- Actualizaciones de seguridad regulares

### Scanning de Vulnerabilidades

En pipeline: **Trivy**
```bash
trivy image ECR_IMAGE_URI
```

## 🔑 Gestión de Secretos

### GitHub Secrets

En repo: **Settings → Secrets and variables**

```
AWS_ACCESS_KEY_ID          # ✅ Encriptado
AWS_SECRET_ACCESS_KEY      # ✅ Encriptado
AWS_ACCOUNT_ID             # ⚠️ Semi-público
```

### Buenas Prácticas

1. **Nunca comitear secretos**
2. **Usar .gitignore**:
   ```
   .env
   .env.local
   terraform.tfstate
   *.key
   ```

3. **Rotar credenciales** regularmente

4. **Auditar acceso**:
   ```bash
   aws iam list-access-keys --user-name github-deployer
   ```

## 👤 IAM Policies

### Usuario: github-deployer

Permisos asignados:
- `AmazonEC2ContainerRegistryPowerUser` - ECR
- `AmazonECS_FullAccess` - ECS
- `AmazonVPCFullAccess` - VPC
- `AmazonS3FullAccess` - S3 (Terraform state)
- `IAMFullAccess` - IAM (roles)
- `elasticloadbalancing:*` - ALB

### Principio de Menor Privilegio

⚠️ **Mejorable**: Reducir permisos a lo estrictamente necesario

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:PutImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "arn:aws:ecr:us-east-1:*:repository/devops-app"
    }
  ]
}
```

## 🔒 Encriptación

### En Tránsito

- ALB: HTTP (considerar HTTPS con cert)
- ECS ← ALB: VPC privada
- GitHub ← AWS: Credenciales encriptadas

### En Reposo

- S3 (Terraform state): ✅ Server-side encryption
- EBS: ✅ Habilitado por defecto
- RDS: ⚠️ No aplicable

### Terraform State

Almacenado en S3 **encriptado**:

```bash
# Ver encriptación
aws s3api get-bucket-encryption \
  --bucket devops-app-terraform-state-1780247597
```

## 🌐 Network Security

### Security Groups

#### ALB (puerto 80)
```
Ingress: 0.0.0.0/0:80
Egress: 0.0.0.0/0:*
```

#### ECS Tasks (puerto 3000)
```
Ingress: ALB security group:3000
Egress: 0.0.0.0/0:*
```

### VPC Endpoints (opcional)

Para acceso privado a AWS services:
```
- ECR (pull images sin internet)
- S3 (Terraform state)
```

## 📋 Compliance

### Requisitos Típicos

| Requisito | Implementado |
|-----------|--------------|
| Code scanning | ✅ PyLint |
| SBOM | ✅ sbom-tool |
| Container scanning | ✅ Trivy |
| Secrets management | ✅ GitHub Secrets |
| Audit logs | ✅ AWS CloudTrail |
| Encryption in transit | ⚠️ HTTP (mejorar) |
| Encryption at rest | ✅ S3 |
| Access control | ✅ IAM |
| Network segmentation | ✅ VPC |

### SAST (Static Application Security Testing)

Opciones:
- PyLint (incluido)
- Bandit: `bandit -r src/`
- SonarQube: Integración opcional

### DAST (Dynamic Application Security Testing)

Opciones:
- OWASP ZAP
- Burp Suite

## 🔄 Auditoría

### Ver eventos AWS
```bash
# CloudTrail events
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=devops-app-cluster
```

### Logs de GitHub Actions
```bash
# En GitHub Actions → Workflow run → Logs
# Búsqueda de secretos: GitHub almacena hashes, no valores
```

## 🛡️ Mejoras Recomendadas

1. **HTTPS/TLS**
   - Agregar certificado SSL/TLS al ALB
   - Acme.sh con AWS Route53

2. **WAF**
   - AWS WAF en ALB
   - Proteger contra OWASP Top 10

3. **Secrets Rotation**
   - AWS Secrets Manager
   - Rotación automática

4. **MFA**
   - Habilitar MFA en AWS account

5. **VPN**
   - Acceso a infraestructura privada

6. **Container Registry Scanning**
   - ECR image scanning automático

7. **Network Policies**
   - Kubernetes NetworkPolicies (si migrar a EKS)

8. **Runtime Security**
   - Falco para detección de anomalías

## 📚 Referencias

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)

---

**Última actualización**: Mayo 2026
