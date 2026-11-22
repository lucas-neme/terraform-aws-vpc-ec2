locals {
  # Um lugar só para regras de nome: "getrak-lab-dev-vpc", "getrak-lab-prod-web"...
  name_prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Repository  = "terraform-aws-vpc-ec2"
  }

  # Se a AMI veio fixa (LocalStack/tfvars), usa ela; senão, a encontrada pelo data source.
  ami_id = coalesce(var.ami_id, try(data.aws_ami.ubuntu[0].id, null))
}
