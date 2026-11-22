locals {
  # for_each com chave = nome da AZ. Com count, se a lista mudasse de ordem o índice
  # mudaria e o Terraform destruiria e recriaria sub-redes sem necessidade.
  az_index = { for i, az in var.azs : az => i }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # as instâncias recebem nome DNS interno

  tags = { Name = "${var.name_prefix}-vpc" }
}

# O security group "default" de toda VPC nasce liberando tráfego interno.
# Gerenciá-lo SEM regras o deixa fechado: ninguém usa o default por engano.
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name_prefix}-default-fechado" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name_prefix}-igw" }
}

# Públicas: 10.10.0.0/24, 10.10.1.0/24 (cidrsubnet soma 8 bits à máscara /16 -> /24).
resource "aws_subnet" "public" {
  for_each = local.az_index

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, each.value)

  # IP público só para quem pedir na própria instância (associate_public_ip_address).
  map_public_ip_on_launch = false

  tags = { Name = "${var.name_prefix}-public-${each.key}", Tier = "public" }
}

# Privadas: 10.10.10.0/24, 10.10.11.0/24 (offset 10 deixa espaço para mais públicas).
resource "aws_subnet" "private" {
  for_each = local.az_index

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, each.value + 10)

  tags = { Name = "${var.name_prefix}-private-${each.key}", Tier = "private" }
}

# Tabela pública: rota padrão (0.0.0.0/0) para a internet pelo IGW.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = { Name = "${var.name_prefix}-rt-public" }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Tabela privada SEM rota para a internet, de propósito.
# Dar saída exigiria um NAT Gateway (~US$ 32/mês + tráfego): fica como próximo passo.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name_prefix}-rt-private" }
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
