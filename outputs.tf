output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.app_lb.dns_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.ecs_service.name
}

output "ecs_task_definition" {
  description = "ARN of the ECS Task Definition"
  value       = aws_ecs_task_definition.ecs_task.arn
}
