locals {
  prefix      = "${var.prefix}-${var.environment}"
  bucket_name = "${local.prefix}-dashboard"
  origin_id   = "${local.prefix}-s3-origin"
}

# ─────────────────────────────────────────
# S3 Bucket — stores dashboard static files
# Block all public access; CloudFront uses OAC
# ─────────────────────────────────────────
resource "aws_s3_bucket" "dashboard" {
  bucket        = local.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "dashboard" {
  bucket                  = aws_s3_bucket.dashboard.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "dashboard" {
  bucket = aws_s3_bucket.dashboard.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ─────────────────────────────────────────
# Origin Access Control (OAC)
# Allows CloudFront to read from private S3
# ─────────────────────────────────────────
resource "aws_cloudfront_origin_access_control" "dashboard" {
  name                              = "${local.prefix}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ─────────────────────────────────────────
# S3 Bucket Policy — allow only CloudFront OAC
# ─────────────────────────────────────────
resource "aws_s3_bucket_policy" "dashboard" {
  bucket = aws_s3_bucket.dashboard.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudFrontOAC"
      Effect = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action   = "s3:GetObject"
      Resource = "${aws_s3_bucket.dashboard.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.dashboard.arn
        }
      }
    }]
  })

  depends_on = [aws_cloudfront_distribution.dashboard]
}

# ─────────────────────────────────────────
# CloudFront Distribution
# Serves dashboard over HTTPS with auto domain
# ─────────────────────────────────────────
resource "aws_cloudfront_distribution" "dashboard" {
  enabled             = true
  default_root_object = "index.html"
  comment             = "ChatOps Operations Dashboard - ${var.environment}"

  origin {
    domain_name              = aws_s3_bucket.dashboard.bucket_regional_domain_name
    origin_id                = local.origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.dashboard.id
  }

  default_cache_behavior {
    target_origin_id       = local.origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# ─────────────────────────────────────────
# Upload dashboard index.html to S3
# ─────────────────────────────────────────
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.dashboard.id
  key          = "index.html"
  source       = "${path.module}/site/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/site/index.html")
}
