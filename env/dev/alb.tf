# resource "aws_security_group" "shoora_alb" {
#   name   = format("%s-alb-sg", local.grid)
#   vpc_id = module.vpc.vpc_id
# }

# resource "aws_security_group_rule" "ingress_rule_alb" {
#   for_each = var.shoora_alb_ingress_rule

#   type                     = "ingress"
#   description              = each.value.description
#   from_port                = each.value.from_port
#   to_port                  = each.value.to_port
#   protocol                 = each.value.protocol
#   self                     = try(each.value.self, null)
#   cidr_blocks              = try(each.value.cidr_blocks, null)
#   source_security_group_id = try(each.value.source_security_group_id, null)
#   security_group_id        = aws_security_group.shoora_alb.id
# }

# resource "aws_security_group_rule" "egress_rule_alb" {
#   for_each = var.shoora_alb_egress_rule

#   type                     = "egress"
#   from_port                = each.value.from_port
#   to_port                  = each.value.to_port
#   protocol                 = each.value.protocol
#   cidr_blocks              = try(each.value.cidr_blocks, null)
#   source_security_group_id = try(each.value.source_security_group_id, null)
#   security_group_id        = aws_security_group.shoora_alb.id
# }
