# Data sources
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

# Local variables
locals {
  log_group_name    = var.log_group_name != null ? var.log_group_name : "/ecs/${var.app_name}"
  log_stream_prefix = var.log_stream_prefix != null ? var.log_stream_prefix : var.app_name

  # Determine execution role ARN
  execution_role_arn = var.execution_role_arn != null ? var.execution_role_arn : (
    var.create_execution_role ? aws_iam_role.execution_role[0].arn : null
  )

  # Determine loader path based on CPU architecture
  ld_loader_path = var.runtime_platform.cpu_architecture == "ARM64" ? "/tmp/CrowdStrike/rootfs/lib64/ld-linux-aarch64.so.1" : "/tmp/CrowdStrike/rootfs/lib64/ld-linux-x86-64.so.2"

  # Build Falcon entrypoint wrapper
  falcon_entrypoint_base = [
    local.ld_loader_path,
    "--library-path",
    "/tmp/CrowdStrike/rootfs/lib64",
    "/tmp/CrowdStrike/rootfs/bin/bash",
    "/tmp/CrowdStrike/rootfs/entrypoint-ecs.sh"
  ]

  # Handle app entrypoint - convert to string if it's a list
  app_entrypoint_string = var.app_entrypoint != null ? (
    length(var.app_entrypoint) == 1 ? var.app_entrypoint[0] : join(" ", var.app_entrypoint)
  ) : null

  # Combine Falcon wrapper with app entrypoint
  # Only wrap if app_entrypoint is provided; otherwise, Falcon will wrap the container's default entrypoint
  wrapped_entrypoint = local.app_entrypoint_string != null ? concat(
    local.falcon_entrypoint_base,
    [local.app_entrypoint_string]
  ) : null

  # Merge Falcon environment with app environment
  app_environment_with_falcon = concat(
    var.app_environment,
    [
      {
        name  = "FALCONCTL_OPTS"
        value = "--cid=${var.falcon_cid}${var.falcon_additional_opts != "" ? " ${var.falcon_additional_opts}" : ""}"
      }
    ]
  )

  # Add Falcon volume to mount points
  app_mount_points_with_falcon = concat(
    var.app_mount_points,
    [
      {
        sourceVolume  = var.falcon_volume_name
        containerPath = "/tmp/CrowdStrike"
        readOnly      = false
      }
    ]
  )

  # Merge SYS_PTRACE capability with any user-provided capabilities
  linux_parameters = var.app_linux_parameters != null ? {
    capabilities = {
      add = distinct(concat(
        try(var.app_linux_parameters.capabilities.add, []),
        ["SYS_PTRACE"]
      ))
      drop = tolist(try(var.app_linux_parameters.capabilities.drop, []))
    }
    devices            = tolist(try(var.app_linux_parameters.devices, []))
    initProcessEnabled = try(var.app_linux_parameters.initProcessEnabled, null)
    maxSwap            = try(var.app_linux_parameters.maxSwap, null)
    sharedMemorySize   = try(var.app_linux_parameters.sharedMemorySize, null)
    swappiness         = try(var.app_linux_parameters.swappiness, null)
    tmpfs              = tolist(try(var.app_linux_parameters.tmpfs, []))
    } : {
    capabilities = {
      add  = tolist(["SYS_PTRACE"])
      drop = tolist([])
    }
    devices            = tolist([])
    initProcessEnabled = null
    maxSwap            = null
    sharedMemorySize   = null
    swappiness         = null
    tmpfs              = tolist([])
  }

  # Build log configuration
  log_configuration = var.enable_logging ? {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = var.create_log_group ? aws_cloudwatch_log_group.ecs_log_group[0].name : local.log_group_name
      "awslogs-region"        = data.aws_region.current.id
      "awslogs-stream-prefix" = local.log_stream_prefix
    }
  } : null

  # Add Falcon volume to user-provided volumes
  all_volumes = concat(
    var.volumes,
    [
      {
        name                        = var.falcon_volume_name
        host_path                   = null
        docker_volume_configuration = null
        efs_volume_configuration    = null
      }
    ]
  )
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  count = var.enable_logging && var.create_log_group ? 1 : 0

  name              = local.log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_group_kms_key_id

  tags = var.tags
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "execution_role" {
  count = var.create_execution_role ? 1 : 0

  name = "${var.app_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "execution_role_policy" {
  count = var.create_execution_role ? 1 : 0

  role       = aws_iam_role.execution_role[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "execution_role_additional_policies" {
  for_each = var.create_execution_role ? toset(var.execution_role_policies) : []

  role       = aws_iam_role.execution_role[0].name
  policy_arn = each.value
}

# ECS Task Definition
resource "aws_ecs_task_definition" "task" {
  family                   = var.app_name
  network_mode             = var.network_mode
  requires_compatibilities = var.requires_compatibilities
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = local.execution_role_arn
  task_role_arn            = var.task_role_arn
  pid_mode                 = var.pid_mode
  ipc_mode                 = var.ipc_mode

  dynamic "runtime_platform" {
    for_each = var.runtime_platform != null ? [var.runtime_platform] : []
    content {
      cpu_architecture        = runtime_platform.value.cpu_architecture
      operating_system_family = runtime_platform.value.operating_system_family
    }
  }

  dynamic "ephemeral_storage" {
    for_each = var.ephemeral_storage != null ? [var.ephemeral_storage] : []
    content {
      size_in_gib = ephemeral_storage.value.size_in_gib
    }
  }

  # Volumes
  dynamic "volume" {
    for_each = local.all_volumes
    content {
      name      = volume.value.name
      host_path = volume.value.host_path

      dynamic "docker_volume_configuration" {
        for_each = volume.value.docker_volume_configuration != null ? [volume.value.docker_volume_configuration] : []
        content {
          scope         = docker_volume_configuration.value.scope
          autoprovision = docker_volume_configuration.value.autoprovision
          driver        = docker_volume_configuration.value.driver
          driver_opts   = docker_volume_configuration.value.driver_opts
          labels        = docker_volume_configuration.value.labels
        }
      }

      dynamic "efs_volume_configuration" {
        for_each = volume.value.efs_volume_configuration != null ? [volume.value.efs_volume_configuration] : []
        content {
          file_system_id          = efs_volume_configuration.value.file_system_id
          root_directory          = efs_volume_configuration.value.root_directory
          transit_encryption      = efs_volume_configuration.value.transit_encryption
          transit_encryption_port = efs_volume_configuration.value.transit_encryption_port

          dynamic "authorization_config" {
            for_each = efs_volume_configuration.value.authorization_config != null ? [efs_volume_configuration.value.authorization_config] : []
            content {
              access_point_id = authorization_config.value.access_point_id
              iam             = authorization_config.value.iam
            }
          }
        }
      }
    }
  }

  # Container Definitions
  container_definitions = jsonencode(concat(
    [
      # Falcon Init Container
      {
        name      = "crowdstrike-falcon-init-container"
        image     = var.falcon_image
        user      = "0:0"
        essential = false
        cpu       = var.falcon_init_cpu
        memory    = var.falcon_init_memory

        entryPoint = [
          "/bin/bash",
          "-c",
          "chmod u+rwx /tmp/CrowdStrike && mkdir /tmp/CrowdStrike/rootfs && cp -r /bin /etc /lib64 /usr /entrypoint-ecs.sh /tmp/CrowdStrike/rootfs && chmod -R a=rX /tmp/CrowdStrike"
        ]

        mountPoints = [
          {
            containerPath = "/tmp/CrowdStrike"
            sourceVolume  = var.falcon_volume_name
            readOnly      = false
          }
        ]

        startTimeout = var.falcon_init_timeout
      },
      # Application Container
      merge(
        {
          name      = var.app_name
          image     = var.app_image
          essential = true

          environment = local.app_environment_with_falcon
          secrets     = var.app_secrets

          portMappings = var.app_port_mappings
          mountPoints  = local.app_mount_points_with_falcon

          dependsOn = [
            {
              containerName = "crowdstrike-falcon-init-container"
              condition     = "COMPLETE"
            }
          ]

          linuxParameters = local.linux_parameters
        },
        var.app_cpu != null ? { cpu = var.app_cpu } : {},
        var.app_memory != null ? { memory = var.app_memory } : {},
        var.app_memory_reservation != null ? { memoryReservation = var.app_memory_reservation } : {},
        local.wrapped_entrypoint != null ? { entryPoint = local.wrapped_entrypoint } : {},
        var.app_command != null ? { command = var.app_command } : {},
        var.app_user != null ? { user = var.app_user } : {},
        var.app_working_directory != null ? { workingDirectory = var.app_working_directory } : {},
        var.app_readonly_root_filesystem ? { readonlyRootFilesystem = true } : {},
        var.app_privileged ? { privileged = true } : {},
        var.app_health_check != null ? { healthCheck = var.app_health_check } : {},
        local.log_configuration != null ? { logConfiguration = local.log_configuration } : {}
      )
    ],
    # Sidecar Containers
    [
      for container in var.sidecar_containers : merge(
        {
          name      = container.name
          image     = container.image
          essential = container.essential
        },
        container.cpu != null ? { cpu = container.cpu } : {},
        container.memory != null ? { memory = container.memory } : {},
        container.memoryReservation != null ? { memoryReservation = container.memoryReservation } : {},
        container.entryPoint != null ? { entryPoint = container.entryPoint } : {},
        container.command != null ? { command = container.command } : {},
        length(container.environment) > 0 ? { environment = container.environment } : {},
        length(container.secrets) > 0 ? { secrets = container.secrets } : {},
        length(container.portMappings) > 0 ? { portMappings = container.portMappings } : {},
        length(container.mountPoints) > 0 ? { mountPoints = container.mountPoints } : {},
        container.volumesFrom != null ? { volumesFrom = container.volumesFrom } : {},
        length(container.dependsOn) > 0 ? { dependsOn = container.dependsOn } : {},
        container.healthCheck != null ? { healthCheck = container.healthCheck } : {},
        container.user != null ? { user = container.user } : {},
        container.workingDirectory != null ? { workingDirectory = container.workingDirectory } : {},
        container.readonlyRootFilesystem != null ? { readonlyRootFilesystem = container.readonlyRootFilesystem } : {},
        container.privileged != null ? { privileged = container.privileged } : {},
        container.linuxParameters != null ? { linuxParameters = container.linuxParameters } : {},
        local.log_configuration != null ? { logConfiguration = local.log_configuration } : {}
      )
    ]
  ))

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}
