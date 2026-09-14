terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  # Local state is fine solo. Uncomment and fill in once a second contributor
  # or a second machine is involved, so state locking actually matters:
  #
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "serverless-image-pipeline/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region
}
