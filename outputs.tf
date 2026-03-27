output "task_definition_arn" {
  description = "Full ARN of the Task Definition (including revision)"
  value       = aws_ecs_task_definition.task.arn
}

output "task_definition_family" {
  description = "Family of the Task Definition"
  value       = aws_ecs_task_definition.task.family
}

output "task_definition_revision" {
  description = "Revision of the Task Definition"
  value       = aws_ecs_task_definition.task.revision
}

output "execution_role_arn" {
  description = "ARN of the ECS execution role"
  value       = local.execution_role_arn
}

output "execution_role_name" {
  description = "Name of the ECS execution role (if created)"
  value       = var.create_execution_role ? aws_iam_role.execution_role[0].name : null
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = var.enable_logging ? local.log_group_name : null
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = var.enable_logging && var.create_log_group ? aws_cloudwatch_log_group.ecs_log_group[0].arn : null
}

output "falcon_volume_name" {
  description = "Name of the Falcon sensor volume"
  value       = var.falcon_volume_name
}

output "container_name" {
  description = "Name of the application container"
  value       = var.app_name
}

output "enable_execute_command" {
  description = "Whether ECS Exec is enabled (use this value when creating ECS service)"
  value       = var.enable_execute_command
}

output "platform_version" {
  description = "Fargate platform version to use (use this value when creating ECS service)"
  value       = var.platform_version
}
