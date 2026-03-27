module "falcon_ecs_task" {
  source = "github.com/crowdstrike/terraform-aws-ecs-fargate"

  app_name  = "my-application"
  app_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:v1.0.0"

  falcon_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/falcon-sensor:latest"
  falcon_cid   = "YOUR-CID-HERE-12345678901234567890123456789012-AB"

  app_port_mappings = [
    {
      containerPort = 8080
      protocol      = "tcp"
    }
  ]

  task_cpu    = "512"
  task_memory = "1024"

  tags = {
    Environment = "production"
    Application = "my-app"
    ManagedBy   = "terraform"
  }
}

# Create ECS service using the task definition
resource "aws_ecs_service" "app" {
  name            = "my-application"
  cluster         = aws_ecs_cluster.main.id
  task_definition = module.falcon_ecs_task.task_definition_arn
  desired_count   = 2

  # Use outputs from the module
  enable_execute_command = module.falcon_ecs_task.enable_execute_command
  platform_version       = module.falcon_ecs_task.platform_version

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = module.falcon_ecs_task.container_name
    container_port   = 8080
  }
}
