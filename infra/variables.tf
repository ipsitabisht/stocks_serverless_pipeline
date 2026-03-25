variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "massive_api_key" {
  type      = string
  sensitive = true
}