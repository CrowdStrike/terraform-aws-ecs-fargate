<!-- BEGIN_TF_DOCS -->
![CrowdStrike Falcon](https://raw.githubusercontent.com/CrowdStrike/falconpy/main/docs/asset/cs-logo.png)

[![Twitter URL](https://img.shields.io/twitter/url?label=Follow%20%40CrowdStrike&style=social&url=https%3A%2F%2Ftwitter.com%2FCrowdStrike)](https://twitter.com/CrowdStrike)

# CrowdStrike Falcon ECS Fargate Module

Terraform module for deploying CrowdStrike Falcon Container sensor with Amazon ECS Fargate tasks. This module automatically wraps your application containers with the Falcon sensor using an init container pattern, providing runtime protection without modifying your application images.

## Features

- Automatically wraps application containers with Falcon sensor
- Uses Falcon init container to inject sensor at runtime
- Designed specifically for AWS Fargate workloads
- Supports all standard ECS task definition options
- Optional IAM role creation with customizable policies
- Integrated logging with configurable retention

## Prerequisites

Before using this module, you need:

1. **CrowdStrike Falcon Credentials**
   - Customer ID (CID) from your Falcon console
   - Access to CrowdStrike Falcon Container registry

2. **Falcon Container Image**
   - Push the Falcon Container sensor image to Amazon ECR or another accessible registry
   - Use the image URI in the `falcon_image` variable

3. **AWS Permissions**
   - Permissions to create ECS task definitions
   - IAM role creation permissions (if using `create_execution_role = true`)
   - ECR permissions to pull images

## Architecture

This module creates an ECS task definition with:

1. **Falcon Init Container** - Runs first to prepare the Falcon sensor
   - Copies sensor files to a shared volume
   - Exits successfully after preparation
   - Non-essential (task continues if it fails)

2. **Application Container** - Your main application
   - Wrapped with Falcon entrypoint
   - Inherits Falcon sensor from shared volume
   - Requires `SYS_PTRACE` capability for runtime protection

3. **Sidecar Containers** (optional) - Additional containers
   - Log routers, proxies, monitoring agents, etc.
   - Share the same task networking and volumes

## Important Notes

> **Note**: The Falcon sensor requires the `SYS_PTRACE` Linux capability to monitor processes. This module automatically adds this capability to your application container.

> **Warning**: When using a read-only root filesystem (`app_readonly_root_filesystem = true`), ensure your application doesn't need to write to the root filesystem. The Falcon sensor files are mounted from a shared volume.

## Usage

```hcl
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
```

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.33.0 |
## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.ecs_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_task_definition.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_role.execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.execution_role_additional_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.execution_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_command"></a> [app\_command](#input\_app\_command) | The command for the application container | `list(string)` | `null` | no |
| <a name="input_app_entrypoint"></a> [app\_entrypoint](#input\_app\_entrypoint) | The entrypoint for the application container (will be wrapped by Falcon) | `list(string)` | `null` | no |
| <a name="input_app_environment"></a> [app\_environment](#input\_app\_environment) | Environment variables for the application container | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>  }))</pre> | `[]` | no |
| <a name="input_app_health_check"></a> [app\_health\_check](#input\_app\_health\_check) | Health check configuration for the application container | <pre>object({<br/>    command     = list(string)<br/>    interval    = optional(number, 30)<br/>    timeout     = optional(number, 5)<br/>    retries     = optional(number, 3)<br/>    startPeriod = optional(number, 0)<br/>  })</pre> | `null` | no |
| <a name="input_app_image"></a> [app\_image](#input\_app\_image) | The full container image path including tag for the application container | `string` | n/a | yes |
| <a name="input_app_linux_parameters"></a> [app\_linux\_parameters](#input\_app\_linux\_parameters) | Linux-specific options for the application container (SYS\_PTRACE is added automatically for Falcon) | <pre>object({<br/>    capabilities = optional(object({<br/>      add  = optional(list(string), [])<br/>      drop = optional(list(string), [])<br/>    }))<br/>    devices = optional(list(object({<br/>      hostPath      = string<br/>      containerPath = optional(string)<br/>      permissions   = optional(list(string))<br/>    })), [])<br/>    initProcessEnabled = optional(bool)<br/>    maxSwap            = optional(number)<br/>    sharedMemorySize   = optional(number)<br/>    swappiness         = optional(number)<br/>    tmpfs = optional(list(object({<br/>      containerPath = string<br/>      size          = number<br/>      mountOptions  = optional(list(string))<br/>    })), [])<br/>  })</pre> | `null` | no |
| <a name="input_app_mount_points"></a> [app\_mount\_points](#input\_app\_mount\_points) | Additional mount points for the application container (Falcon volume is added automatically) | <pre>list(object({<br/>    sourceVolume  = string<br/>    containerPath = string<br/>    readOnly      = optional(bool, false)<br/>  }))</pre> | `[]` | no |
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | Logical name for application / container (used as task family name) | `string` | n/a | yes |
| <a name="input_app_port_mappings"></a> [app\_port\_mappings](#input\_app\_port\_mappings) | Port mappings for the application container | <pre>list(object({<br/>    containerPort = number<br/>    hostPort      = optional(number)<br/>    protocol      = optional(string, "tcp")<br/>  }))</pre> | `[]` | no |
| <a name="input_app_privileged"></a> [app\_privileged](#input\_app\_privileged) | Whether to give the application container elevated privileges | `bool` | `false` | no |
| <a name="input_app_readonly_root_filesystem"></a> [app\_readonly\_root\_filesystem](#input\_app\_readonly\_root\_filesystem) | Whether the application container has a read-only root filesystem | `bool` | `false` | no |
| <a name="input_app_secrets"></a> [app\_secrets](#input\_app\_secrets) | Secrets for the application container (from SSM or Secrets Manager) | <pre>list(object({<br/>    name      = string<br/>    valueFrom = string<br/>  }))</pre> | `[]` | no |
| <a name="input_app_user"></a> [app\_user](#input\_app\_user) | User to run the application container as | `string` | `null` | no |
| <a name="input_app_working_directory"></a> [app\_working\_directory](#input\_app\_working\_directory) | Working directory for the application container | `string` | `null` | no |
| <a name="input_create_execution_role"></a> [create\_execution\_role](#input\_create\_execution\_role) | Whether to create an execution role. Set to false if providing execution\_role\_arn | `bool` | `true` | no |
| <a name="input_create_log_group"></a> [create\_log\_group](#input\_create\_log\_group) | Whether to create the CloudWatch log group | `bool` | `true` | no |
| <a name="input_enable_logging"></a> [enable\_logging](#input\_enable\_logging) | Whether to enable CloudWatch logging | `bool` | `true` | no |
| <a name="input_ephemeral_storage"></a> [ephemeral\_storage](#input\_ephemeral\_storage) | Ephemeral storage configuration | <pre>object({<br/>    size_in_gib = number<br/>  })</pre> | `null` | no |
| <a name="input_execution_role_arn"></a> [execution\_role\_arn](#input\_execution\_role\_arn) | ARN of the task execution role. If not provided, one will be created | `string` | `null` | no |
| <a name="input_execution_role_policies"></a> [execution\_role\_policies](#input\_execution\_role\_policies) | Additional IAM policy ARNs to attach to the execution role | `list(string)` | `[]` | no |
| <a name="input_falcon_additional_opts"></a> [falcon\_additional\_opts](#input\_falcon\_additional\_opts) | Additional options to pass to falconctl (appended to --cid) | `string` | `""` | no |
| <a name="input_falcon_cid"></a> [falcon\_cid](#input\_falcon\_cid) | CrowdStrike Customer ID (CID) value | `string` | n/a | yes |
| <a name="input_falcon_image"></a> [falcon\_image](#input\_falcon\_image) | The full container image path including tag for the Falcon Container sensor | `string` | n/a | yes |
| <a name="input_falcon_init_timeout"></a> [falcon\_init\_timeout](#input\_falcon\_init\_timeout) | Timeout in seconds for the Falcon init container to complete | `number` | `60` | no |
| <a name="input_falcon_volume_name"></a> [falcon\_volume\_name](#input\_falcon\_volume\_name) | Name of the volume used for Falcon sensor files | `string` | `"crowdstrike-falcon-volume"` | no |
| <a name="input_ipc_mode"></a> [ipc\_mode](#input\_ipc\_mode) | IPC resource namespace to use for the containers in the task | `string` | `null` | no |
| <a name="input_log_group_name"></a> [log\_group\_name](#input\_log\_group\_name) | CloudWatch log group name. If not provided, defaults to /ecs/{app\_name} | `string` | `null` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days to retain logs in CloudWatch | `number` | `7` | no |
| <a name="input_log_stream_prefix"></a> [log\_stream\_prefix](#input\_log\_stream\_prefix) | Log stream prefix for the application container | `string` | `null` | no |
| <a name="input_network_mode"></a> [network\_mode](#input\_network\_mode) | Docker networking mode to use for the containers in the task | `string` | `"awsvpc"` | no |
| <a name="input_pid_mode"></a> [pid\_mode](#input\_pid\_mode) | Process namespace to use for the containers in the task | `string` | `null` | no |
| <a name="input_requires_compatibilities"></a> [requires\_compatibilities](#input\_requires\_compatibilities) | Set of launch types required by the task | `list(string)` | <pre>[<br/>  "FARGATE"<br/>]</pre> | no |
| <a name="input_runtime_platform"></a> [runtime\_platform](#input\_runtime\_platform) | Runtime platform configuration | <pre>object({<br/>    cpu_architecture        = optional(string, "X86_64")<br/>    operating_system_family = optional(string, "LINUX")<br/>  })</pre> | <pre>{<br/>  "cpu_architecture": "X86_64",<br/>  "operating_system_family": "LINUX"<br/>}</pre> | no |
| <a name="input_sidecar_containers"></a> [sidecar\_containers](#input\_sidecar\_containers) | Additional sidecar containers to include in the task | <pre>list(object({<br/>    name                   = string<br/>    image                  = string<br/>    cpu                    = optional(number)<br/>    memory                 = optional(number)<br/>    memoryReservation      = optional(number)<br/>    essential              = optional(bool, false)<br/>    entryPoint             = optional(list(string))<br/>    command                = optional(list(string))<br/>    environment            = optional(list(object({<br/>      name  = string<br/>      value = string<br/>    })), [])<br/>    secrets                = optional(list(object({<br/>      name      = string<br/>      valueFrom = string<br/>    })), [])<br/>    portMappings           = optional(list(object({<br/>      containerPort = number<br/>      hostPort      = optional(number)<br/>      protocol      = optional(string)<br/>    })), [])<br/>    mountPoints            = optional(list(object({<br/>      sourceVolume  = string<br/>      containerPath = string<br/>      readOnly      = optional(bool)<br/>    })), [])<br/>    volumesFrom            = optional(list(object({<br/>      sourceContainer = string<br/>      readOnly        = optional(bool)<br/>    })), [])<br/>    dependsOn              = optional(list(object({<br/>      containerName = string<br/>      condition     = string<br/>    })), [])<br/>    healthCheck            = optional(object({<br/>      command     = list(string)<br/>      interval    = optional(number)<br/>      timeout     = optional(number)<br/>      retries     = optional(number)<br/>      startPeriod = optional(number)<br/>    }))<br/>    user                   = optional(string)<br/>    workingDirectory       = optional(string)<br/>    readonlyRootFilesystem = optional(bool)<br/>    privileged             = optional(bool)<br/>    linuxParameters        = optional(object({<br/>      capabilities = optional(object({<br/>        add  = optional(list(string))<br/>        drop = optional(list(string))<br/>      }))<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_task_cpu"></a> [task\_cpu](#input\_task\_cpu) | Amount of CPU to allocate to the task (256, 512, 1024, 2048, 4096, 8192, 16384) | `string` | `"256"` | no |
| <a name="input_task_memory"></a> [task\_memory](#input\_task\_memory) | Amount of memory to allocate to the task | `string` | `"512"` | no |
| <a name="input_task_role_arn"></a> [task\_role\_arn](#input\_task\_role\_arn) | ARN of IAM role that allows your Amazon ECS container task to make calls to other AWS services | `string` | `null` | no |
| <a name="input_volumes"></a> [volumes](#input\_volumes) | Additional volumes for the task (Falcon volume is added automatically) | <pre>list(object({<br/>    name      = string<br/>    host_path = optional(string)<br/>    docker_volume_configuration = optional(object({<br/>      scope         = optional(string)<br/>      autoprovision = optional(bool)<br/>      driver        = optional(string)<br/>      driver_opts   = optional(map(string))<br/>      labels        = optional(map(string))<br/>    }))<br/>    efs_volume_configuration = optional(object({<br/>      file_system_id          = string<br/>      root_directory          = optional(string)<br/>      transit_encryption      = optional(string)<br/>      transit_encryption_port = optional(number)<br/>      authorization_config = optional(object({<br/>        access_point_id = optional(string)<br/>        iam             = optional(string)<br/>      }))<br/>    }))<br/>  }))</pre> | `[]` | no |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_container_name"></a> [container\_name](#output\_container\_name) | Name of the application container |
| <a name="output_execution_role_arn"></a> [execution\_role\_arn](#output\_execution\_role\_arn) | ARN of the ECS execution role |
| <a name="output_execution_role_name"></a> [execution\_role\_name](#output\_execution\_role\_name) | Name of the ECS execution role (if created) |
| <a name="output_falcon_volume_name"></a> [falcon\_volume\_name](#output\_falcon\_volume\_name) | Name of the Falcon sensor volume |
| <a name="output_log_group_arn"></a> [log\_group\_arn](#output\_log\_group\_arn) | ARN of the CloudWatch log group |
| <a name="output_log_group_name"></a> [log\_group\_name](#output\_log\_group\_name) | Name of the CloudWatch log group |
| <a name="output_task_definition_arn"></a> [task\_definition\_arn](#output\_task\_definition\_arn) | Full ARN of the Task Definition (including revision) |
| <a name="output_task_definition_family"></a> [task\_definition\_family](#output\_task\_definition\_family) | Family of the Task Definition |
| <a name="output_task_definition_revision"></a> [task\_definition\_revision](#output\_task\_definition\_revision) | Revision of the Task Definition |
<!-- END_TF_DOCS -->