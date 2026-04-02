terraform {
  backend "s3" {
    bucket         = "***"
    key            = "environments/staging/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "***"
    encrypt        = true
  }
}