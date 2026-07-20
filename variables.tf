# Application Configuration
variable "app_name" {
  type        = string
  description = "Logical name for application / container (used as task family name)"
}

variable "app_image" {
  type        = string
  description = "The full container image path including tag for the application container"
}

variable "app_entrypoint" {
  type        = list(string)
  description = "The entrypoint for the application container (will be wrapped by Falcon). If not specified, Falcon will attempt to wrap the image's default entrypoint. For best results, explicitly specify the entrypoint (e.g., [\"/docker-entrypoint.sh\"] for nginx)."
  default     = null
}

variable "app_command" {
  type        = list(string)
  description = "The command for the application container"
  default     = null
}

variable "app_environment" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "Environment variables for the application container"
  default     = []
}

variable "app_secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  description = "Secrets for the application container (from SSM or Secrets Manager)"
  default     = []
}

variable "app_port_mappings" {
  type = list(object({
    containerPort = number
    hostPort      = optional(number)
    protocol      = optional(string, "tcp")
  }))
  description = "Port mappings for the application container"
  default     = []
}

variable "app_health_check" {
  type = object({
    command     = list(string)
    interval    = optional(number, 30)
    timeout     = optional(number, 5)
    retries     = optional(number, 3)
    startPeriod = optional(number, 0)
  })
  description = "Health check configuration for the application container"
  default     = null
}

variable "app_mount_points" {
  type = list(object({
    sourceVolume  = string
    containerPath = string
    readOnly      = optional(bool, false)
  }))
  description = "Additional mount points for the application container (Falcon volume is added automatically)"
  default     = []
}

variable "app_linux_parameters" {
  type = object({
    capabilities = optional(object({
      add  = optional(list(string), [])
      drop = optional(list(string), [])
    }))
    devices = optional(list(object({
      hostPath      = string
      containerPath = optional(string)
      permissions   = optional(list(string))
    })), [])
    initProcessEnabled = optional(bool)
    maxSwap            = optional(number)
    sharedMemorySize   = optional(number)
    swappiness         = optional(number)
    tmpfs = optional(list(object({
      containerPath = string
      size          = number
      mountOptions  = optional(list(string))
    })), [])
  })
  description = "Linux-specific options for the application container (SYS_PTRACE is added automatically for Falcon)"
  default     = null
}

variable "app_user" {
  type        = string
  description = "User to run the application container as"
  default     = null
}

variable "app_working_directory" {
  type        = string
  description = "Working directory for the application container"
  default     = null
}

variable "app_readonly_root_filesystem" {
  type        = bool
  description = "Whether the application container has a read-only root filesystem"
  default     = false
}

variable "app_privileged" {
  type        = bool
  description = "Whether to give the application container elevated privileges"
  default     = false
}

variable "app_cpu" {
  type        = number
  description = "CPU units to allocate to the application container (not the entire task). If not specified, no container-level CPU limit is set."
  default     = null
}

variable "app_memory" {
  type        = number
  description = "Memory (in MB) to allocate to the application container (hard limit). If not specified, no container-level memory limit is set."
  default     = null
}

variable "app_memory_reservation" {
  type        = number
  description = "Soft memory limit (in MB) for the application container. Container will try to stay below this limit."
  default     = null
}

variable "app_stop_timeout" {
  type        = number
  description = "Time duration (in seconds) to wait before the container is forcefully killed if it doesn't exit normally on its own. ECS default is 30 seconds."
  default     = null
}

variable "app_log_configuration" {
  type = object({
    logDriver = string
    options   = optional(map(string), {})
    secretOptions = optional(list(object({
      name      = string
      valueFrom = string
    })), [])
  })
  description = "Log configuration for the application container. If not specified, defaults to awslogs via enable_logging/log_group_name."
  default     = null
}

# Task Configuration
variable "task_cpu" {
  type        = string
  description = "Amount of CPU to allocate to the task (256, 512, 1024, 2048, 4096, 8192, 16384)"
  default     = "256"

  validation {
    condition     = contains(["256", "512", "1024", "2048", "4096", "8192", "16384"], var.task_cpu)
    error_message = "task_cpu must be one of: 256, 512, 1024, 2048, 4096, 8192, 16384"
  }
}

variable "task_memory" {
  type        = string
  description = "Amount of memory to allocate to the task"
  default     = "512"

  validation {
    condition = contains([
      "512", "1024", "2048", "3072", "4096", "5120", "6144", "7168", "8192",
      "9216", "10240", "11264", "12288", "13312", "14336", "15360", "16384",
      "17408", "18432", "19456", "20480", "21504", "22528", "23552", "24576",
      "25600", "26624", "27648", "28672", "29696", "30720"
    ], var.task_memory)
    error_message = "task_memory must be a valid Fargate memory value"
  }
}

variable "task_role_arn" {
  type        = string
  description = "ARN of IAM role that allows your Amazon ECS container task to make calls to other AWS services"
  default     = null
}

variable "execution_role_arn" {
  type        = string
  description = "ARN of the task execution role. If not provided, one will be created"
  default     = null

  validation {
    condition     = var.execution_role_arn != null || var.create_execution_role
    error_message = "Either execution_role_arn must be provided or create_execution_role must be true. Set create_execution_role = true to create a new execution role, or provide an existing role ARN via execution_role_arn."
  }
}

variable "create_execution_role" {
  type        = bool
  description = "Whether to create an execution role. Set to false if providing execution_role_arn"
  default     = true
}

variable "execution_role_policies" {
  type        = list(string)
  description = "Additional IAM policy ARNs to attach to the execution role"
  default     = []
}

