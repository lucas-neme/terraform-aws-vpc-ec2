terraform {
  required_version = ">= 1.10.0" # use_lockfile (lock nativo no S3) exige 1.10+

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
