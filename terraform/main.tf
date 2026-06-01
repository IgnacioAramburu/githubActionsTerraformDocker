terraform {
  required_version = ">= 1.0"
  backend "s3" {
    bucket = "devops-app-terraform-state-1780247597"
    key    = "devops-app/terraform.tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "app_name" {
  description = "Nombre de la aplicación"
  type        = string
  default     = "devops-app"
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "ID de la cuenta de AWS"
  type        = string
  sensitive   = true
}

variable "docker_image_name" {
  description = "URI de la imagen en ECR"
  type        = string
  default     = ""
}

variable "container_port" {
  description = "Puerto en el contenedor"
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

data "aws_availability_zones" "available" {}

# Repositorios ECR (Requeridos para el push de imágenes)
import {
  to = aws_ecr_repository.app
  id = "devops-app"
}

resource "aws_ecr_repository" "app" {
  name                 = var.app_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true # Permite borrar el repositorio aunque tenga imágenes al hacer destroy
}

resource "aws_ecr_repository" "grafana" {
  name                 = "devops-grafana"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

# Red Básica (VPC y Subnets)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.app_name}-vpc"
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.rt.id
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-cluster"
}

# Definición de Tarea (Task Definition)
resource "aws_ecs_task_definition" "app" {
  family                   = var.app_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name  = var.app_name
      image = var.docker_image_name
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
        }
      ]
      environment = [
        { name = "ENV", value = var.environment }
      ]
    }
  ])
}

# Tarea Prometheus
resource "aws_ecs_task_definition" "prometheus" {
  family                   = "prometheus"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([{
    name  = "prometheus"
    image = "prom/prometheus:latest"
    portMappings = [{
      containerPort = 9090
      hostPort      = 9090
    }]
  }])
}

# Tarea Grafana
resource "aws_ecs_task_definition" "grafana" {
  family                   = "grafana"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([{
    name  = "grafana"
    image = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/devops-grafana:latest"
    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
    }]
    environment = [{ name = "GF_SECURITY_ADMIN_PASSWORD", value = "admin123" }]
  }])
}

# Load Balancer (ALB)
resource "aws_lb" "main" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "app" {
  name        = "${var.app_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path = "/health"
  }
}

resource "aws_lb_target_group" "prometheus" {
  name        = "${var.app_name}-prometheus-tg"
  port        = 9090
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path = "/-/healthy"
  }
}

resource "aws_lb_target_group" "grafana" {
  name        = "${var.app_name}-grafana-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path = "/api/health"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_listener" "prometheus" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.prometheus_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus.arn
  }
}

resource "aws_lb_listener" "grafana" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.grafana_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }
}

# ECS Service
resource "aws_ecs_service" "main" {
  name                              = var.app_name
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.app.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 60

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.public[*].id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = var.app_name
    container_port   = var.container_port
  }
}

resource "aws_ecs_service" "prometheus" {
  name                              = "prometheus"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.prometheus.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 60

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.public[*].id
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.prometheus.arn
    container_name   = "prometheus"
    container_port   = 9090
  }
}

resource "aws_ecs_service" "grafana" {
  name                              = "grafana"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.grafana.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 60
  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.public[*].id
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.grafana.arn
    container_name   = "grafana"
    container_port   = 3000
  }
}

# IAM Role para la ejecución de tareas de ECS
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.app_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Grupo de Seguridad para el Load Balancer
resource "aws_security_group" "lb" {
  name   = "${var.app_name}-lb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = var.prometheus_port
    to_port     = var.prometheus_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = var.grafana_port
    to_port     = var.grafana_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Grupo de Seguridad para las tareas de ECS
resource "aws_security_group" "ecs_tasks" {
  name   = "${var.app_name}-tasks-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol        = "tcp"
    from_port       = 3000
    to_port         = 3000
    security_groups = [aws_security_group.lb.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 9090
    to_port         = 9090
    security_groups = [aws_security_group.lb.id]
  }

  # Permitir comunicación interna entre tareas (necesario para Scraping y Data Sources)
  ingress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    self        = true
    description = "Allow internal traffic between ECS tasks"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Outputs
output "app_url" {
  description = "URL de la API (Load Balancer DNS)"
  value       = "http://${aws_lb.main.dns_name}"
}

output "prometheus_url" {
  description = "URL de Prometheus"
  value       = "http://${aws_lb.main.dns_name}:${var.prometheus_port}"
}

output "grafana_url" {
  description = "URL de la interfaz visual de Grafana (acceso de usuario)"
  value       = "http://${aws_lb.main.dns_name}:${var.grafana_port}"
}
