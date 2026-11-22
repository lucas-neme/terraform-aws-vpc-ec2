# Backend S3 do PROD no LocalStack: mesmo bucket, CHAVE diferente (states isolados).
bucket       = "tfstate-getrak-lab"
key          = "vpc-ec2/prod/terraform.tfstate"
region       = "us-east-1"
encrypt      = true
use_lockfile = true

access_key                  = "test"
secret_key                  = "test"
skip_credentials_validation = true
skip_metadata_api_check     = true
skip_requesting_account_id  = true
use_path_style              = true
endpoints = {
  s3 = "http://localhost:4566"
}
