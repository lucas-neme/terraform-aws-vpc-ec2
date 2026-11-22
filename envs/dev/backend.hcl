# Backend S3 do DEV apontando para o LocalStack (ATIVO no lab).
bucket       = "tfstate-getrak-lab"           # criado por bootstrap/
key          = "vpc-ec2/dev/terraform.tfstate" # um arquivo de state por ambiente
region       = "us-east-1"
encrypt      = true
use_lockfile = true # lock nativo no S3 (Terraform 1.10+): impede dois applies ao mesmo tempo

# Só para o LocalStack:
access_key                  = "test"
secret_key                  = "test"
skip_credentials_validation = true
skip_metadata_api_check     = true
skip_requesting_account_id  = true
use_path_style              = true
endpoints = {
  s3 = "http://localhost:4566"
}
