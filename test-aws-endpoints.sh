#!/bin/bash

# Script interactivo para probar todos los endpoints de la API en AWS
# Apunta a ALB en AWS ECS
# Presiona Enter después de cada prueba para continuar

# URL del ALB
ALB_URL="http://devops-app-alb-1530031189.us-east-1.elb.amazonaws.com"

echo "════════════════════════════════════════════════════════════════"
echo "🧪 PRUEBAS INTERACTIVAS - DevOps Pipeline API (AWS ECS)"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📍 Apuntando a: $ALB_URL"
echo ""
echo "Después de cada Request, presiona ENTER para continuar..."
echo ""

# Función auxiliar para esperar Enter
pause() {
    read -p "≡ Presiona ENTER para continuar..."
    echo ""
}

# 1. GET /
echo "1️⃣  GET / (Root - Saludo)"
echo "─────────────────────────────────────────────────────────────────"
echo "📤 Request: curl $ALB_URL/"
echo "───────────────────────────────────────────────────────────────── "
echo "📥 Response:"
curl -s "$ALB_URL/" | jq .
pause

# 2. GET /health
echo "2️⃣  GET /health (Health Check)"
echo "─────────────────────────────────────────────────────────────────"
echo "📤 Request: curl $ALB_URL/health"
echo "─────────────────────────────────────────────────────────────────"
echo "📥 Response:"
curl -s "$ALB_URL/health" | jq .
pause

# 3. GET /api/info
echo "3️⃣  GET /api/info (Información de App)"
echo "─────────────────────────────────────────────────────────────────"
echo "📤 Request: curl $ALB_URL/api/info"
echo "─────────────────────────────────────────────────────────────────"
echo "📥 Response:"
curl -s "$ALB_URL/api/info" | jq .
pause

# 4. POST /api/echo
echo "4️⃣  POST /api/echo (Echo - Enviar datos)"
echo "─────────────────────────────────────────────────────────────────"
echo "📤 Request: curl -X POST $ALB_URL/api/echo \\"
echo "      -H 'Content-Type: application/json' \\"
echo "      -d '{\"message\":\"Hola desde AWS ECS\"}'"
echo "─────────────────────────────────────────────────────────────────"
echo "📥 Response:"
curl -s -X POST "$ALB_URL/api/echo" \
  -H "Content-Type: application/json" \
  -d '{"message":"Hola desde AWS ECS","timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%S)'"}' | jq .
pause

# 5. GET /api/status/app
echo "5️⃣  GET /api/status/app (Status - App)"
echo "─────────────────────────────────────────────────────────────────"
echo "📤 Request: curl $ALB_URL/api/status/app"
echo "─────────────────────────────────────────────────────────────────"
echo "📥 Response:"
curl -s "$ALB_URL/api/status/app" | jq .
pause

# 6. GET /api/status/prometheus
echo "6️⃣  GET /api/status/prometheus (Status - Prometheus)"
echo "─────────────────────────────────────────────────────────────────"
echo "📤 Request: curl $ALB_URL/api/status/prometheus"
echo "─────────────────────────────────────────────────────────────────"
echo "📥 Response:"
curl -s "$ALB_URL/api/status/prometheus" | jq .
pause

# 7. GET /api/status/grafana
echo "7️⃣  GET /api/status/grafana (Status - Grafana)"
echo "─────────────────────────────────────────────────────────────────"
echo "📤 Request: curl $ALB_URL/api/status/grafana"
echo "─────────────────────────────────────────────────────────────────"
echo "📥 Response:"
curl -s "$ALB_URL/api/status/grafana" | jq .
pause

# 8. GET /metrics (primeras 20 líneas)
echo "8️⃣  GET /metrics (Prometheus Metrics)"
echo "─────────────────────────────────────────────────────────────────"
echo "📤 Request: curl $ALB_URL/metrics | head -20"
echo "─────────────────────────────────────────────────────────────────"
echo "📥 Response (primeras 20 líneas):"
curl -s "$ALB_URL/metrics" | head -20
echo ""
echo "... (mostrando 20 líneas de métricas) ..."
pause

# 9. Test error - servicio inválido
echo "9️⃣  GET /api/status/invalid (Test Error - Servicio inválido)"
echo "─────────────────────────────────────────────────────────────────"
echo "📤 Request: curl $ALB_URL/api/status/invalid"
echo "─────────────────────────────────────────────────────────────────"
echo "📥 Response (Error esperado):"
curl -s "$ALB_URL/api/status/invalid" | jq .
pause

# 10. Test OpenAPI
echo "🔟 OpenAPI Documentation"
echo "─────────────────────────────────────────────────────────────────"
echo "✓ Swagger UI:   $ALB_URL/docs"
echo "✓ ReDoc:        $ALB_URL/redoc"
echo "✓ OpenAPI JSON: $ALB_URL/openapi.json"
pause

echo "════════════════════════════════════════════════════════════════"
echo "✅ TODAS LAS PRUEBAS COMPLETADAS"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📊 Información de Acceso:"
echo "   • API Base URL:  $ALB_URL"
echo "   • Región AWS:    us-east-1"
echo "   • Servicio:      ECS Fargate"
echo "   • Load Balancer: Application Load Balancer (ALB)"
echo ""
echo "📌 Puedes cambiar la URL editando ALB_URL en este script"
echo ""
