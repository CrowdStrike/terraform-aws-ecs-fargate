variable "app_name" {
  type        = string
  description = "Name of the application"
  default     = "demo-app"
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

variable "app_port" {
  type        = number
  description = "Application port"
  default     = 8080
}

variable "task_cpu" {
  type        = string
  description = "Task CPU units"
  default     = "512"
}

variable "task_memory" {
  type        = string
  description = "Task memory in MB"
  default     = "1024"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default = {
    Environment = "demo"
    ManagedBy   = "terraform"
  }
}
