# Terragrunt

Este tutorial muestra comandos comunes de Terragrunt y un ejemplo mínimo de uso para gestionar infraestructura como código sobre Terraform.

## Inicialización y Configuración
- `terragrunt init`: Inicializa Terragrunt en el directorio actual.
- `terragrunt plan`: Genera un plan de ejecución para la configuración de Terraform.
- `terragrunt apply`: Aplica los cambios a la infraestructura.
- `terragrunt destroy`: Destruye la infraestructura gestionada por Terraform.
- `terragrunt validate`: Valida los archivos de configuración de Terraform.
- `terragrunt graph`: Genera una representación visual del grafo de dependencias de Terraform.
- `terragrunt output`: Muestra los outputs de un stack.

## Gestión de Dependencias
- `terragrunt get`: Descarga y actualiza los módulos definidos en la configuración de Terraform.
- `terragrunt run-all`: Ejecuta un comando en todos los módulos de Terraform de un stack.
- `terragrunt plan-all`: Genera un plan para todos los módulos de Terraform de un stack.
- `terragrunt apply-all`: Aplica cambios en todos los módulos de Terraform de un stack.
- `terragrunt destroy-all`: Destruye todos los módulos de Terraform de un stack.
- `terragrunt validate-all`: Valida todos los módulos de Terraform de un stack.

> Esta lista no es exhaustiva, pero incluye los comandos más utilizados en Terragrunt.

---

## Ejemplo mínimo

Este ejemplo crea un bucket S3 en AWS usando Terraform y Terragrunt.

### Estructura de archivos

```
terragrunt/
├── main.tf
└── terragrunt.hcl
```

### main.tf
```hcl
provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "example" {
  bucket = var.bucket_name
}

variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "S3 bucket name"
  default     = "my-terragrunt-bucket-example"
}
```

### terragrunt.hcl
```hcl
terraform {
  source = "./"
}

inputs = {
  region      = "us-east-1"
  bucket_name = "my-terragrunt-bucket-example"
}
```

### Uso

1. Instala [Terraform](https://www.terraform.io/downloads.html) y [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/).
2. Ejecuta los siguientes comandos dentro del directorio `terragrunt`:

```bash
terragrunt init
terragrunt plan
terragrunt apply
```

Esto creará un bucket S3 en AWS usando la configuración mínima de ejemplo.
