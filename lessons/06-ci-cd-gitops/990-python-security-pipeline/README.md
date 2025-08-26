# Python Security Pipeline Lesson - GitHub Native (100% Gratuito)

## Pipeline de Seguridad Completo usando SOLO GitHub Native Features

Este proyecto demuestra cómo implementar un pipeline de CI/CD de seguridad **completamente gratuito** usando exclusivamente herramientas nativas de GitHub y open source.

## 💰 **¿Por qué GitHub Native?**

- ✅ **$0 costo total** - Sin suscripciones ni tokens externos
- ✅ **Integración perfecta** - Resultados centralizados en Security tab
- ✅ **Sin configuración compleja** - No requiere secrets o tokens externos
- ✅ **Mantenimiento mínimo** - GitHub mantiene las herramientas
- ✅ **Enterprise ready** - Escalable para equipos grandes

## 🛡️ **Herramientas de Seguridad Implementadas**

### 1. **SAST (Static Application Security Testing)**
#### GitHub Native:
- **CodeQL** - Motor de análisis semántico avanzado de GitHub
  - Detecta: SQL injection, XSS, command injection, path traversal
  - Resultados automáticos en Security tab
  - Queries extendidas de seguridad y calidad

#### Open Source:
- **Bandit** - Linter de seguridad específico para Python
  - Detecta: Hardcoded secrets, weak crypto, insecure functions
  - Genera reportes SARIF para GitHub Security tab

### 2. **SCA (Software Composition Analysis)**
#### GitHub Native:
- **Dependabot** - Alertas automáticas de vulnerabilidades en dependencias
  - Updates automáticos de seguridad
  - PRs automáticos con patches
  - Integración con GitHub Advisory Database

#### Open Source:
- **Safety** - Base de datos de vulnerabilidades Python (PyUp.io)
- **pip-audit** - Herramienta oficial PyPA para auditoría de dependencias

### 3. **Secret Detection**
#### GitHub Native:
- **GitHub Secret Scanning** - Detección automática de secretos
  - Push protection habilitada
  - Patterns para +200 tipos de tokens
  - Alertas automáticas en Security tab

### 4. **Container Security**
- **Dockerfile Analysis** - Verificación de best practices
- **Image Layer Analysis** - Análisis básico de layers Docker

### 5. **Code Quality & Security**
- **Flake8** - Linting con reglas de seguridad
- **Pytest** - Testing con coverage de seguridad
- **GitHub Actions Security** - Análisis de workflows

## 📁 **Estructura del Proyecto**

```
python-security-pipeline-lesson/
├── .github/
│   ├── workflows/
│   │   └── security-pipeline.yml    # Pipeline GitHub Native (100% gratuito)
│   └── dependabot.yml               # Configuración Dependabot
├── tests/
│   └── test_app.py                  # Tests unitarios con coverage
├── app.py                           # Aplicación Flask con vulnerabilidades intencionadas
├── requirements.txt                 # Dependencias de Python (algunas vulnerables)
├── Dockerfile                       # Imagen Docker para testing
├── docker-compose.yml               # Para desarrollo local
├── .bandit                          # Configuración Bandit
├── pytest.ini                      # Configuración pytest
├── SECURITY.md                      # Política de seguridad del proyecto
└── README.md                        # Documentación completa
```

## 🎯 **Flujo del Pipeline**

### **Trigger Events:**
- ✅ Push a `main` o `develop`
- ✅ Pull Requests a `main`
- ✅ Dependabot automático (semanal)

### **Jobs Ejecutados:**

1. **codeql-analysis** - SAST con CodeQL (GitHub Native)
2. **python-security** - Bandit + Safety + pip-audit + Tests
3. **docker-security** - Análisis básico de container security
4. **secret-scanning-setup** - Configuración y verificación de secrets
5. **security-config** - Verificación de configuraciones de seguridad
6. **security-report** - Reporte consolidado y comentarios en PR

## 🚨 Vulnerabilidades Intencionadas

La aplicación `app.py` contiene vulnerabilidades intencionadas para demostrar las capacidades de los scanners:

