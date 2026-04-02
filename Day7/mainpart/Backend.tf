terraform {
  backend "s3" {
    bucket         = "***"
    key            = "***"
    region         = "eu-north-1"
    dynamodb_table = "***"
    encrypt        = true
  }
}