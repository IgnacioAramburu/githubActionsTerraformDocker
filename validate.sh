#!/bin/bash

echo "==========================================================="
echo "VALIDADOR - DevOps Pipeline"
echo "==========================================================="
echo ""

echo "Verificando estructura..."
[ -f "pyproject.toml" ] && echo "[OK] pyproject.toml" || echo "[FAIL] pyproject.toml"
[ -f "requirements.txt" ] && echo "[OK] requirements.txt" || echo "[FAIL] requirements.txt"
[ -d ".github/workflows" ] && echo "[OK] .github/workflows" || echo "[FAIL] .github/workflows"
[ -d "terraform" ] && echo "[OK] terraform" || echo "[FAIL] terraform"
[ -d "src" ] && echo "[OK] src" || echo "[FAIL] src"
[ -d "docker" ] && echo "[OK] docker" || echo "[FAIL] docker"
[ -d "docs" ] && echo "[OK] docs" || echo "[FAIL] docs"

echo ""
echo "Validando Terraform..."
if command -v terraform > /dev/null 2>&1; then
    cd terraform
    terraform validate > /dev/null 2>&1 && echo "[OK] Terraform valid" || echo "[FAIL] Terraform"
    cd ..
else
    echo "[WARN] Terraform not installed"
fi

echo ""
echo "Validando Python..."
if command -v python3 > /dev/null 2>&1; then
    echo "[OK] Python $(python3 --version 2>&1 | awk '{print $2}')"
else
    echo "[FAIL] Python not found"
fi

echo ""
echo "==========================================================="
echo "Validacion completada!"
echo "==========================================================="
