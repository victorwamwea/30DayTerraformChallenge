variable "aws_region" {
  type    = string
  default = "us-east-1"
}


variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 80
}


variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}