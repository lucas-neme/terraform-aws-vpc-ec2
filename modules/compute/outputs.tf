output "instance_id" {
  description = "ID da instância."
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "IP público da instância."
  value       = aws_instance.web.public_ip
}

output "security_group_id" {
  description = "ID do security group web."
  value       = aws_security_group.web.id
}
