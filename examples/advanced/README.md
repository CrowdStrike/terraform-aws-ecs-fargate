# Advanced Example

This example demonstrates a comprehensive, production-ready configuration with all available features:

- Custom entrypoint and command
- Environment variables and Secrets Manager integration
- Multiple port mappings
- Health checks
- EFS volume mounts
- Sidecar containers (Fluent Bit log router)
- Custom IAM roles
- Extended log retention
- Falcon sensor tags

## What This Example Creates

- ECS task definition with Falcon init container
- Application container with production-ready configuration
- Fluent Bit sidecar for log aggregation
- Integration with existing IAM roles
- EFS volume for persistent data
- CloudWatch logging with 30-day retention

## Prerequisites

Before running this example, ensure you have:

1. **Container Images** - Both application and Falcon sensor images pushed to ECR
2. **CrowdStrike Falcon CID** - Customer ID from your Falcon console
3. **IAM Roles** - Existing execution and task roles with appropriate permissions
4. **EFS File System** - Created EFS file system with mount targets in your VPC
5. **Secrets Manager Secrets** - Secrets containing database password and API key
6. **VPC and Networking** - Subnets and security groups configured for ECS tasks and EFS access
7. **ECS Cluster** - Existing cluster to deploy the service (optional for task definition only)

## Usage

1. Create a `terraform.tfvars` file:

```hcl
app_image      = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:v1.0.0"
falcon_image   = "123456789012.dkr.ecr.us-east-1.amazonaws.com/falcon-sensor:latest"
falcon_cid     = "YOUR-CID-HERE-12345678901234567890123456789012-AB"
environment    = "production"

execution_role_arn      = "arn:aws:iam::123456789012:role/ecs-execution-role"
task_role_arn           = "arn:aws:iam::123456789012:role/ecs-task-role"
db_password_secret_arn  = "arn:aws:secretsmanager:us-east-1:123456789012:secret:db-password-abc123"
api_key_secret_arn      = "arn:aws:secretsmanager:us-east-1:123456789012:secret:api-key-xyz789"
efs_file_system_id      = "fs-12345678"
```

2. Initialize and apply:

```bash
terraform init
terraform plan
terraform apply
```

3. Deploy with an ECS service:

```bash
aws ecs create-service \
  --cluster production-cluster \
  --service-name advanced-demo-app \
  --task-definition $(terraform output -raw task_definition_family) \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-12345,subnet-67890],securityGroups=[sg-12345],assignPublicIp=DISABLED}" \
  --load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:...,containerName=$(terraform output -raw container_name),containerPort=8080"
```

## IAM Role Requirements

### Execution Role Permissions

The execution role needs:
- ECS task execution permissions
- ECR image pull permissions
- Secrets Manager read permissions
- CloudWatch Logs write permissions

### Task Role Permissions

The task role needs application-specific permissions, such as:
- S3 bucket access
- DynamoDB table access
- SQS queue access
- Any other AWS service permissions your application needs

## EFS Configuration

The EFS file system should:
- Be in the same VPC as your ECS tasks
- Have mount targets in the same subnets as your tasks
- Have security group rules allowing NFS traffic from your task security group
- Have appropriate POSIX permissions for your application user

## Secrets Manager

Secrets should be stored in AWS Secrets Manager with the following format:

```json
{
  "password": "your-secure-password"
}
```

Or as plaintext for simple values. The execution role must have `secretsmanager:GetSecretValue` permission.

## Monitoring

This example includes:
- CloudWatch Logs with 30-day retention
- Container health checks every 30 seconds
- Metrics port (9090) for Prometheus scraping
- Fluent Bit sidecar for centralized logging

## Inputs

| Name | Description | Required |
|------|-------------|----------|
| app_image | Application image URI | Yes |
| falcon_image | Falcon sensor image URI | Yes |
| falcon_cid | CrowdStrike Customer ID | Yes |
| execution_role_arn | Existing execution role ARN | Yes |
| task_role_arn | Existing task role ARN | Yes |
| db_password_secret_arn | Secrets Manager ARN for DB password | Yes |
| api_key_secret_arn | Secrets Manager ARN for API key | Yes |
| efs_file_system_id | EFS file system ID | Yes |

## Outputs

- `task_definition_arn` - Full ARN including revision
- `task_definition_family` - Family name for service creation
- `task_definition_revision` - Current revision number
- `execution_role_arn` - Execution role ARN
- `log_group_name` - CloudWatch log group name
- `container_name` - Application container name
- `falcon_volume_name` - Falcon sensor volume name
