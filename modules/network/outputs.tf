output "vpc_id" {
  description = "ID da VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs das sub-redes públicas, na ordem de var.azs."
  value       = [for az in var.azs : aws_subnet.public[az].id]
}

output "private_subnet_ids" {
  description = "IDs das sub-redes privadas, na ordem de var.azs."
  value       = [for az in var.azs : aws_subnet.private[az].id]
}

output "public_subnet_cidrs" {
  description = "CIDRs das sub-redes públicas."
  value       = [for az in var.azs : aws_subnet.public[az].cidr_block]
}

output "private_subnet_cidrs" {
  description = "CIDRs das sub-redes privadas."
  value       = [for az in var.azs : aws_subnet.private[az].cidr_block]
}
