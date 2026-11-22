variable "aws_region" {
  description = "Região AWS do bucket de state."
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Nome do bucket S3 que guarda o state remoto (na AWS real precisa ser único no mundo)."
  type        = string
  default     = "tfstate-getrak-lab"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.state_bucket_name))
    error_message = "Nome de bucket S3 inválido: use 3-63 caracteres minúsculos, números, ponto ou hífen."
  }
}

variable "use_localstack" {
  description = "true = fala com o LocalStack (padrão do lab); false = AWS real."
  type        = bool
  default     = true
}

variable "localstack_endpoint" {
  description = "URL do LocalStack."
  type        = string
  default     = "http://localhost:4566"
}

variable "force_destroy" {
  description = "Permite apagar o bucket mesmo com objetos dentro. true só no lab; na AWS real use false."
  type        = bool
  default     = true
}
