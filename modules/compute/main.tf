resource "aws_security_group" "web" {
  name        = "${var.name_prefix}-web"
  description = "Nginx: HTTP de entrada; saida so HTTP/HTTPS (apt) e DNS"
  vpc_id      = var.vpc_id

  tags = { Name = "${var.name_prefix}-web" }
}

# Regras como recursos separados (e não blocos dentro do SG): cada regra tem ciclo
# de vida próprio, ganha descrição e o diff do plan fica fácil de ler.
resource "aws_vpc_security_group_ingress_rule" "http" {
  for_each = toset(var.allowed_http_cidrs)

  security_group_id = aws_security_group.web.id
  description       = "HTTP de ${each.value}"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = each.value
}

# SSH só existe se alguém pedir (ssh_cidr != null). Melhor ainda: SSM Session Manager.
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  count = var.ssh_cidr == null ? 0 : 1

  security_group_id = aws_security_group.web.id
  description       = "SSH administrativo"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.ssh_cidr
}

# Saída mínima: baixar pacotes (80/443) e resolver nomes (53). Nada de "tudo liberado".
resource "aws_vpc_security_group_egress_rule" "out" {
  for_each = {
    http  = { proto = "tcp", port = 80 }
    https = { proto = "tcp", port = 443 }
    dns   = { proto = "udp", port = 53 }
  }

  security_group_id = aws_security_group.web.id
  description       = "Saida ${each.key}"
  ip_protocol       = each.value.proto
  from_port         = each.value.port
  to_port           = each.value.port
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_instance" "web" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true # demo; em produção ficaria na privada, atrás de um ALB
  ebs_optimized               = true

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    project     = var.project
    environment = var.environment
  })
  # O user data só roda no primeiro boot: se o script mudar, a instância é recriada.
  user_data_replace_on_change = true

  # IMDSv2 obrigatório: impede roubo de credenciais via SSRF no endpoint de metadados.
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  tags = { Name = "${var.name_prefix}-web" }
}
