variable "project" {
  description = "Nome curto do projeto (entra nos nomes e tags)."
  type        = string
  default     = "getrak-lab"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.project))
    error_message = "project: 3-21 caracteres, minúsculas, números e hífen, começando por letra."
  }
}

variable "environment" {
  description = "Ambiente: dev ou prod."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment precisa ser \"dev\" ou \"prod\"."
  }
}

variable "aws_region" {
  description = "Região AWS."
  type        = string
  default     = "us-east-1"
}

variable "azs" {
  description = "Exatamente 2 zonas de disponibilidade (alta disponibilidade mínima)."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.azs) == 2 && length(distinct(var.azs)) == 2
    error_message = "Informe exatamente 2 AZs diferentes."
  }
}

variable "vpc_cidr" {
  description = "CIDR da VPC. Precisa ser /16 para caber as sub-redes /24."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && endswith(var.vpc_cidr, "/16")
    error_message = "vpc_cidr precisa ser um CIDR válido terminado em /16 (ex.: 10.10.0.0/16)."
  }
}

variable "instance_type" {
  description = "Tipo da EC2. Só tipos baratos são aceitos, para ninguém subir uma máquina cara por engano."
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t2.micro", "t3.micro", "t3.small"], var.instance_type)
    error_message = "instance_type permitido: t2.micro, t3.micro ou t3.small."
  }
}

variable "ami_id" {
  description = "AMI fixa. null = buscar a Ubuntu 24.04 mais recente da Canonical (AWS real)."
  type        = string
  default     = null
}

variable "allowed_http_cidrs" {
  description = "CIDRs que podem acessar a porta 80."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for c in var.allowed_http_cidrs : can(cidrhost(c, 0))])
    error_message = "Todos os itens de allowed_http_cidrs precisam ser CIDRs válidos."
  }
}

variable "ssh_cidr" {
  description = "CIDR liberado para SSH. null (padrão) = porta 22 fechada."
  type        = string
  default     = null

  validation {
    condition     = var.ssh_cidr == null || can(cidrhost(var.ssh_cidr, 0))
    error_message = "ssh_cidr precisa ser null ou um CIDR válido (ex.: 203.0.113.10/32)."
  }
}

variable "use_localstack" {
  description = "true = LocalStack (padrão do lab, custo zero); false = AWS real."
  type        = bool
  default     = true
}

variable "localstack_endpoint" {
  description = "URL do LocalStack."
  type        = string
  default     = "http://localhost:4566"
}
