variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "massive_api_key" {
  type      = string
  sensitive = true
}

variable "bucket_name_primary" {
  type      = string
  description = "Name of Bucket"
  defualt = "s3site"
}