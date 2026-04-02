terraform {
  backend "s3" {
    bucket         = "***"
    key            = "environments/production/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "***"
    encrypt        = true
  }
}