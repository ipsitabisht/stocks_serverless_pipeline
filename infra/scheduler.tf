resource "aws_iam_role" "scheduler_invoke_lambda_role" {
  name = "scheduler_invoke_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "scheduler_invoke_lambda_policy" {
  name = "scheduler_invoke_lambda_policy"
  role = aws_iam_role.scheduler_invoke_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.ingest_lambda.arn
      }
    ]
  })
}

resource "aws_scheduler_schedule" "daily_stock_ingest" {
  name        = "daily-stock-ingest"
  description = "Runs stock mover ingestion Lambda after market close"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "rate(15 minutes)"
  schedule_expression_timezone = "America/New_York"

  target {
    arn      = aws_lambda_function.ingest_lambda.arn
    role_arn = aws_iam_role.scheduler_invoke_lambda_role.arn

    input = jsonencode({})
  }
}

resource "aws_scheduler_schedule" "test_run_now" {
  name = "test-run-now"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "at(2026-03-24T14:25:00)"
  schedule_expression_timezone = "America/Los_Angeles"

  target {
    arn      = aws_lambda_function.ingest_lambda.arn
    role_arn = aws_iam_role.scheduler_invoke_lambda_role.arn
    input    = jsonencode({})
  }
}