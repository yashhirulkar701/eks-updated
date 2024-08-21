output "route_53_fqdn" {
  value = {
    for k, v in aws_route53_record.shoora : k => v.fqdn
  }
}
