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

resource "aws_scheduler_schedule" "daily_stock_ingest_9pm_pst" {
  name        = "daily-stock-ingest-9pm-pst"
  description = "Runs stock mover ingestion Lambda at 9pm PST Mon-Fri"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(0 21 ? * MON-FRI *)"
  schedule_expression_timezone = "America/Los_Angeles"

  target {
    arn      = aws_lambda_function.ingest_lambda.arn
    role_arn = aws_iam_role.scheduler_invoke_lambda_role.arn

    input = jsonencode({})
  }
}
