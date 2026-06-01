#!/bin/bash
# Script para generar SBOM local sin depender de npm scripts

set -e

echo "📦 Generando SBOM con CycloneDX..."

# Verificar si python3 está instalado
if ! command -v python3 &> /dev/null; then
    echo "❌ python3 no está instalado"
    exit 1
fi

# Instalar cyclonedx-bom si es necesario
if ! pip show cyclonedx-bom &> /dev/null; then
    echo "Instalando cyclonedx-bom..."
    pip install cyclonedx-bom
fi

# Generar SBOM
cd "$(dirname "$0")/.."
cyclonedx-py requirements requirements.txt --output-format xml --output-file sbom.xml

echo "✓ SBOM generado: sbom.xml"
ls -lh sbom.xml
