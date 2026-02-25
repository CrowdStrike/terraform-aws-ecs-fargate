module "falcon_ecs_task" {
  source = "../.."

  app_name       = var.app_name
  app_image      = var.app_image
  app_entrypoint = ["/app/entrypoint.sh"]
  app_command    = ["--config", "/etc/app/config.yaml"]

  app_environment = [
    {
      name  = "ENVIRONMENT"
      value = var.environment
    },
    {
      name  = "LOG_LEVEL"
      value = "info"
    },
    {
      name  = "APP_PORT"
      value = tostring(var.app_port)
    }
  ]

  app_secrets = [
    {
      name      = "DATABASE_PASSWORD"
      valueFrom = var.db_password_secret_arn
    },
    {
      name      = "API_KEY"
      valueFrom = var.api_key_secret_arn
    }
  ]

  app_port_mappings = [
    {
      containerPort = var.app_port
      protocol      = "tcp"
    },
    {
      containerPort = var.metrics_port
      protocol      = "tcp"
    }
  ]

  app_health_check = {
    command     = ["CMD-SHELL", "curl -f http://localhost:${var.app_port}/health || exit 1"]
    interval    = 30
    timeout     = 5
    retries     = 3
    startPeriod = 60
  }

  app_mount_points = [
    {
      sourceVolume  = "app-data"
      containerPath = "/mnt/data"
      readOnly      = false
    }
  ]

  falcon_image           = var.falcon_image
  falcon_cid             = var.falcon_cid
  falcon_additional_opts = "--tags=env:${var.environment},app:${var.app_name}"

  task_cpu    = var.task_cpu
  task_memory = var.task_memory

  create_execution_role = false
  execution_role_arn    = var.execution_role_arn
  task_role_arn         = var.task_role_arn

  log_retention_days = 30

  volumes = [
    {
      name = "app-data"
      efs_volume_configuration = {
        file_system_id = var.efs_file_system_id
        root_directory = "/data"
      }
    }
  ]

  sidecar_containers = [
    {
      name      = "log-router"
      image     = "fluent/fluent-bit:2.0"
      essential = false
      environment = [
        {
          name  = "FLB_LOG_LEVEL"
          value = "info"
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "app-data"
          containerPath = "/fluent-bit/logs"
          readOnly      = true
        }
      ]
    }
  ]

  tags = var.tags
}
