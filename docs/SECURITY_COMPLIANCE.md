# Guía de Seguridad y Compliance

## Análisis de Seguridad

### 1. PyLint & Black - Análisis Estático

**Herramientas**: `pylint` para lógica y `black` para formato.

**Ejecutar**:
```bash
pylint src/server.py
black --check src/
```

Problemas que detecta:
- Sintaxis inválida
- Variables no usadas
- Uso de `eval()`
- Comparaciones sospechosas
- Prácticas inseguras

### 2. pip check & pip-audit - Auditoría de Dependencias

**Ejecutar**:
```bash
pip check
pip install pip-audit && pip-audit -r requirements.txt
```

**Niveles**:
- critical: CVSS 9-10
- high: CVSS 7-8.9
- moderate: CVSS 4-6.9
- low: CVSS 0-3.9

**Gestión de falsos positivos**:
```bash
# Crear .auditignore para ignorar CVEs específicas
echo "1234567" >> .auditignore  # CVE ID
npm audit --ignore 1234567
```

### 3. Snyk - Deep Security Analysis

**Setup**:
```bash
npm install -g snyk
snyk auth           # Authenticate
snyk test           # Test vulnerabilities
snyk test --json    # JSON output
snyk monitor        # Monitor en tiempo real
```

**Nivel de severidad**:
- Critical: Exploit conocido, usar en producción
- High: Potencial acceso RCE/auth bypass
- Medium: Potencial DoS/información disclosure
- Low: Edge cases

**GitHub Action**:
El workflow usa `snyk/actions/node@master` automáticamente.
Requiere: `secrets.SNYK_TOKEN`

### 4. Trivy - Escaneo de Imágenes Docker

**Ejecutar localmente**:
```bash
# Instalar
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Escanear imagen
trivy image devops-app:latest

# JSON output
trivy image --format json --output trivy-results.json devops-app:latest

# Filtrar por severidad
trivy image --severity CRITICAL,HIGH devops-app:latest
```

**Qué escanea**:
- Vulnerabilidades de SO (Alpine, Ubuntu, etc.)
- Vulnerabilidades de aplicación
- Configuración insegura
- Secrets expuestas

### 5. SBOM (Software Bill of Materials)

**Generación automática**:
El pipeline genera `sbom.xml` en formato CycloneDX.

**Generar localmente**:
```bash
npm run sbom:generate
```

**Contenido**:
```xml
<?xml version="1.0"?>
<bom xmlns="http://cyclonedx.org/schema/bom/1.4">
  <metadata>
    <component type="application">
      <name>devops-app</name>
      <version>1.0.0</version>
    </component>
  </metadata>
  <components>
    <!-- Lista de dependencias con versiones -->
  </components>
</bom>
```

**Usar SBOM**:
- Compliance (SOC 2, ISO 27001)
- Supply chain security
- Audit de dependencias
- Tracking de licencias

**Reproducibilidad**:
SBOM + SBOM.sig (firma) = reproducible

## Seguridad del Dockerfile

### Mejores Prácticas Implementadas

1. **Multi-stage build**
   ```dockerfile
   FROM node:18-alpine AS builder
   # Build stage
   ...
   FROM node:18-alpine
   # Runtime stage - imagen final más pequeña
   ```
   Beneficio: Imagen final ~100MB (vs 500MB sin multi-stage)

2. **Usuario no-root**
   ```dockerfile
   RUN adduser -S nodejs -u 1001
   USER nodejs
   ```
   Beneficio: Ataque limitado a permisos de usuario

3. **Health checks**
   ```dockerfile
   HEALTHCHECK --interval=30s --timeout=10s
     CMD node -e "require('http').get(...)"
   ```
   Beneficio: Orquestadores pueden restart automático

4. **npm ci (Clean Installation)**
   ```dockerfile
   RUN npm ci instead of npm install
   ```
   Beneficio: Versiones exactas, reproducible

5. **Alpine Linux**
   ```dockerfile
   FROM node:18-alpine
   ```
   Beneficio: Imagen pequeña, menor superficie de ataque

6. **Minimizar layers**
   - Combinar comandos RUN con `&&`
   - Reduce números de layers filesystem

7. **Secrets management**
   - NO hardcodear secrets
   - Usar Build Args con default vacío
   - Usar Docker Secrets en producción (Swarm)

## Seguridad del Código

### Entrada/Salida Segura
```javascript
// ✅ SEGURO
app.use(express.json({ limit: '1mb' }));  // Limitar payload
const num = parseInt(userInput, 10);       // Parse con radix

// ❌ INSEGURO
eval(userInput);                           // Nunca!
app.use(express.json());                   // Sin límite
```

