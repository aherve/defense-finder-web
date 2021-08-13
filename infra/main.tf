terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"

  backend "remote" {
    organization = "mdmparis"
    workspaces {
      name = "defense-finder-web"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "eu-west-3"
}

resource "aws_s3_bucket" "proteins_bucket" {
  bucket = "tf-proteins"
  acl    = "private"
  tags = {
    Name        = "tf-proteins"
    Environment = "Prod"
  }
}
