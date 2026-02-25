module "falcon_ecs_task" {
  source = "../.."

  app_name  = var.app_name
  app_image = var.app_image

  falcon_image = var.falcon_image
  falcon_cid   = var.falcon_cid

  app_port_mappings = [
    {
      containerPort = var.app_port
      protocol      = "tcp"
    }
  ]

  task_cpu    = var.task_cpu
  task_memory = var.task_memory

  tags = var.tags
}
