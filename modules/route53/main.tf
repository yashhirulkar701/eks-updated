resource "aws_route53_record" "shoora" {
  for_each = var.route53_record

  name    = each.value.name
  records = try(each.value.records, null)
  ttl     = try(each.value.ttl, null)
  type    = each.value.type
  zone_id = each.value.zone_id

  dynamic "alias" {
    for_each = try([each.value.alias], [])

    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = false
    }
  }
}
