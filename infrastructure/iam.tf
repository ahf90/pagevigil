resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
  tags            = local.tags
}

resource "aws_iam_role" "github_actions" {
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
  description          = "Role assumed by the GitHub OIDC provider."
  max_session_duration = 3600
  name                 = "GitHubActionsRole"
  tags                 = local.tags
}

resource "aws_iam_policy" "sts_assume" {
  name   = "GitHubActionsStsAssumePolicy"
  policy = data.aws_iam_policy_document.sts_assume.json
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "sts_assume" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.sts_assume.arn
}

data "aws_iam_policy" "ecr_full" {
  name = "AmazonEC2ContainerRegistryFullAccess"
}

data "aws_iam_policy" "ecr_public_full" {
  name = "AmazonElasticContainerRegistryPublicFullAccess"
}

resource "aws_iam_role" "github_actions_ecr" {
  name = "GitHubActionsECR"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          "AWS" : aws_iam_role.github_actions.arn
        }
      }
    ],
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "github_actions_ecr" {
  role       = aws_iam_role.github_actions_ecr.name
  policy_arn = data.aws_iam_policy.ecr_full.arn
}

resource "aws_iam_role_policy_attachment" "github_actions_ecr_public" {
  role       = aws_iam_role.github_actions_ecr.name
  policy_arn = data.aws_iam_policy.ecr_public_full.arn
}