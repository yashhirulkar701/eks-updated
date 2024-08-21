output "ecr_repository_name" {
  value = aws_ecr_repository.infra.registry_id
}

output "ecr_repository_arn" {
  value = aws_ecr_repository.infra.arn
}
