output "vpc_id" {
  description = "ID da VPC criada."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Sub-redes públicas (uma por AZ)."
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Sub-redes privadas (uma por AZ)."
  value       = module.network.private_subnet_ids
}

output "instance_id" {
  description = "ID da EC2."
  value       = module.compute.instance_id
}

output "web_url" {
  description = "Endereço do Nginx (na AWS real; no LocalStack o IP é simulado)."
  value       = "http://${module.compute.public_ip}"
}
