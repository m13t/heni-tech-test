terraform {
  // Minimum version for Terraform CLI
  required_version = ">= 1.1"

  // Configuration for terraform providers
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.10.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "2.2.0"
    }
  }

  // Backend configuration for remote state.
  // `bucket` will need updating if running in a different account
  backend "s3" {
    bucket = "heni-test-tf-state"
    key    = "demo.tfstate"
    region = "eu-west-2"
  }
}
