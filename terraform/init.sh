#!/bin/bash
set -e

echo "🚀 Inicializando Terraform..."
terraform init

echo "📋 Validando configuración..."
terraform validate

echo "📊 Generando plan..."
terraform plan -out=tfplan

echo "✓ Plan generado. Ejecutar con: terraform apply tfplan"
