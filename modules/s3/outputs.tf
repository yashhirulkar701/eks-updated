output "s3_bucket_name" {
  value = aws_s3_bucket.shoora.id
}

output "s3_bucket_domain_name" {
  value = aws_s3_bucket.shoora.bucket_domain_name
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.shoora.arn
}

output "s3_bucket_website_endpoint" {
  value = var.bucket_website_configuration ? aws_s3_bucket_website_configuration.shoora[0].website_endpoint : null
}
