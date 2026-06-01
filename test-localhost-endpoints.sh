#!/bin/bash

# Script interactivo para probar todos los endpoints de la API
# Presiona Enter después de cada prueba para continuar

echo "════════════════════════════════════════════════════════════════"
echo "🧪 PRUEBAS INTERACTIVAS - DevOps Pipeline API"
echo "════════════════════════════════════════════════════════════════"
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
echo "📤 Request: curl http://localhost:3000/"
echo "───────────────────────────────────────────────────────────────── "
echo "📥 Response:"
curl -s http://localhost:3000/ | jq .
pause

# 2. GET /health
echo "2️⃣  GET /health (Health Check)"
echo "─────────────────────────────────────────────────────────────────"
echo "📤 Request: curl http://localhost:3000/health"
echo "─────────────────────────────────────────────────────────────────"
echo "📥 Response:"
curl -s http://localhost:3000/health | jq .
pause

# 3. GET /api/info
echo "3️⃣  GET /api/info (Información de App)"
echo "─────────────────────────────────────────────────────────────────"
echo "📤 Request: curl http://localhost:3000/api/info"
echo "─────────────────────────────────────────────────────────────────"
echo "📥 Response:"
curl -s http://localhost:3000/api/info | jq .
pause

# 4. POST /api/echo
echo "4️⃣  POST /api/echo (Echo - Enviar datos)"
echo "─────────────────────────────────────────────────────────────────"
echo "📤 Request: curl -X POST http://localhost:3000/api/echo \\"
echo "      -H 'Content-Type: application/json' \\"
echo "      -d '{\"message\":\"Hola desde test-endpoints.sh\"}'"
echo "─────────────────────────────────────────────────────────────────"
echo "📥 Response:"
curl -s -X POST http://localhost:3000/api/echo \
  -H "Content-Type: application/json" \
  -d '{"message":"Hola desde test-endpoints.sh","timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%S)'"}' | jq .
pause

# 5. GET /api/status/app
echo "5️⃣  GET /api/status/app (Status - App)"
echo "─────────────────────────────────────────────────────────────────"
echo "📤 Request: curl http://localhost:3000/api/status/app"
echo "─────────────────────────────────────────────────────────────────"
echo "📥 Response:"
curl -s http://localhost:3000/api/status/app | jq .
pause

# 6. GET /api/status/prometheus
echo "6️⃣  GET /api/status/prometheus (Status - Prometheus)"
echo "─────────────────────────────────────────────────────────────────"
echo "📤 Request: curl http://localhost:3000/api/status/prometheus"
echo "─────────────────────────────────────────────────────────────────"
echo "📥 Response:"
curl -s http://localhost:3000/api/status/prometheus | jq .
pause

# 7. GET /api/status/grafana
echo "7️⃣  GET /api/status/grafana (Status - Grafana)"
echo "─────────────────────────────────────────────────────────────────"
echo "📤 Request: curl http://localhost:3000/api/status/grafana"
echo "─────────────────────────────────────────────────────────────────"
echo "📥 Response:"
curl -s http://localhost:3000/api/status/grafana | jq .
pause

# 8. GET /metrics (primeras 20 líneas)
echo "8️⃣  GET /metrics (Prometheus Metrics)"
echo "─────────────────────────────────────────────────────────────────"
echo "📤 Request: curl http://localhost:3000/metrics | head -20"
echo "─────────────────────────────────────────────────────────────────"
echo "📥 Response (primeras 20 líneas):"
curl -s http://localhost:3000/metrics | head -20
echo ""
echo "... (mostrando 20 líneas de métricas) ..."
pause

# 9. GET /docs (Swagger UI disponible)
echo "9️⃣  Documentación Interactiva"
echo "─────────────────────────────────────────────────────────────────"
echo "✓ Swagger UI:   http://localhost:3000/docs"
echo "✓ ReDoc:        http://localhost:3000/redoc"
echo "✓ OpenAPI JSON: http://localhost:3000/openapi.json"
pause

# 10. Test error - servicio inválido
echo "🔟 GET /api/status/invalid (Test Error - Servicio inválido)"
echo "─────────────────────────────────────────────────────────────────"
echo "📤 Request: curl http://localhost:3000/api/status/invalid"
echo "─────────────────────────────────────────────────────────────────"
echo "📥 Response (Error esperado):"
curl -s http://localhost:3000/api/status/invalid | jq .
pause

echo "════════════════════════════════════════════════════════════════"
echo "✅ TODAS LAS PRUEBAS COMPLETADAS"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📊 Servicios disponibles:"
echo "   • FastAPI App:  http://localhost:3000"
echo "   • Prometheus:   http://localhost:9090"
echo "   • Grafana:      http://localhost:3001 (admin/admin123)"
echo ""
