variable "app_name" {
  type        = string
  description = "Name of the application"
  default     = "advanced-demo-app"
}

variable "app_image" {
  type        = string
  description = "Application container image URI"
}

variable "falcon_image" {
  type        = string
  description = "Falcon sensor container image URI"
}

variable "falcon_cid" {
  type        = string
  description = "CrowdStrike Customer ID (CID)"
  sensitive   = true
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "production"
}

variable "app_port" {
  type        = number
  description = "Application port"
  default     = 8080
}

variable "metrics_port" {
  type        = number
  description = "Metrics/monitoring port"
  default     = 9090
}

variable "task_cpu" {
  type        = string
  description = "Task CPU units"
  default     = "1024"
}

variable "task_memory" {
  type        = string
  description = "Task memory in MB"
  default     = "2048"
}

variable "execution_role_arn" {
  type        = string
  description = "ARN of existing ECS execution role"
}

variable "task_role_arn" {
  type        = string
  description = "ARN of existing ECS task role"
}

variable "db_password_secret_arn" {
  type        = string
  description = "ARN of Secrets Manager secret containing database password"
}

variable "api_key_secret_arn" {
  type        = string
  description = "ARN of Secrets Manager secret containing API key"
}

variable "efs_file_system_id" {
  type        = string
  description = "EFS file system ID for application data"
}

variable "datadog_api_key_secret_arn" {
  type        = string
  description = "ARN of SSM Parameter Store or Secrets Manager secret containing the Datadog API key"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default = {
    Environment = "production"
    ManagedBy   = "terraform"
    Application = "advanced-demo"
  }
}
