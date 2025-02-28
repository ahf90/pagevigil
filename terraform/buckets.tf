resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
}

module "storage_bucket" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "4.6.0"
  bucket        = "pagevigil-${random_string.random.result}"
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