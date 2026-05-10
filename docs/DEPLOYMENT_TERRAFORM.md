# Guía de Despliegue con Terraform

## Opción 2: Terraform + Docker (Infrastructure as Code)

### Requisitos
- Docker instalado y corriendo
- Terraform >= 1.0
- Provider Docker configurado

### Inicialización

```bash
cd terraform
bash init.sh
```

Este script ejecuta:
- `terraform init` - Inicializa el working directory
- `terraform validate` - Valida la configuración
- `terraform plan` - Genera el plan de ejecución

### Revisar cambios propuestos
```bash
terraform plan
```

### Aplicar configuración
```bash
# Con confirmación interactiva
terraform apply

# Sin confirmación
terraform apply -auto-approve
```

### Ver variables disponibles
```bash
terraform -chdir=terraform console
var.app_name
var.container_port
# etc.
```

### Customizar variables

Opción 1: Con flags
```bash
terraform apply \
  -var="host_port=8080" \
  -var="prometheus_port=9091" \
  -var="grafana_port=3002"
```

Opción 2: Con archivo tfvars
```bash
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars
terraform apply -var-file="terraform.tfvars"
```

### Ver estado de recursos
```bash
terraform show
terraform state list
terraform state show docker_container.devops_app
```

### Outputs
```bash
terraform output
terraform output app_url
terraform output prometheus_url
terraform output grafana_url
```

### Destruir infraestructura
```bash
cd terraform
bash destroy.sh
```

O manualmente:
```bash
terraform destroy -auto-approve
```

## Diferencias entre Terraform y Docker Compose

| Aspecto | Terraform | Docker Compose |
|--------|-----------|----------------|
| Propósito | IaC completo | Desarrollo local |
| Estado | Trackea en .tfstate | Sin estado persistente |
| Complejidad | Mayor | Menor |
| Escalabilidad | Mejor | Limitada |
| Producción | Recomendado | No recomendado |

## Integración con Terraform Cloud (Opcional)

```bash
# Loguear con cuenta de TF Cloud
terraform login

# Configurar backend remoto
cat > main.tf << EOF
terraform {
  cloud {
    organization = "your-org"
    workspaces {
      name = "devops-app"
    }
  }
}
EOF

# Reinicializar
terraform init
```

## Monitoring del Despliegue

```bash
# Ver contenedores creados
docker ps | grep devops-app

# Ver logs de la aplicación
docker logs -f $(docker ps -q -f label=env=production)

# Ver logs de Prometheus
docker logs -f $(docker ps -q -f ancestor=prom/prometheus)

# Ver logs de Grafana
docker logs -f $(docker ps -q -f ancestor=grafana/grafana)
```

## Post-Despliegue

1. Acceder a http://localhost:3000 y verificar API
2. Ir a Prometheus (http://localhost:9090) y verificar targets
3. Acceder a Grafana (http://localhost:3001) y crear dashboards
4. Revisar métricas en `/metrics`

## Troubleshooting Terraform

### Error: Docker daemon not running
```bash
# En Linux
sudo service docker start

# En macOS
open /Applications/Docker.app
```

### Error: Network already exists
```bash
# Ver redes
docker network ls

# Remover red conflictiva
docker network rm devops-app-network

# Reintentar
terraform apply -auto-approve
```

### Error: Image cannot be built
```bash
# Verificar Dockerfile existe
ls -la ../docker/Dockerfile

# Verificar rutas en main.tf
cd ../
pwd  # Ver directorio actual

# Reintentar con paths absolutos
```

## Backup y Restore

### Backup del estado
```bash
cp terraform/terraform.tfstate terraform/terraform.tfstate.backup
```

### Restore del estado
```bash
cp terraform/terraform.tfstate.backup terraform/terraform.tfstate
terraform apply -auto-approve
```
