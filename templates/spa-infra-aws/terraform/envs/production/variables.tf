variable "aws_region" {
  description = "Región AWS del entorno"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Prefijo de nombres de recursos"
  type        = string
  default     = "spa-unas"
}