variable "network_mode" {
  type        = string
  description = "Docker networking mode to use for the containers in the task"
  default     = "awsvpc"

  validation {
    condition     = contains(["awsvpc", "bridge", "host", "none"], var.network_mode)
    error_message = "network_mode must be one of: awsvpc, bridge, host, none"
  }
}

variable "requires_compatibilities" {
  type        = list(string)
  description = "Set of launch types required by the task"
  default     = ["FARGATE"]
}

variable "runtime_platform" {
  type = object({
    cpu_architecture        = optional(string, "X86_64")
    operating_system_family = optional(string, "LINUX")
  })
  description = "Runtime platform configuration"
  default = {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
}

variable "volumes" {
  type = list(object({
    name      = string
    host_path = optional(string)
    docker_volume_configuration = optional(object({
      scope         = optional(string)
      autoprovision = optional(bool)
      driver        = optional(string)
      driver_opts   = optional(map(string))
      labels        = optional(map(string))
    }))
    efs_volume_configuration = optional(object({
      file_system_id          = string
      root_directory          = optional(string)
      transit_encryption      = optional(string)
      transit_encryption_port = optional(number)
      authorization_config = optional(object({
        access_point_id = optional(string)
        iam             = optional(string)
      }))
    }))
  }))
  description = "Additional volumes for the task (Falcon volume is added automatically)"
  default     = []
}

variable "pid_mode" {
  type        = string
  description = "Process namespace to use for the containers in the task"
  default     = null
}

variable "ipc_mode" {
  type        = string
  description = "IPC resource namespace to use for the containers in the task"
  default     = null
}

variable "ephemeral_storage" {
  type = object({
    size_in_gib = number
  })
  description = "Ephemeral storage configuration"
  default     = null
}

# Falcon Configuration
variable "falcon_image" {
  type        = string
  description = "The full container image path including tag for the Falcon Container sensor"
}

variable "falcon_cid" {
  type        = string
  description = "CrowdStrike Customer ID (CID) value"
  sensitive   = true
}

variable "falcon_additional_opts" {
  type        = string
  description = "Additional options to pass to falconctl (appended to --cid)"
  default     = ""
}

variable "falcon_init_timeout" {
  type        = number
  description = "Timeout in seconds for the Falcon init container to complete"
  default     = 120
}

variable "falcon_init_cpu" {
  type        = number
  description = "CPU units to allocate to the Falcon init container"
  default     = 256
}

variable "falcon_init_memory" {
  type        = number
  description = "Memory (in MB) to allocate to the Falcon init container"
  default     = 512
}

variable "falcon_volume_name" {
  type        = string
  description = "Name of the volume used for Falcon sensor files"
  default     = "crowdstrike-falcon-volume"
}

# Logging Configuration
variable "enable_logging" {
  type        = bool
  description = "Whether to enable CloudWatch logging"
  default     = true
}

variable "log_group_name" {
  type        = string
  description = "CloudWatch log group name. If not provided, defaults to /ecs/{app_name}"
  default     = null
}

variable "create_log_group" {
  type        = bool
  description = "Whether to create the CloudWatch log group"
  default     = true
}

variable "log_retention_days" {
  type        = number
  description = "Number of days to retain logs in CloudWatch"
  default     = 30
}

variable "log_group_kms_key_id" {
  type        = string
  description = "ARN of the KMS key to use for encrypting CloudWatch log data. If not specified, logs will use default encryption."
  default     = null
}

variable "log_stream_prefix" {
  type        = string
  description = "Log stream prefix for the application container"
  default     = null
}

variable "enable_execute_command" {
  type        = bool
  description = "Enable ECS Exec for debugging (allows running commands in containers). Requires task role with SSM permissions."
  default     = false
}

variable "platform_version" {
  type        = string
  description = "Fargate platform version to use for the ECS service. Use this value when creating your ECS service. Defaults to LATEST."
  default     = "LATEST"
}

# Sidecar Containers
variable "sidecar_containers" {
  type = list(object({
    name              = string
    image             = string
    cpu               = optional(number)
    memory            = optional(number)
    memoryReservation = optional(number)
    essential         = optional(bool, false)
    entryPoint        = optional(list(string))
    command           = optional(list(string))
    environment = optional(list(object({
      name  = string
      value = string
    })), [])
    secrets = optional(list(object({
      name      = string
      valueFrom = string
    })), [])
    portMappings = optional(list(object({
      containerPort = number
      hostPort      = optional(number)
      protocol      = optional(string)
    })), [])
    mountPoints = optional(list(object({
      sourceVolume  = string
      containerPath = string
      readOnly      = optional(bool)
    })), [])
    volumesFrom = optional(list(object({
      sourceContainer = string
      readOnly        = optional(bool)
    })), [])
    dependsOn = optional(list(object({
      containerName = string
      condition     = string
    })), [])
    healthCheck = optional(object({
      command     = list(string)
      interval    = optional(number)
      timeout     = optional(number)
      retries     = optional(number)
      startPeriod = optional(number)
    }))
    user                   = optional(string)
    workingDirectory       = optional(string)
    readonlyRootFilesystem = optional(bool)
    privileged             = optional(bool)
    linuxParameters = optional(object({
      capabilities = optional(object({
        add  = optional(list(string))
        drop = optional(list(string))
      }))
    }))
    firelensConfiguration = optional(object({
      type    = string
      options = optional(map(string), {})
    }))
    logConfiguration = optional(object({
      logDriver = string
      options   = optional(map(string), {})
      secretOptions = optional(list(object({
        name      = string
        valueFrom = string
      })), [])
    }))
  }))
  description = "Additional sidecar containers to include in the task"
  default     = []
}

# Tags
variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}
