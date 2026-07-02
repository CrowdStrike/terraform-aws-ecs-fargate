# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **`app_log_configuration`** variable: overrides the app container log driver. When `enable_logging = true` and this is set, it takes precedence over the default `awslogs` configuration. Enables FireLens (`awsfirelens`) or any other ECS-supported log driver without disabling CloudWatch logging for sidecars. Supports the full AWS `logConfiguration` type (`logDriver`, `options`, `secretOptions`).
- **`sidecar_containers[*].firelensConfiguration`**: declares a sidecar container as a FireLens log router (`type = "fluentbit"` or `"fluentd"`). Supports the full AWS `firelensConfiguration` type (`type`, `options`).
- **`sidecar_containers[*].logConfiguration`**: per-sidecar log driver override. When set, takes precedence over the shared `awslogs` default. When omitted, existing fallback behaviour is unchanged.

All new fields are optional with `null`/empty defaults — fully backwards compatible.

---

Initial release of the CrowdStrike Falcon ECS Fargate Terraform module.

### Features

- **Zero-Touch Integration** - Automatically wraps application containers with Falcon sensor using init container pattern
- **Multi-Architecture Support** - Supports both x86_64 (Intel/AMD) and ARM64 (Graviton) architectures with automatic loader path detection
- **Flexible Configuration** - Comprehensive configuration options for task definitions, containers, and resources
- **IAM Management** - Optional IAM execution role creation with customizable policies
- **CloudWatch Integration** - Integrated logging with configurable retention (default 30 days) and optional KMS encryption
- **Resource Management** - Container-level and task-level CPU/memory limits with sensible defaults
- **Volume Support** - Support for EFS, Docker volumes, and ephemeral storage
- **Health Checks** - Container health check configuration
- **Security Hardening** - Read-only root filesystem support, custom Linux capabilities (SYS_PTRACE auto-added)
- **ECS Exec Support** - Optional debugging support via AWS ECS Exec
- **Platform Version Control** - Pin specific Fargate platform versions for stable deployments
- **Graceful Shutdown** - Configurable container stop timeout for proper cleanup
- **Sidecar Containers** - Support for additional sidecar containers
- **Monitoring Integration** - CloudWatch metrics outputs for easy monitoring setup
- **AWS GovCloud Compatible** - Automatically detects and uses correct ARN partitions
- **Developer Tooling** - Pre-commit hooks configuration for automated validation and formatting

### Configuration

Key variables:
- `app_name`, `app_image` - Application container configuration
- `falcon_image`, `falcon_cid` - CrowdStrike Falcon sensor configuration
- `app_entrypoint` - Optional entrypoint override (defaults to image entrypoint)
- `app_cpu`, `app_memory`, `app_memory_reservation` - Container-level resource limits
- `app_stop_timeout` - Graceful shutdown timeout (default: 30s)
- `task_cpu`, `task_memory` - Task-level resource allocation
- `platform_version` - Fargate platform version (default: LATEST)
- `enable_execute_command` - Enable ECS Exec for debugging
- `log_group_kms_key_id` - Optional KMS encryption for CloudWatch Logs
- `falcon_init_timeout` - Falcon init container timeout (default: 120s)
- `falcon_init_cpu`, `falcon_init_memory` - Falcon init container resources (defaults: 256 CPU, 512 MB)

### Documentation

- Comprehensive README with usage examples and production tips
- CONTRIBUTING.md with development guidelines
- Examples directory with basic usage
- Pre-commit hooks for automated validation

[Unreleased]: https://github.com/crowdstrike/terraform-aws-ecs-fargate/commits/main
