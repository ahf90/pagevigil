terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "3.3.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.100.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.9.1"
    }
  }
}

provider "aws" {}