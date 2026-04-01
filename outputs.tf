output "alb_dns" {
  description = "DNS name of the application load balancer"
  value       = aws_lb.cluster.dns_name
}
