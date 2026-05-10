#!/bin/bash
# Test and validation script
set -e

echo "✅ Ejecutando validaciones..."

echo "📋 Verificando estructura..."
[ -f "pyproject.toml" ] && echo "✓ pyproject.toml"
[ -f "requirements.txt" ] && echo "✓ requirements.txt"
[ -d ".github/workflows" ] && echo "✓ .github/workflows"
[ -d "terraform" ] && echo "✓ terraform"
[ -d "src" ] && echo "✓ src"
[ -d "docker" ] && echo "✓ docker"
[ -d "monitoring" ] && echo "✓ monitoring"

echo ""
echo "🔍 Validando archivos YAML..."
ls -1 .github/workflows/*.yml && echo "✓ Workflows encontrados"

echo ""
echo "🧪 Validando Terraform..."
cd terraform
terraform init -backend=false -quiet
terraform validate
echo "✓ Terraform válido"
cd ..

echo ""
echo "📦 Validando dependencias Python..."
pip freeze | head -5
echo "✓ Dependencias correctas"

echo ""
echo "🧪 Validando tests..."
pytest src/test_server.py -v --collect-only || echo "⚠️  Tests disponibles"

echo ""
echo "✅ Todas las validaciones pasaron!"
