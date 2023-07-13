locals {
  organization = "pagevigil"
  tags = {
    owner   = "pagevigil"
    project = "pagevigil"
  }
  config = base64encode(file("../config.yml"))
}