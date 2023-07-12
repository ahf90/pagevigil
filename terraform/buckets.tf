locals {
  organization = "pagevigil"
  tags = {
    owner   = "pagevigil"
    project = "pagevigil"
  }
  config = base64encode(file("../config.yml"))
}

module "storage_bucket" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "3.14.0"
  bucket        = "pagevigil-${local.organization}" # Bucket name
  force_destroy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  tags = local.tags
}

module "screenshot_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "5.0.0"

  function_name = "pagevigil-${local.organization}"
  description   = "Screenshots pages and stores the screenshots in S3"
  handler       = "main.handler"
  runtime       = "python3.10"
  create_current_version_allowed_triggers = false

  attach_policy = true
  policy        = aws_iam_policy.pagevigil_lambda.arn

  cloudwatch_logs_retention_in_days = 7

  source_path = [
    "../app/main.py",
    {
      pip_requirements = "../app/requirements.txt"
      prefix_in_zip    = ""
    }
  ]

  allowed_triggers = {
    Cron = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.cron.arn
    }
  }

  environment_variables = {
    CONFIG    = local.config,
    BUCKET_ID = module.storage_bucket.s3_bucket_id
  }

  tags = local.tags
}

resource "aws_cloudwatch_event_rule" "cron" {
  name          = "PageVigilLambdaCron"
  description   = "Minutely event to trigger the PageVigil Lambda"
  schedule_expression =  "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "cron_lambda_function" {
  rule = aws_cloudwatch_event_rule.cron.name
  arn  = module.screenshot_lambda.lambda_function_arn
}

data "aws_iam_policy_document" "pagevigil_lambda" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [module.storage_bucket.s3_bucket_arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:*Object"
    ]
    resources = ["${module.storage_bucket.s3_bucket_arn}/*"]
  }
}

resource "aws_iam_policy" "pagevigil_lambda" {
  name   = "pagevigil-lambda-policy"
  policy = data.aws_iam_policy_document.pagevigil_lambda.json
}