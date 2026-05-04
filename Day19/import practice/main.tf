terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket         = "wamwea_bucket"
    key            = "day19/import-practice/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "wamwea_terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-north-1"
}

resource "aws_s3_bucket" "state_bucket" {
  bucket = "wamwea_bucket"

  tags = {
    Name        = "wamwea terraform-state"
    ManagedBy   = "terraform"
    Environment = "production"
    Project     = "30day-terraform-challenge"
    Owner       = "sarahcodes"
  }
}

resource "aws_dynamodb_table" "state_locks" {
  name         = "wamwea terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "wamwea terraform-locks"
    ManagedBy   = "terraform"
    Environment = "production"
    Project     = "30day-terraform-challenge"
    Owner       = "sarahcodes"
  }
}