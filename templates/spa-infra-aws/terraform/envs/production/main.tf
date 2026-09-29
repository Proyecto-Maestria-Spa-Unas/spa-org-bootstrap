locals {
  environment = "production"

  tags = {
    Project     = var.project
    Environment = local.environment
    ManagedBy   = "terraform"
    Repository  = "__ORG__/__REPO__"
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = local.tags
  }
}

# Registro de imágenes de la API (inmutable + escaneo al subir)
resource "aws_ecr_repository" "backend_api" {
  name                 = "${var.project}/backend-api-${local.environment}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
  }
}

# Módulos a incorporar por fases (ver docs/ROADMAP_INFRA.md):
# module "vpc" {}   module "eks" {}   module "rds_postgis" {}   module "secrets" {}   module "github_oidc" {}
