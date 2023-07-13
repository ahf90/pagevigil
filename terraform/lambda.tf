module "screenshot_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "5.0.0"

  function_name  = "pagevigil-${local.organization}"
  description    = "Screenshots pages and stores the screenshots in S3"
  create_package = false
  image_uri      = "public.ecr.aws/m5e2w3a9/pagevigil:latest"
  package_type   = "Image"
  architectures  = ["arm64"]

  attach_policy = true
  policy        = aws_iam_policy.pagevigil_lambda.arn

  cloudwatch_logs_retention_in_days = 7

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
  name                = "PageVigilLambdaCron"
  description         = "Minutely event to trigger the PageVigil Lambda"
  schedule_expression = "rate(1 minute)"
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