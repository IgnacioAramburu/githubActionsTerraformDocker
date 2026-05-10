terraform {
  required_version = ">= 1.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  # Configuración automática desde variable de entorno DOCKER_HOST
}

variable "app_name" {
  description = "Nombre de la aplicación"
  type        = string
  default     = "devops-app"
}

variable "docker_image_name" {
  description = "Nombre de la imagen Docker"
  type        = string
  default     = "devops-app:latest"
}

variable "container_port" {
  description = "Puerto en el contenedor"
  type        = number
  default     = 3000
}

variable "host_port" {
  description = "Puerto en el host"
  type        = number
  default     = 3000
}

variable "environment" {
  description = "Entorno de ejecución"
  type        = string
  default     = "production"
}

variable "prometheus_port" {
  description = "Puerto para Prometheus"
  type        = number
  default     = 9090
}

variable "grafana_port" {
  description = "Puerto para Grafana"
  type        = number
  default     = 3001
}

# Network
resource "docker_network" "devops_network" {
  name   = "${var.app_name}-network"
  driver = "bridge"

  tags {
    env = var.environment
  }
}

# Imagen Docker - Build local
resource "docker_image" "devops_app" {
  name = var.docker_image_name

  build {
    context      = "${path.root}/.."
    dockerfile   = "docker/Dockerfile"
    target       = ""
    build_args = {
      NODE_ENV = var.environment
    }
  }

  triggers = {
    dir_sha1 = filebase64sha256("${path.root}/../src/")
  }
}

# Contenedor de la aplicación
resource "docker_container" "devops_app" {
  name  = "${var.app_name}-container"
  image = docker_image.devops_app.image_id

  ports {
    internal = var.container_port
    external = var.host_port
  }

  env = [
    "NODE_ENV=${var.environment}",
    "PORT=${var.container_port}"
  ]

  networks_advanced {
    name = docker_network.devops_network.name
  }

  healthcheck {
    test     = ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:${var.container_port}/health"]
    interval = "30s"
    timeout  = "10s"
    retries  = 3
  }

  restart_policy {
    condition = "unless-stopped"
  }

  tags {
    env = var.environment
  }

  depends_on = [docker_image.devops_app]
}

# Imagen Prometheus
resource "docker_image" "prometheus" {
  name = "prom/prometheus:latest"
  keep_locally = true
}

# Contenedor Prometheus
resource "docker_container" "prometheus" {
  name  = "${var.app_name}-prometheus"
  image = docker_image.prometheus.image_id

  ports {
    internal = 9090
    external = var.prometheus_port
  }

  mounts {
    type      = "bind"
    source    = "${path.root}/../monitoring/prometheus.yml"
    target    = "/etc/prometheus/prometheus.yml"
    read_only = true
  }

  mounts {
    type   = "volume"
    source = docker_volume.prometheus_data.name
    target = "/prometheus"
  }

  cmd = [
    "--config.file=/etc/prometheus/prometheus.yml",
    "--storage.tsdb.path=/prometheus"
  ]

  networks_advanced {
    name = docker_network.devops_network.name
  }

  restart_policy {
    condition = "unless-stopped"
  }

  depends_on = [docker_image.prometheus]
}

# Volume para Prometheus
resource "docker_volume" "prometheus_data" {
  name = "${var.app_name}-prometheus-data"
}

# Imagen Grafana
resource "docker_image" "grafana" {
  name = "grafana/grafana:latest"
  keep_locally = true
}

# Contenedor Grafana
resource "docker_container" "grafana" {
  name  = "${var.app_name}-grafana"
  image = docker_image.grafana.image_id

  ports {
    internal = 3000
    external = var.grafana_port
  }

  env = [
    "GF_SECURITY_ADMIN_PASSWORD=admin123",
    "GF_SECURITY_ADMIN_USER=admin",
    "GF_INSTALL_PLUGINS=alexanderzobnin-zabbix-app"
  ]

  mounts {
    type   = "volume"
    source = docker_volume.grafana_data.name
    target = "/var/lib/grafana"
  }

  mounts {
    type      = "bind"
    source    = "${path.root}/../monitoring/grafana-provisioning"
    target    = "/etc/grafana/provisioning"
    read_only = true
  }

  networks_advanced {
    name = docker_network.devops_network.name
  }

  restart_policy {
    condition = "unless-stopped"
  }

  depends_on = [docker_container.prometheus, docker_image.grafana]
}

# Volume para Grafana
resource "docker_volume" "grafana_data" {
  name = "${var.app_name}-grafana-data"
}

# Outputs
output "app_url" {
  description = "URL de la aplicación"
  value       = "http://localhost:${var.host_port}"
}

output "prometheus_url" {
  description = "URL de Prometheus"
  value       = "http://localhost:${var.prometheus_port}"
}

output "grafana_url" {
  description = "URL de Grafana (usuario: admin, contraseña: admin123)"
  value       = "http://localhost:${var.grafana_port}"
}

output "container_id" {
  description = "ID del contenedor de la aplicación"
  value       = docker_container.devops_app.id
}

output "image_id" {
  description = "ID de la imagen Docker"
  value       = docker_image.devops_app.image_id
}
