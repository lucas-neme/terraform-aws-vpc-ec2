variable "name_prefix" {
  description = "Prefixo dos nomes (ex.: getrak-lab-dev)."
  type        = string
}

variable "vpc_cidr" {
  description = "Bloco CIDR da VPC (ex.: 10.10.0.0/16)."
  type        = string
}

variable "azs" {
  description = "Zonas de disponibilidade: uma sub-rede pública e uma privada em cada."
  type        = list(string)
}