1. **SQL Injection** (`get_user_by_id`): Concatenación directa en consultas SQL
2. **Command Injection** (`/ping`): Ejecución de comandos del sistema
3. **XSS** (`/search`): Renderizado sin escape de entrada de usuario
4. **Path Traversal** (`/file`): Lectura de archivos sin validación
5. **Hardcoded Credentials**: Contraseñas y API keys en código
6. **Weak Cryptography**: Uso de MD5 para hashing de contraseñas
7. **Debug Mode**: Flask en modo debug en producción

## 🔧 **Configuración del Pipeline**

### **NO se requieren Secrets! 🎉**

A diferencia de otros pipelines, este NO requiere configuración de tokens externos:

- ❌ No necesitas `SNYK_TOKEN`
- ❌ No necesitas `GITLEAKS_LICENSE`  
- ❌ No necesitas tokens de terceros
- ✅ Solo usa `GITHUB_TOKEN` (automático)

### **Configuración Automática**

GitHub habilita automáticamente:

1. **Dependabot** - Mediante `.github/dependabot.yml`
2. **Secret Scanning** - Automático para repos públicos
3. **CodeQL** - Configurado en el workflow
4. **Security Advisories** - Siempre activo

### **Para Repositorios Privados**

Si tu repo es privado, algunas features requieren GitHub Advanced Security:
- CodeQL: Requiere licencia ($21/committer/mes)
- Secret Scanning: Requiere licencia ($21/committer/mes)

**Alternativa gratuita**: Usar solo Bandit + Safety + pip-audit (funciona igual)

## 📋 **Cómo Usar Este Pipeline**

### **1. Fork o Clona el Proyecto**

```bash
git clone <tu-repo>
cd python-security-pipeline-lesson
```

### **2. ¡No hay configuración! Push directamente**

```bash
git add .
git commit -m "Initial commit with GitHub native security pipeline"  
git push origin main
```

### **3. Revisar Resultados (Todo en GitHub)**

#### **🔍 Security Tab**
- CodeQL findings (SAST)
- Bandit findings (Python security)
- Dependabot alerts (SCA)
- Secret scanning alerts

#### **⚡ Actions Tab**  
- Logs detallados de cada job
- Artifacts descargables (JSON reports)
- Coverage reports
- Build status

#### **🔔 Notifications**
- PRs automáticos de Dependabot
- Comentarios automáticos en PRs con security summary
- Email alerts para nuevas vulnerabilidades

### **4. Usar en tu Propio Proyecto**

1. Copia `.github/workflows/security-pipeline.yml`
2. Copia `.github/dependabot.yml`  
3. Copia `SECURITY.md` (opcional)
4. Adapta `requirements.txt` y tests a tu proyecto

## 📊 **Interpretación de Resultados**

### **🔍 Security Tab - Tu Dashboard Principal**

Aquí encontrarás todos los hallazgos centralizados:

#### **CodeQL (SAST)**
- **SQL Injection**: Detecta concatenación insegura en queries
- **XSS**: Encuentra renderizado sin escape  
- **Command Injection**: Identifica ejecución de comandos peligrosa
- **Path Traversal**: Detecta acceso a archivos sin validación

#### **Bandit (Python SAST)**  
- **Hardcoded Secrets**: Passwords/keys en código
- **Weak Cryptography**: Uso de MD5, SHA1, etc.
- **Insecure Functions**: `eval()`, `exec()`, `shell=True`
- **Debug Mode**: Flask debug en producción

#### **Dependabot (SCA)**
- **Known CVEs**: Vulnerabilidades públicas en dependencias
- **Severity Levels**: Critical, High, Medium, Low
- **Auto-fixes**: PRs automáticos con updates seguros

### **⚡ Actions Tab - Logs Detallados**

#### **Artifacts Descargables**
- `safety-results` - Reporte JSON de vulnerabilidades Python
- `pip-audit-results` - Auditoría oficial PyPA  
- `security-summary-report` - Reporte consolidado markdown

### **🔔 Notificaciones Automáticas**

- **Email alerts** cuando se detectan nuevas vulnerabilidades
- **PR comments** con summary de seguridad
- **Dependabot PRs** para updates de seguridad

