terraform {
  required_version = "1.8.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.55.0"
    }
  }
}

provider "aws" {
  allowed_account_ids = ["298280266775"]
  region              = "us-east-1"

  default_tags {
    tags = {
      environment     = "dev"
      project         = local.project_name
      terraform_state = "dev/us-east-1"
    }
  }
}
