terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }

  # Estado remoto: se habilita al crear el bucket S3 + tabla DynamoDB de bloqueo (bootstrap manual único).
  # backend "s3" {
  #   bucket         = "spa-unas-tfstate"
  #   key            = "staging/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "spa-unas-tflock"
  #   encrypt        = true
  # }
}
