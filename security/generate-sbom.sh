#!/bin/bash
# Script para generar SBOM local sin depender de npm scripts

set -e

echo "📦 Generando SBOM con CycloneDX..."

# Verificar si npm está instalado
if ! command -v npm &> /dev/null; then
    echo "❌ npm no está instalado"
    exit 1
fi

# Instalar cyclonedx-npm globalmente si es necesario
if ! npm list -g @cyclonedx/npm &> /dev/null; then
    echo "Instalando @cyclonedx/npm..."
    npm install -g @cyclonedx/npm
fi

# Generar SBOM
cd "$(dirname "$0")/.."
cyclonedx-npm --output-file sbom.xml

echo "✓ SBOM generado: sbom.xml"
ls -lh sbom.xml
