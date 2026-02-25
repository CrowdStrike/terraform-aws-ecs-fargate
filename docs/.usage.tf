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
