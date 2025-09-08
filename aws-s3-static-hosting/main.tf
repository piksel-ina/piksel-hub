data "aws_caller_identity" "current" {}

locals {
  hosting_bucket_name = "docs-${lower(var.project)}-${lower(var.environment)}"
  docs_domain         = "${var.docs_domain_name}"
}

# --- ACM Certificate for CloudFront (must be in us-east-1) ---
resource "aws_acm_certificate" "docs" {
  provider          = aws.us_east_1
  domain_name       = local.docs_domain
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${local.docs_domain}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.default_tags, {
    Name = "Documentation SSL Certificate"
  })
}

# --- Route53 records for certificate validation ---
resource "aws_route53_record" "docs_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.docs.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# --- Certificate validation ---
resource "aws_acm_certificate_validation" "docs" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.docs.arn
  validation_record_fqdns = [for record in aws_route53_record.docs_cert_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}

# --- S3 bucket for documentation hosting ---
resource "aws_s3_bucket" "docs" {
  bucket = local.hosting_bucket_name
  
  tags = merge(var.default_tags, {
    Name = "Documentation Bucket"
  })
}

# --- S3 bucket versioning ---
resource "aws_s3_bucket_versioning" "docs" {
  bucket = aws_s3_bucket.docs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# --- S3 bucket public access block ---
resource "aws_s3_bucket_public_access_block" "docs" {
  bucket = aws_s3_bucket.docs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- S3 bucket server-side encryption ---
resource "aws_s3_bucket_server_side_encryption_configuration" "docs" {
  bucket = aws_s3_bucket.docs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --- S3 bucket lifecycle configuration ---
resource "aws_s3_bucket_lifecycle_configuration" "docs" {
  bucket = aws_s3_bucket.docs.id

  rule {
    id     = "delete_old_versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

# --- CloudFront Origin Access Control ---
resource "aws_cloudfront_origin_access_control" "docs" {
  name                              = "${local.hosting_bucket_name}-oac"
  description                       = "OAC for docs S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# --- S3 bucket policy to allow CloudFront access ---
resource "aws_s3_bucket_policy" "docs" {
  bucket = aws_s3_bucket.docs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.docs.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.docs.arn
          }
        }
      }
    ]
  })
}

# --- CloudFront distribution for documentation ---
resource "aws_cloudfront_distribution" "docs" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "Documentation distribution for ${local.docs_domain}"
  price_class         = var.cloudfront_price_class
  
  aliases = [local.docs_domain]

  # --- Origin configuration ---
  origin {
    domain_name              = aws_s3_bucket.docs.bucket_regional_domain_name
    origin_id                = "S3-${local.hosting_bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.docs.id

    # Custom headers (optional)
    custom_header {
      name  = "X-Forwarded-Host"
      value = local.docs_domain
    }
  }

  # --- Default cache behavior for HTML files ---
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${local.hosting_bucket_name}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    # Use managed cache policy for better performance
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" 
    
    # Response headers policy for security
    response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    # Short cache for HTML files to ensure updates are visible
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 86400

  }

  # --- Cache behavior for static assets (CSS, JS, images) ---
  ordered_cache_behavior {
    path_pattern           = "/assets/*"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "S3-${local.hosting_bucket_name}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    # Use managed cache policy for static assets
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]
      cookies {
        forward = "none"
      }
    }

    # Long cache for static assets
    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
  }

  # --- Cache behavior for API documentation ---
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "S3-${local.hosting_bucket_name}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"  # CachingDisabled for API docs

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    # Medium cache for API docs
    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # --- Custom error responses for SPA routing ---
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  # --- Geographic restrictions ---
  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  # --- SSL/TLS configuration ---
  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate_validation.docs.certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
    cloudfront_default_certificate = false
  }

  tags = merge(var.default_tags, {
    Name = "Documentation CloudFront"
  })

  depends_on = [aws_acm_certificate_validation.docs]
}

# --- Route53 A record for docs subdomain ---
resource "aws_route53_record" "docs" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.docs_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.docs.domain_name
    zone_id                = aws_cloudfront_distribution.docs.hosted_zone_id
    evaluate_target_health = false
  }
}

# --- Route53 AAAA record for IPv6 ---
resource "aws_route53_record" "docs_ipv6" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.docs_domain
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.docs.domain_name
    zone_id                = aws_cloudfront_distribution.docs.hosted_zone_id
    evaluate_target_health = false
  }
}

# --- Optional: WAF Web ACL for additional security ---
resource "aws_wafv2_web_acl" "docs" {
  count = var.enable_waf ? 1 : 0

  name  = "docs-${var.project}-${var.environment}-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Rate limiting rule
  rule {
    name     = "RateLimitRule"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "RateLimitRule"
      sampled_requests_enabled    = true
    }
  }

  # AWS Managed Rules
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "CommonRuleSetMetric"
      sampled_requests_enabled    = true
    }
  }

  tags = merge(var.default_tags, {
    Name = "Documentation WAF"
  })

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                 = "DocsWAF"
    sampled_requests_enabled    = true
  }
}
