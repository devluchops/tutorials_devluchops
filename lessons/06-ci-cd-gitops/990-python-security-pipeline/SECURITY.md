# Security Policy

## Supported Versions

Esta aplicación es un proyecto de demostración educativa con vulnerabilidades intencionadas para testing de seguridad.

⚠️ **IMPORTANTE**: Esta aplicación NO debe usarse en producción ya que contiene vulnerabilidades intencionadas.

## Reporting a Vulnerability

Si encuentras una vulnerabilidad de seguridad en este proyecto educativo:

1. **NO** crear un issue público
2. Contactar al mantenedor vía email privado
3. Proporcionar detalles de la vulnerabilidad
4. Esperar confirmación antes de divulgación pública

## Vulnerabilidades Intencionadas

Este proyecto contiene las siguientes vulnerabilidades **intencionadas** para propósitos educativos:

### 🔴 Vulnerabilidades SAST
- **SQL Injection** en `get_user_by_id()` - app.py:8
- **Command Injection** en `/ping` endpoint - app.py:14
- **XSS** en `/search` endpoint - app.py:21
- **Path Traversal** en `/file` endpoint - app.py:32
- **Hardcoded Secrets** - app.py:44-45
- **Weak Cryptography** (MD5) en `register()` - app.py:53

### 🔴 Vulnerabilidades de Configuración
- Debug mode habilitado en producción - app.py:78
- Binding a todas las interfaces (0.0.0.0) - app.py:78

### 🔴 Vulnerabilidades de Dependencias
- Versiones específicas con vulnerabilidades conocidas en `requirements.txt`

## Herramientas de Detección

Estas vulnerabilidades pueden ser detectadas por:

- **CodeQL**: SQL injection, XSS, command injection
- **Bandit**: Hardcoded secrets, weak cryptography, debug mode
- **Safety/pip-audit**: Vulnerabilidades en dependencias
- **Dependabot**: Updates automáticos de dependencias vulnerables

## Uso Responsable

Este proyecto es únicamente para:
- ✅ Aprendizaje de seguridad
- ✅ Testing de herramientas de seguridad  
- ✅ Demonstraciones educativas
- ✅ Desarrollo de skills en DevSecOps

NO usar para:
- ❌ Aplicaciones de producción
- ❌ Almacenar datos reales
- ❌ Ataques maliciosos
- ❌ Cualquier uso no ético

## Contacto

Para preguntas sobre seguridad contactar:
- Email: security@example.com
- GitHub Issues: Solo para vulnerabilidades no intencionadas