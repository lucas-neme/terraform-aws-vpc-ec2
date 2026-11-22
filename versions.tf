terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # aceita 6.x, não pula sozinho para a 7 (que pode quebrar)
    }
  }
}
