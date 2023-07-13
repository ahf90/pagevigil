module "pagevigil" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "1.6.0"

  repository_name                   = "pagevigil"
  repository_read_write_access_arns = []
  repository_read_access_arns       = []
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus   = "any",
          countType   = "imageCountMoreThan",
          countNumber = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
  repository_image_tag_mutability = "IMMUTABLE"
  repository_image_scan_on_push   = true

  tags = local.tags
}