# Guía de CI/CD con GitHub Actions

## Workflows Configurados

### 1. CI/CD Pipeline (ci-cd-pipeline.yml)

Se ejecuta en:
- Push a `main` o `develop`
- Pull Requests a `main` o `develop`
- Manualmente (workflow_dispatch)

#### Trabajos del Pipeline

##### 1.1 Lint & Code Analysis (2 min)
```yaml
- ESLint: Validación de estándares JavaScript
- npm audit: Escaneo de vulnerabilidades de dependencias
```

Estado: ⚠️ `continue-on-error: true` (no bloquea)

Ejecutar localmente:
```bash
npm run lint
npm run security:check
```

##### 1.2 Test & Coverage (3 min)
```yaml
- Jest: Ejecución de unit tests
- Coverage: Reporte de cobertura
- Codecov: Subida a Codecov para tracking
- PR Comment: Comenta cobertura en PRs
```

Estado: 🛑 Crítico (bloquea si falla)

Ejecutar localmente:
```bash
npm test
npm test -- --coverage
```

##### 1.3 Security Scanning (2 min)
```yaml
- Snyk: Análisis de vulnerabilidades profundo
Requiere: SNYK_TOKEN en GitHub Secrets
```

Estado: ⚠️ `continue-on-error: true`

##### 1.4 Generate SBOM (1 min)
```yaml
- CycloneDX: Genera Software Bill of Materials
- Artifact: Sube sbom.xml como artefacto
```

Ejecutar localmente:
```bash
npm run sbom:generate
```

##### 1.5 Build Docker Image (5-10 min)
```yaml
- Docker Build: Multi-stage build optimizado
- Registry Push: Sube a GHCR si es main
- Trivy Scan: Escanea vulnerabilidades de imagen
- SARIF Upload: Reporta a GitHub Security
```

Requiere:
- `GITHUB_TOKEN` (autom)
- Buildx para layers caché

Ejecutar localmente:
```bash
docker build -f docker/Dockerfile -t devops-app:latest .
trivy image devops-app:latest
```

##### 1.6 Deploy (1 min)
```yaml
- Deployment Report: Genera reporte
- Artifact: Sube deployment-report.md
Solo en: main branch, eventos push
```

##### 1.7 Pipeline Summary (1 min)
```yaml
- Summary: Resumen final del pipeline
- Issue Creation: Crea issue si hay fallo
```

### 2. Terraform Validation (terraform-validation.yml)

Se ejecuta cuando hay cambios en `terraform/**`

#### Trabajos
- Terraform Format Check: Valida fmt
- Terraform Init: Inicializa backend local
- Terraform Validate: Valida sintaxis
- TFLint: Linting específico de Terraform

Ejecutar localmente:
```bash
cd terraform
terraform fmt -check -recursive .
terraform init -backend=false
terraform validate
```

## Configurar Secrets de GitHub

Necesarios para el pipeline completo:

1. **SNYK_TOKEN** (Recomendado)
   ```bash
   # En https://snyk.io → Account settings → Auth tokens
   # Copiar token
   ```
   En GitHub → Settings → Secrets → New repository secret
   - Name: SNYK_TOKEN
   - Value: [tu token]

2. **CODECOV_TOKEN** (Opcional)
   - Para mejor tracking de coverage
   - Obtenible en codecov.io

## Trigger Manual del Pipeline

Opción 1: GitHub UI
- Actions → CI/CD Pipeline → Run workflow

Opción 2: GitHub CLI
```bash
gh workflow run ci-cd-pipeline.yml --ref main
```

Opción 3: Evento push
```bash
git push origin main
```

## Monitorear Ejecución

### Dashboard de Actions
1. GitHub → Actions
2. Seleccionar workflow
3. Click en run reciente
4. Ver detalles de cada job

### Artefactos
Disponibles al final del pipeline:
- `sbom` - SBOM CycloneDX XML
- `deployment-report` - Reporte de despliegue
- `trivy-results` - Resultados de escaneo Trivy

Descargar desde:
GitHub → Actions → [Run] → Artifacts

