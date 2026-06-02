# Terraform Deployment - AWS Infrastructure

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                     Internet                            │
└────────────────────────┬────────────────────────────────┘
                         │
                    ┌────▼────┐
                    │   ALB    │
                    │ :80, 9090, 3001 │
                    └────┬────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
    ┌───▼─────┐    ┌────▼────┐    ┌─────▼──┐
    │ Subnet1 │    │ Subnet2 │    │ Route  │
    │ 10.0.0  │    │ 10.0.1  │    │ Table  │
    └───┬─────┘    └────┬────┘    └────────┘
        │                │
    ┌───▼─────┐    ┌────▼────┐
    │ECS Tasks│    │ECS Tasks│
    │App:3000 │    │Prom:9090│
    │Graf:3000│    │         │
    └─────────┘    └────────┘
```

## 📁 Archivos Terraform

### main.tf
Definición completa de recursos AWS:
- **VPC** - Red virtual (10.0.0.0/16)
- **Subnets** - 2 subnets públicas (10.0.0.0/24, 10.0.1.0/24)
- **IGW** - Internet Gateway
- **Route Table** - Enrutamiento 0.0.0.0/0 → IGW
- **ALB** - Application Load Balancer en puerto 80
- **Target Group** - Targets en puerto 3000
- **ECS Cluster** - Cluster de contenedores
- **ECS Task Definition** - Definición de tarea (CPU: 256, RAM: 512MB)
- **ECS Service** - Servicio con desiredCount: 1
- **IAM Roles** - Para ECS task execution
- **Security Groups** - ALB y ECS tasks

### terraform.tfvars
Variables de configuración:
```hcl
aws_region      = "us-east-1"
app_name        = "devops-app"
environment     = "production"
container_port  = 3000
```

## 🚀 Deployment

### Prerequisitos

1. **AWS Account** con credenciales configuradas
2. **Terraform** >= 1.0
3. **AWS CLI** configurado

### Pasos

```bash
# 1. Navegar a terraform
cd terraform

# 2. Inicializar
terraform init

# 3. Ver plan
terraform plan -var="docker_image_name=867344458893.dkr.ecr.us-east-1.amazonaws.com/devops-app:latest"

# 4. Aplicar
terraform apply -auto-approve

# 5. Obtener outputs
terraform output app_url
```

## 📤 State Backend

El estado se almacena en **S3**:
```
Bucket: devops-app-terraform-state-1780247597
Key: devops-app/terraform.tfstate
Region: us-east-1
```

⚠️ **Importante**: No comitear `.terraform/` ni `terraform.tfstate`

## 📊 Variables

| Variable | Valor | Descripción |
|----------|-------|-------------|
| aws_region | us-east-1 | Región de AWS |
| app_name | devops-app | Nombre de la app |
| environment | production | Entorno |
| container_port | 3000 | Puerto contenedor |
| docker_image_name | ECR URI | Imagen a desplegar |

## 🔗 Outputs

```bash
# Ver outputs
terraform output

# Output ejemplo:
# app_url = "http://devops-app-alb-1530031189.us-east-1.elb.amazonaws.com"
```

## 🔄 Actualizar Deployments

```bash
# Cambiar imagen
terraform apply -var="docker_image_name=NEW_IMAGE_URI"

# Ver cambios antes
terraform plan -var="docker_image_name=NEW_IMAGE_URI"
```

## 🗑️ Destruir Infraestructura

```bash
# Ver recursos a eliminar
terraform plan -destroy

# Destruir
terraform destroy -auto-approve
```

⚠️ **Cuidado**: Esto elimina todos los recursos

## 🆘 Troubleshooting

### Error: "Invalid configuration"
```bash
terraform validate
terraform fmt -check
```

### Error: "Permission denied"
Verificar IAM permisos:
```bash
aws sts get-caller-identity
aws iam list-attached-user-policies --user-name github-deployer
```

### Error: "Backend already initialized"
```bash
rm -rf .terraform
terraform init
```

## 📝 Logs

Ver logs de eventos:
```bash
# ECS
aws ecs describe-services --cluster devops-app-cluster --services devops-app --region us-east-1

# ALB
aws elbv2 describe-load-balancers --region us-east-1

# Task logs
aws logs tail /ecs/devops-app --follow
```

---

**Última actualización**: Mayo 2026
