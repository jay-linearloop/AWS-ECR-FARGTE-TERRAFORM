# terraform.tfvars

container_image = "jack2153/bb-redis-1:latest"  # The container image to use
vpc_id          = "vpc-03ba82035858827cb"    # Your VPC ID
subnets         = ["subnet-01c70f8d323f5baa7", "subnet-0920989a05e1678b0", "subnet-020a2fa3b1fff6bbe", "subnet-0944883f9d0881a32", "subnet-0169d85b1a2a1f1b6", "subnet-022cfd256f9d8f1bb"]  # List of your existing subnets