### Logs en Real-Time
```bash
# Con GitHub CLI
gh run watch [run-id]

# Ver logs de job específico
gh run view [run-id] --log --job [job-name]
```

## Condicionales y Gates

### Condiciones por Job
```yaml
needs: [test, security]  # Esperar otros jobs
if: github.ref == 'refs/heads/main'  # Solo en main
if: github.event_name != 'pull_request'  # No en PRs
```

### Requisitos para Merge
En GitHub → Settings → Branches → main →
- Require status checks to pass
- Require branches to be up to date
- Require code reviews

## Troubleshooting del Pipeline

### Job no se ejecuta
Check:
1. `on:` triggers en el YAML
2. Permisos en el archivo
3. Rama correcta

Solución:
```bash
# Validar YAML
ruby -e "require 'yaml'; YAML.load_file('.github/workflows/ci-cd-pipeline.yml')"

# O con yamllint
yamllint .github/workflows/
```

### Job failed: Out of disk
Sucede en runners con mucho build. Soluciones:
- Limpiar cache: `actions/setup-node` con `cache: 'npm'`
- Usar `npm ci` en lugar de `npm install`
- Limitar imagen tamaño

### ESLint/Tests fallan solo en CI
Causas comunes:
- Diferencias de línea (CRLF vs LF)
  ```bash
  # Configurar git
  git config core.autocrlf false
  ```
- Diferencia de versiones Node
  - Actualizar `node-version` en workflows
- Diferencia de env
  - Usar `.env.example` en CI

Soluciones:
```bash
# Ejecutar igual que CI localmente
node --version  # Debe coincidir
npm ci  # No npm install
npm run lint
npm test
```

### Push a registry falla
Check:
1. `GITHUB_TOKEN` disponible (automático)
2. Token tiene permisos `packages: write`
3. Logueo correcto: `docker/login-action`

## Información de Artifacts

### SBOM (CycloneDX)
- Ubicación: `sbom.xml`
- Generado por: `@cyclonedx/npm`
- Contiene: Lista completa de dependencias
- Usar para: Compliance, auditoría

### Deployment Report
- Ubicación: `deployment-report.md`
- Contiene: Image, branch, commit, timestamp
- Usar para: Registro de despliegues

### Trivy Results
- Ubicación: `trivy-results.sarif`
- Formato: SARIF (GitHub Security format)
- Visible en: GitHub Security tab

## Performance

Tiempos típicos:
```
Lint & Analysis: ~2 min
Test & Coverage: ~3 min
Security Scan:   ~2 min
Generate SBOM:   ~1 min
Build Docker:    ~5-10 min (1ra vez)
                 ~2-5 min (con cache)
Deploy:          ~1 min
Total: ~15-30 min (primera vez)
       ~10-20 min (con cache)
```

## Optimizaciones

1. **Node Dependencies Cache**
   ```yaml
   - uses: actions/setup-node@v3
     with:
       cache: 'npm'  # ← Cachea node_modules
   ```

2. **Docker Layer Caching**
   ```yaml
   cache-from: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache
   cache-to: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache,mode=max
   ```

3. **Parallel Jobs**
   - lint-and-analyze → independiente
   - test → después de lint
   - security → después de lint
   - build-docker → después de test + security
   - deploy → después de build

## Integración Continua Local

Probar pipeline localmente sin GitHub Actions:

```bash
# Con act (simula GitHub Actions localmente)
brew install act

# Ejecutar workflow
act -j lint-and-analyze

# Listar jobs disponibles
act -l
```

Instalación:
- macOS: `brew install act`
- Linux: `curl https://raw.githubusercontent.com/nektos/act/master/install.sh | bash`

## Referencia Rápida

| Comando | Descripción |
|---------|-------------|
| `npm run lint` | ESLint |
| `npm test` | Jest tests |
| `npm run security:check` | npm audit |
| `npm run sbom:generate` | CycloneDX SBOM |
| `docker build .` | Build imagen |
| `trivy image img:tag` | Scan imagen |
| `cd terraform && terraform validate` | Validar TF |
