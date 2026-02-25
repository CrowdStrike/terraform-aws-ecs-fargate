output "task_definition_arn" {
  description = "ARN of the created task definition"
  value       = module.falcon_ecs_task.task_definition_arn
}

output "task_definition_family" {
  description = "Family name of the task definition"
  value       = module.falcon_ecs_task.task_definition_family
}

output "task_definition_revision" {
  description = "Revision number of the task definition"
  value       = module.falcon_ecs_task.task_definition_revision
}

output "execution_role_arn" {
  description = "ARN of the execution role"
  value       = module.falcon_ecs_task.execution_role_arn
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.falcon_ecs_task.log_group_name
}

output "container_name" {
  description = "Name of the application container"
  value       = module.falcon_ecs_task.container_name
}

output "falcon_volume_name" {
  description = "Name of the Falcon sensor volume"
  value       = module.falcon_ecs_task.falcon_volume_name
}
