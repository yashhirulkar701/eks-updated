data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "shoora" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "shoora" {
  count = var.versioning_enabled ? 1 : 0

  bucket = aws_s3_bucket.shoora.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "shoora" {
  count = var.ownership_controls ? 1 : 0

  bucket = aws_s3_bucket.shoora.id

  rule {
    object_ownership = var.object_ownership
  }
}

resource "aws_s3_bucket_policy" "shoora" {
  count = var.bucket_policy ? 1 : 0

  bucket = aws_s3_bucket.shoora.id
  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {

        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${var.elb_account_id}:root"
        },
        Action   = ["s3:PutObject"]
        Resource = "arn:aws:s3:::${aws_s3_bucket.shoora.bucket}/alblogs/*"
      }
    ]
  })
}

resource "aws_s3_bucket_logging" "shoora" {
  count = var.bucket_logging ? 1 : 0

  bucket        = aws_s3_bucket.shoora.id
  target_bucket = aws_s3_bucket.shoora.id
  target_prefix = "s3logs/${aws_s3_bucket.shoora.bucket}"
  depends_on    = [aws_s3_bucket.shoora]
}

resource "aws_s3_bucket_acl" "shoora" {
  count = length(var.bucket_acls)

  acl        = var.bucket_acls[count.index]
  bucket     = aws_s3_bucket.shoora.id
  depends_on = [aws_s3_bucket_ownership_controls.shoora[0]]
}

resource "aws_s3_bucket_public_access_block" "shoora" {
  count = var.bucket_public_access_block ? 1 : 0

  bucket                  = aws_s3_bucket.shoora.id
  block_public_acls       = false
  block_public_policy     = true
  ignore_public_acls      = false
  restrict_public_buckets = true
}

resource "aws_s3_bucket_website_configuration" "shoora" {
  count = var.bucket_website_configuration ? 1 : 0

  bucket = aws_s3_bucket.shoora.bucket

  index_document {
    suffix = "index.json"
  }

  error_document {
    key = "error.json"
  }
}

resource "aws_s3_bucket_cors_configuration" "shoora" {
  count = var.bucket_cors_configuration ? 1 : 0

  bucket = aws_s3_bucket.shoora.bucket

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 86400
  }
}
