#!/bin/bash
# Setup Script - Inicializar proyecto local
set -e

echo "🚀 Inicializando proyecto DevOps..."

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar requisitos
echo -e "${YELLOW}📋 Verificando requisitos...${NC}"

check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}❌ $1 no encontrado${NC}"
        return 1
    fi
    echo -e "${GREEN}✓ $1${NC}"
}

check_command "git"
check_command "docker"
check_command "docker-compose"
check_command "python3"
check_command "pip3"
check_command "terraform"

echo -e "${GREEN}✓ Todos los requisitos instalados${NC}\n"

# Instalar dependencias Python
echo -e "${YELLOW}📦 Instalando dependencias Python...${NC}"
pip3 install -r requirements.txt

# Ejecutar tests
echo -e "${YELLOW}🧪 Ejecutando tests...${NC}"
pylint src/server.py --disable=C0103,R0913 || true
black --check src/ || true
pytest src/test_server.py -v || true

# Inicializar Terraform
echo -e "${YELLOW}🏗️  Inicializando Terraform...${NC}"
cd terraform
terraform init -backend=false || true
terraform validate || true
cd ..

# Construir imagen Docker
echo -e "${YELLOW}🐳 Construyendo imagen Docker...${NC}"
docker build -f docker/Dockerfile -t devops-app:latest . || true

echo -e "${GREEN}✓ Inicialización completada${NC}\n"

echo -e "${YELLOW}📝 Pasos siguientes:${NC}"
echo "1. Iniciar servicios: docker-compose up -d"
echo "2. Acceder a la app: http://localhost:3000"
echo "3. Prometheus: http://localhost:9090"
echo "4. Grafana: http://localhost:3001 (admin/admin123)"
echo ""
echo "-or-"
echo ""
echo "1. cd terraform"
echo "2. terraform init"
echo "3. terraform apply -auto-approve"
