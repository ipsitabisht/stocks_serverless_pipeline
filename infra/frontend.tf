resource "aws_s3_bucket" "stock_mover_site" {
  bucket = var.stock_mover_bucket_name
}

resource "aws_s3_bucket_public_access_block" "stock_mover_site" {
  bucket = aws_s3_bucket.stock_mover_site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "stock_mover_site" {
  bucket = aws_s3_bucket.stock_mover_site.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_cloudfront_origin_access_control" "stock_mover_site_oac" {
  name                              = "stock-mover-site-oac"
  description                       = "OAC for React Stock Mover bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "stock_mover_cdn" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.stock_mover_site.bucket_regional_domain_name
    origin_id                = "stock-mover-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.stock_mover_site_oac.id
  }

  default_cache_behavior {
    target_origin_id       = "stock-mover-s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  # SPA routing support
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

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

data "aws_iam_policy_document" "stock_mover_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontReadAccess"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.stock_mover_site.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.stock_mover_cdn.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "stock_mover_site" {
  bucket = aws_s3_bucket.stock_mover_site.id
  policy = data.aws_iam_policy_document.stock_mover_bucket_policy.json
}

output "cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.stock_mover_cdn.domain_name}"
}