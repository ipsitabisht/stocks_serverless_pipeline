resource "aws_lambda_function" "ingest_lambda" {
  function_name = "ingest_lambda"
  role          = aws_iam_role.ingest_lambda_role.arn
  handler       = "stock_mover_handler.lambda_handler"
  runtime       = "python3.12"

  filename         = data.archive_file.ingest_lambda_zip.output_path
  source_code_hash = data.archive_file.ingest_lambda_zip.output_base64sha256
  timeout = 300

  environment {
    variables = {
      TABLE_NAME      = aws_dynamodb_table.stocker_movers.name
      WATCHLIST       = "AAPL,MSFT,GOOGL,AMZN,TSLA,NVDA"
      MASSIVE_API_KEY = var.massive_api_key
    }
  }
}

resource "aws_lambda_function" "ingest_week_lambda" {
  function_name = "ingest_week_lambda"
  role          = aws_iam_role.ingest_lambda_role.arn
  handler       = "stock_mover_weekly_handler.lambda_handler"
  runtime       = "python3.12"

  filename         = data.archive_file.ingest_lambda_zip.output_path
  source_code_hash = data.archive_file.ingest_lambda_zip.output_base64sha256

  timeout = 900

  environment {
    variables = {
      TABLE_NAME      = aws_dynamodb_table.stocker_movers.name
      WATCHLIST       = "AAPL,MSFT,GOOGL,AMZN,TSLA,NVDA"
      MASSIVE_API_KEY = var.massive_api_key
    }
  }
}

resource "aws_lambda_function" "retrieve_week_lambda" {
  function_name = "retrieve_week_lambda"
  role          = aws_iam_role.retrieve_lambda_role.arn
  handler       = "retrieve_mover_handler.lambda_handler"
  runtime       = "python3.12"

  filename         = data.archive_file.ingest_lambda_zip.output_path
  source_code_hash = data.archive_file.ingest_lambda_zip.output_base64sha256
  timeout = 300

  environment {
    variables = {
      TABLE_NAME      = aws_dynamodb_table.stocker_movers.name
    }
  }
}