### Manejo de Errores
```javascript
// ✅ SEGURO
catch (err) {
  console.error('Error occurred');
  res.status(500).json({ error: 'Internal Server Error' });
}

// ❌ INSEGURO
catch (err) {
  res.status(500).json({ error: err.message, stack: err.stack });
}
```

### Variables de Entorno
```javascript
// ✅ SEGURO
const SECRET = process.env.SECRET_KEY;
if (!SECRET) throw new Error('SECRET_KEY no configurada');

// ❌ INSEGURO
const SECRET = "hardcoded-secret";
```

## GitHub Security Features

### 1. Dependabot
En Settings → Security & Analysis →
- Enable Dependabot alerts
- Enable Dependabot security updates
- Enable Dependabot version updates

### 2. Code Scanning
- Integración con Trivy (SARIF)
- Resultados en Security tab
- Alertas automáticas en PRs

### 3. Secret Scanning
- GitHub busca patrones de secrets
- Notifica si encuentra

Para ignorar falsos positivos:
En archivo `.github/secret_scanning.yml`:
```yaml
patterns:
  - pattern: 'my-false-positive'
    type: regex
```

### 4. Branch Protection Rules
Settings → Branches → main →
- ✅ Require pull request reviews
- ✅ Require status checks to pass
- ✅ Require branches to be up to date
- ✅ Dismiss stale pull request approvals

## Hardening de Seguridad Adicional

### 1. CORS Configuration
```javascript
const cors = require('cors');
app.use(cors({
  origin: process.env.CORS_ORIGIN || 'http://localhost:3000',
  credentials: true
}));
```

### 2. Helmet (Security headers)
```bash
npm install helmet
```
```javascript
const helmet = require('helmet');
app.use(helmet());
```

### 3. Rate Limiting
```bash
npm install express-rate-limit
```
```javascript
const rateLimit = require('express-rate-limit');
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100
});
app.use('/api/', limiter);
```

### 4. Request Validation
```bash
npm install joi
```
```javascript
const schema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().min(8).required()
});

app.post('/login', (req, res) => {
  const { error } = schema.validate(req.body);
  if (error) return res.status(400).json({ error });
});
```

## Compliance Frameworks

### SOC 2 Type II
- Change management (git history)
- Access controls (RBAC)
- Audit logs (GitHub Actions logs)
- Incident response (GitHub Issues)

### ISO 27001
- Information security policies (SECURITY.md)
- Access control (branch protection)
- Encryption in transit (HTTPS)
- Incident management

### OWASP Top 10
- Injection: Validация de entrada
- Broken Auth: JWT/OAuth
- Sensitive Data Exposure: Encryption
- XML External Entities: Parsers seguros
- Broken Access Control: RBAC
- Misconfiguración: Hardening
- XSS: Output encoding
- Insecure Deserialization: Avoid eval()
- Using Components with Known Vulns: Dependabot
- Insufficient Logging: Structured logs

## Escaneos Periódicos

### Automático
- npm audit: En cada PR (GitHub Actions)
- Dependabot: Diario (automático GitHub)
- Trivy: En cada build Docker

### Manual (Recomendado mensual)
```bash
npm audit                      # Dependencias
trivy fs .                     # Filesystem
trivy image devops-app:latest  # Imagen
snyk test                      # Snyk
```

### Reportes para Compliance
```bash
# Generar reportes para stakeholders
npm audit --json > audit-report.json
trivy image --format json devops-app:latest > trivy-report.json
```

## Licencias

### Verificar Licencias de Dependencias
```bash
npm install -g license-checker
license-checker --json > licenses.json
```

### Conformidad de Licencias
- MIT: ✅ Permisiva
- Apache 2.0: ✅ Permisiva
- BSD: ✅ Permisiva
- GPL v3: ⚠️ Copyleft (código debe ser open-source)
- Proprietary: ❌ No permitida

Excluir dependencias problemáticas:
```bash
npm uninstall problematic-package
npm install alternative-package
```

## Checklist de Seguridad

- [ ] ESLint configurado y ejecutándose
- [ ] npm audit pasa nivel moderate
- [ ] Snyk token configurado en GitHub Secrets
- [ ] Dockerfile usa usuario no-root
- [ ] Trivy scan sin CRITICAL vulnerabilidades
- [ ] SBOM generado y versionado
- [ ] Branch protection rules habilitadas
- [ ] Dependabot habilitado
- [ ] Code scanning habilitado
- [ ] Secret scanning habilitado
- [ ] Correr audit mensualmente
- [ ] Documentación de seguridad actualizada
