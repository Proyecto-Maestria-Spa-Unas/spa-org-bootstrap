output "ecr_backend_api_url" {
  description = "URL del repositorio ECR de la API"
  value       = aws_ecr_repository.backend_api.repository_url
}
