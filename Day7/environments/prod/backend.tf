terraform {
  backend "s3" {
    bucket         = "wamwea_bucket"
    key            = "environments/production/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "wamwea_terraform_locks"
    encrypt        = true
  }
}