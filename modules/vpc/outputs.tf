## Outputs

output "vpc_id" {
  value = aws_vpc.shoora.id
}

output "subnet_id" {
  value = aws_subnet.shoora.*.id
}

output "private_subnet_id" {
  value = var.private_subnet_enabled ? aws_subnet.shoora_private.*.id : null
}

output "default_route_table_id" {
  value = aws_default_route_table.shoora.default_route_table_id
}

output "private_route_table_id" {
  value = var.private_subnet_enabled ? aws_route_table.shoora_private[0].id : null
}
