#!/bin/bash
set -e

echo "🛑 Destruyendo infraestructura..."
terraform destroy -auto-approve

echo "✓ Infraestructura destruida"
