module "screenshot_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.13.0"

  function_name                           = "pagevigil"
  description                             = "Screenshots pages and stores the screenshots in S3"
  create_package                          = false
  image_uri                               = "${module.pagevigil.repository_url}:${var.latest_image_tag}"
  package_type                            = "Image"
  architectures                           = ["x86_64"]
  create_current_version_allowed_triggers = false
  cloudwatch_logs_retention_in_days       = 7
  timeout                                 = 60

  attach_policy = true
  policy        = aws_iam_policy.pagevigil_lambda.arn

  allowed_triggers = {
    Cron = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.cron.arn
    }
  }

  environment_variables = {
    CONFIG        = local.config,
    BUCKET_ID     = module.storage_bucket.s3_bucket_id
    SNS_TOPIC_ARN = aws_sns_topic.pagevigil_errors.arn
    REGION        = data.aws_region.current.name
  }

  tags       = local.tags
  depends_on = [null_resource.copy_image]
}

resource "aws_cloudwatch_event_rule" "cron" {
  name                = "PageVigilLambdaCron"
  description         = "Minutely event to trigger the PageVigil Lambda"
  schedule_expression = var.frequency != 1 ? "rate(${var.frequency} minutes)" : "rate(${var.frequency} minute)"
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
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:ListTagsForResource",
      "ecr:DescribeImageScanFindings"
    ]
    resources = [module.pagevigil.repository_arn]
  }
}

resource "aws_iam_policy" "pagevigil_lambda" {
  name   = "pagevigil-lambda-policy"
  policy = data.aws_iam_policy_document.pagevigil_lambda.json
}