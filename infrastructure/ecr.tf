module "public_ecr" {
  source = "terraform-aws-modules/ecr/aws"
  version = "1.6.0"

  repository_name = "pagevigil"
  repository_type = "public"

  repository_read_write_access_arns = []

  public_repository_catalog_data = {
    description       = "PageVigil docker images"
    about_text        = "Please see https://github.com/ahf90/pagevigil/blob/main/README.md"
    usage_text        = "Please see https://github.com/ahf90/pagevigil/blob/main/LICENSE"
    operating_systems = ["Linux"]
    architectures     = ["arm64"]
  }

  tags = local.tags
}