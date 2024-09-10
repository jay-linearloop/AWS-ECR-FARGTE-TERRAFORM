# Provider
provider "aws" {
  region = "us-east-1"  # Change this to your desired region
}

# Data source to fetch existing VPC
data "aws_vpc" "selected" {
  id = var.vpc_id  # Use the VPC ID from variables
}

# Data source to fetch subnets from the existing VPC
data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-bb-tf"
}

# Security Group for ECS service
resource "aws_security_group" "ecs_sg" {
  vpc_id = data.aws_vpc.selected.id
  name   = "ecs_sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1400
    to_port     = 1400
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6379
    to_port     = 6379
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

# Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = "ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets            = data.aws_subnets.selected.ids
}

# Target Group for ECS
resource "aws_lb_target_group" "ecs_target_group" {
  name        = "ecs-tg"
  port        = 1400
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.selected.id
  target_type = "ip"

  health_check {
    path                = "/ping"  # Adjust based on your application health check path
    interval            = 60  # Check every 30 seconds
    timeout             = 30   # Timeout after 5 seconds
    healthy_threshold   = 2   # Consider healthy after 2 successful checks
    unhealthy_threshold = 2   # Consider unhealthy after 2 failed checks
  }
}

# Listener for Load Balancer
resource "aws_lb_listener" "ecs_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"  # Listener uses HTTP protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
  }
}

# Task Definition for ECS Service
resource "aws_ecs_task_definition" "ecs_task" {
  family                   = "ecs-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"   # 1 vCPU
  memory                   = "3072"   # 3 GB Memory

  container_definitions = jsonencode([
    {
      name  = "bb-api"
      image = var.container_image
      portMappings = [
        {
          containerPort = 1400
          hostPort      = 1400
          protocol      = "tcp"
        }
      ]
    }
  ])
}

# ECS Service with Fargate
resource "aws_ecs_service" "ecs_service" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.selected.ids
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    container_name   = "bb-api"
    container_port   = 1400
  }

  depends_on = [aws_lb_listener.ecs_listener]  # Ensure listener is created before ECS service
}
