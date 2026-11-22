# Ubuntu 24.04 oficial da Canonical. Só é consultada quando ami_id = null (AWS real):
# o LocalStack tem uma lista própria de AMIs simuladas e usa a fixa do tfvars.
data "aws_ami" "ubuntu" {
  count = var.ami_id == null ? 1 : 0

  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

module "network" {
  source = "./modules/network"

  name_prefix = local.name_prefix
  vpc_cidr    = var.vpc_cidr
  azs         = var.azs
}

module "compute" {
  source = "./modules/compute"

  name_prefix        = local.name_prefix
  project            = var.project
  environment        = var.environment
  vpc_id             = module.network.vpc_id
  subnet_id          = module.network.public_subnet_ids[0] # primeira AZ
  ami_id             = local.ami_id
  instance_type      = var.instance_type
  allowed_http_cidrs = var.allowed_http_cidrs
  ssh_cidr           = var.ssh_cidr
}
