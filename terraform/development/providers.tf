provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Uncomment for remote state
# terraform {
#   backend "s3" {
#     bucket         = "dify-terraform-state-337257207190"
#     key            = "development/terraform.tfstate"
#     region         = "ap-northeast-1"
#     dynamodb_table = "terraform-lock"
#     encrypt        = true
#   }
# }
