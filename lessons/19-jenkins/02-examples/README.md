# Jenkins - Ejemplos

Ejemplos prácticos de uso de Jenkins:

- **Declarative Pipeline**
- **Scripted Pipeline**
- **Integración con GitHub**
- **Despliegue a Kubernetes**

## Ejemplo: Declarative Pipeline básico

```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                echo 'Compilando...'
            }
        }
        stage('Test') {
            steps {
                echo 'Ejecutando tests...'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Desplegando aplicación...'
            }
        }
    }
}
```

Agrega más ejemplos o casos de uso según tus necesidades.
