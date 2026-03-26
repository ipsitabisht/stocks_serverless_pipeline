variable "github_owner" {
  type = string
}

variable "github_repo" {
  type = string
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [
        "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/main"
      ]
    }
  }
}

resource "aws_iam_role" "github_actions_deploy_role" {
  name               = "github-actions-deploy-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

data "aws_iam_policy_document" "github_actions_deploy_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.stock_mover_site.arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.stock_mover_site.arn}/*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "cloudfront:CreateInvalidation"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_actions_deploy_policy" {
  name   = "github-actions-deploy-policy"
  role   = aws_iam_role.github_actions_deploy_role.id
  policy = data.aws_iam_policy_document.github_actions_deploy_policy.json
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_deploy_role.arn
}