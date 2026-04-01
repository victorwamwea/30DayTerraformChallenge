# Data Sources
data "aws_availability_zones" "available" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Latest Ubuntu 22.04 AMI (Updated from old Focal)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]   # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Allow HTTP inbound to ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for Instances (Best practice)
resource "aws_security_group" "instance_sg" {
  name        = "instance_sg"
  description = "Allow traffic from ALB to instances"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = var.server_port
    to_port         = var.server_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch Template for ASG
resource "aws_launch_template" "cluster" {
  name_prefix   = "cluster-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = base64encode(<<-EOF
#!/bin/bash
set -euxo pipefail

PORT="${var.server_port}"
echo "Hello, World from Terraform Challenge!" > /tmp/index.html

if command -v python3 >/dev/null 2>&1; then
  mkdir -p /opt/web
  cp /tmp/index.html /opt/web/index.html
  nohup python3 -m http.server "$PORT" --directory /opt/web >/var/log/webserver.log 2>&1 &
elif command -v apt-get >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y apache2
  cp /tmp/index.html /var/www/html/index.html
  systemctl enable --now apache2
else
  echo "No supported web server runtime found" >/var/log/user-data-error.log
fi
EOF
  )
}

# Target Group
resource "aws_lb_target_group" "cluster" {
  name     = "cluster-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Application Load Balancer
resource "aws_lb" "cluster" {
  name               = "cluster-alb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb_sg.id]

  enable_deletion_protection = false
}

# HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.cluster.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cluster.arn
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "cluster" {
  vpc_zone_identifier = data.aws_subnets.default.ids
  min_size            = 2
  max_size            = 5
  desired_capacity    = 2

  launch_template {
    id      = aws_launch_template.cluster.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.cluster.arn]
  health_check_type = "ELB"

  tag {
    key                 = "Name"
    value               = "asg-instance"
    propagate_at_launch = true
  }
}

# Standalone EC2 Instance
resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.instance_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "Ubuntu EC2 Server"
  }
}

