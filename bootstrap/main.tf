# Bootstrap: cria o bucket que vai guardar o state do projeto principal.
# Problema do ovo e da galinha: o backend S3 precisa do bucket ANTES do "terraform init",
# então este diretório usa state LOCAL e roda uma única vez.

provider "aws" {
  region = var.aws_region

  # No LocalStack qualquer credencial serve; na AWS real (use_localstack = false)
  # as credenciais vêm do ambiente (aws configure / variáveis AWS_*).
  access_key                  = var.use_localstack ? "test" : null
  secret_key                  = var.use_localstack ? "test" : null
  skip_credentials_validation = var.use_localstack
  skip_metadata_api_check     = var.use_localstack
  skip_requesting_account_id  = var.use_localstack
  s3_use_path_style           = var.use_localstack

  dynamic "endpoints" {
    for_each = var.use_localstack ? [1] : []
    content {
      s3  = var.localstack_endpoint
      sts = var.localstack_endpoint
    }
  }

  default_tags {
    tags = {
      Project   = "terraform-aws-vpc-ec2"
      ManagedBy = "terraform"
      Purpose   = "terraform-state"
    }
  }
}

resource "aws_s3_bucket" "state" {
  bucket        = var.state_bucket_name
  force_destroy = var.force_destroy
}

# Versionamento: se um apply corromper o state, dá para voltar à versão anterior.
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Criptografia em repouso: o state pode conter dados sensíveis (IPs, senhas geradas, IDs).
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# State nunca pode ficar público.
resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versões antigas do state expiram em 90 dias (o custo não cresce para sempre).
resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    id     = "expirar-versoes-antigas"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
