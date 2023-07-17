terraform {
  required_providers {
    null = {
      source = "hashicorp/null"
      version = "3.2.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.8.0"
    }
    random = {
      source = "hashicorp/random"
      version = "3.5.1"
    }
  }
}