## 🎓 **Objetivos de Aprendizaje**

Al completar esta lección, habrás aprendido:

### **1. GitHub Native Security**
- ✅ Configurar CodeQL para SAST avanzado
- ✅ Usar Dependabot para SCA automático  
- ✅ Habilitar GitHub Secret Scanning
- ✅ Centralizar resultados en Security tab

### **2. DevSecOps sin Costo**
- ✅ Implementar security shift-left gratuitamente
- ✅ Automatizar security testing sin herramientas pagas
- ✅ Generar reportes SARIF estándares
- ✅ Configurar alertas y notificaciones

### **3. Pipeline de Seguridad Escalable**
- ✅ Diseñar workflows para equipos grandes
- ✅ Manejar artifacts y reportes
- ✅ Configurar jobs paralelos para eficiencia
- ✅ Implementar conditional logic

### **4. Herramientas Open Source**
- ✅ Integrar Bandit para Python security
- ✅ Usar Safety y pip-audit para SCA
- ✅ Configurar testing con coverage
- ✅ Combinar múltiples herramientas efectivamente

### **5. Estrategia de Costo**
- ✅ Maximizar valor con herramientas gratuitas
- ✅ Entender cuándo vale la pena herramientas pagas
- ✅ Calcular ROI de security tooling
- ✅ Escalar security sin explotar el presupuesto

## 💰 **Análisis de Costos**

### **Repositorio PÚBLICO (Completamente Gratis)**
```
✅ GitHub Actions: Ilimitado
✅ CodeQL: Gratis  
✅ Dependabot: Gratis
✅ Secret Scanning: Gratis
✅ Todas las herramientas open source: Gratis

💲 COSTO TOTAL: $0/mes
```

### **Repositorio PRIVADO (Opciones)**
```
Opción 1 - Solo Open Source:
✅ Bandit + Safety + pip-audit: Gratis
❌ CodeQL: No disponible  
❌ Secret Scanning: No disponible
💲 COSTO: $0/mes

Opción 2 - GitHub Advanced Security:
✅ Todo lo anterior + CodeQL + Secret Scanning
💲 COSTO: $21/committer/mes

Opción 3 - Alternativa mixta:
✅ Open source tools + Snyk free tier
💲 COSTO: $0-52/mes (según uso)
```

## 🔗 **Recursos Adicionales**

### **Documentación GitHub**
- [GitHub Security Features](https://docs.github.com/en/code-security)
- [CodeQL Documentation](https://codeql.github.com/docs/)
- [Dependabot Configuration](https://docs.github.com/en/code-security/dependabot)

### **Herramientas Open Source**
- [Bandit Documentation](https://bandit.readthedocs.io/)
- [Safety Documentation](https://pyup.io/safety/)
- [pip-audit Guide](https://pypa.github.io/pip-audit/)

### **Security Best Practices**
- [OWASP DevSecOps Guide](https://owasp.org/www-project-devsecops-guideline/)
- [SARIF Format Specification](https://sarifweb.azurewebsites.net/)

## 🚀 **Siguientes Pasos**

### **Inmediatos (Hoy)**
1. Fork este proyecto
2. Habilita GitHub Security features en tu repo
3. Ejecuta el pipeline y revisa resultados
4. Configura Dependabot en tu proyecto actual

### **Esta Semana**
1. Adapta el workflow a tu tech stack
2. Configura custom Bandit rules
3. Establece security policies en tu equipo
4. Integra coverage goals en tu CI

### **Este Mes**
1. Implementa security metrics dashboard
2. Entrena a tu equipo en interpretación de resultados
3. Establece security gates en deployment
4. Evalúa herramientas pagas según crecimiento

---

## ⚠️ **Advertencias Importantes**

1. **Esta aplicación contiene vulnerabilidades INTENCIONADAS**
2. **NO usar en producción bajo ninguna circunstancia**
3. **Solo para propósitos educativos y testing**
4. **Revisar SECURITY.md antes de usar**

---

*¿Preguntas? Abre un issue en el repositorio* 💬