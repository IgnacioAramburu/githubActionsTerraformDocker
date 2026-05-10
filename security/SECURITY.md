# Configuración de Seguridad

## Escaneo de Dependencias
- npm audit
- Snyk scanning

## Linting
- ESLint para análisis estático

## SBOM (Software Bill of Materials)
- Formato CycloneDX
- Ubicación: `sbom.xml`

## Análisis de Imágenes Docker
- Trivy para vulnerabilidades en imágenes

## Secretos
- GitHub Secrets para SNYK_TOKEN
- No commitear `.env` files

## Recomendaciones
1. Usar ramas protegidas con checks requeridos
2. Revisar dependencias regularmén
3. Mantener Node.js actualizado
4. Usar HTTPS para todas las comunicaciones
5. Implementar RBAC en contenedores
