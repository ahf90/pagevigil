module "pagevigil" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "1.7.1"

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

resource "null_resource" "copy_image" {
  triggers = {
    version = var.latest_image_tag
  }
  provisioner "local-exec" {
    command     = <<EOT
      docker pull --platform linux/x86_64 public.ecr.aws/m5e2w3a9/pagevigil:${var.latest_image_tag}
      aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com
      docker tag public.ecr.aws/m5e2w3a9/pagevigil:${var.latest_image_tag} ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-2.amazonaws.com/pagevigil:${var.latest_image_tag}
      docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-2.amazonaws.com/pagevigil:${var.latest_image_tag}
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = [module.pagevigil]
}