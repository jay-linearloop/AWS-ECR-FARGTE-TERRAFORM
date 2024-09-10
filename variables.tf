variable "vpc_id" {
  description = "The VPC ID to use for the ECS service"
  type        = string
}

variable "subnets" {
  description = "The subnets to use for the ECS service"
  type        = list(string)
}

variable "container_image" {
  description = "The container image to use for the ECS service"
  type        = string
}
