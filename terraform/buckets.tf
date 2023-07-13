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