resource "aws_dynamodb_table" "stocker_movers" {
  name           = "Stocker_Movers"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "date"

  attribute {
    name = "date"
    type = "S"
  }
}