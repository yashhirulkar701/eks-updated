resource "aws_secretsmanager_secret" "infra" {
  name = var.secret_manager_name

  tags = var.tags
}
