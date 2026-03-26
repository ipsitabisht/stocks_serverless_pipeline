resource "aws_s3_bucket_website_configuration" "stock_mover_site" {
  bucket = aws_s3_bucket.stock_mover_site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  routing_rule {
    condition {
      key_prefix_equals = "docs/"
    }
    redirect {
      replace_key_prefix_with = "documents/"
    }
  }
}