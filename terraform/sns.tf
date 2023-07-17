resource "aws_sns_topic" "pagevigil_errors" {
  provider     = aws
  name         = "pagevigil-errors"
  display_name = "PageVigil Errors"
}

resource "aws_sns_topic_subscription" "sns-topic" {
  topic_arn = aws_sns_topic.pagevigil_errors.arn
  protocol  = "email"
  endpoint  = var.errors_email
}