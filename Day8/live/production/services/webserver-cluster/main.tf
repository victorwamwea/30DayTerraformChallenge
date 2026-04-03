provider "aws" {
  region = "eu-north-1"
}

terraform {
  backend "s3" {
    bucket         = "wamwea_bucket"
    key            = "day8/production/services/webserver-cluster/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "wamwea_terraform_locks"
    encrypt        = true
  }
}

module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  cluster_name  = "webservers-production"
  instance_type = "t3.micro"
  min_size      = 2
  max_size      = 4
}

output "alb_dns_name" {
  value       = module.webserver_cluster.alb_dns_name
  description = "The DNS name of the production load balancer"
}