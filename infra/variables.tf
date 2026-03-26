variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "massive_api_key" {
  type      = string
  sensitive = true
}

variable "stock_mover_bucket_name" {
  type      = string
}