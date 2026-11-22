variable "name_prefix" {
  description = "Prefixo dos nomes."
  type        = string
}

variable "project" {
  description = "Nome do projeto (aparece na página do Nginx)."
  type        = string
}

variable "environment" {
  description = "Nome do ambiente (aparece na página do Nginx)."
  type        = string
}

variable "vpc_id" {
  description = "VPC onde o security group é criado."
  type        = string
}

variable "subnet_id" {
  description = "Sub-rede pública onde a instância sobe."
  type        = string
}

variable "ami_id" {
  description = "AMI da instância."
  type        = string
}

variable "instance_type" {
  description = "Tipo da instância."
  type        = string
}

variable "allowed_http_cidrs" {
  description = "Quem pode acessar a porta 80."
  type        = list(string)
}

variable "ssh_cidr" {
  description = "CIDR liberado para SSH (porta 22). null = SSH fechado (padrão)."
  type        = string
  default     = null
}
