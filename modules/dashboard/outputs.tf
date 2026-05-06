output "cloudfront_url" {
  description = "Public URL of the operations dashboard"
  value       = "https://${aws_cloudfront_distribution.dashboard.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (needed for cache invalidations)"
  value       = aws_cloudfront_distribution.dashboard.id
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket hosting dashboard files"
  value       = aws_s3_bucket.dashboard.bucket
}
