# Basic Example

This example demonstrates the minimal configuration needed to deploy an ECS Fargate task with CrowdStrike Falcon sensor protection.

## What This Example Creates

- ECS task definition with Falcon init container
- Application container wrapped with Falcon sensor
- IAM execution role with basic ECS permissions
- CloudWatch log group for container logs

## Prerequisites

Before running this example, ensure you have:

1. **Container Images** - Both application and Falcon sensor images pushed to a container registry (ECR recommended)
2. **CrowdStrike Falcon CID** - Your Customer ID from the Falcon console
3. **AWS Permissions** - Ability to create ECS task definitions, IAM roles, and CloudWatch log groups
4. **ECS Cluster** - An existing ECS cluster to run the task (optional for task definition creation)

## Usage

1. Set your application and Falcon image URIs:

```bash
export TF_VAR_app_image="123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:v1.0.0"
export TF_VAR_falcon_image="123456789012.dkr.ecr.us-east-1.amazonaws.com/falcon-sensor:latest"
export TF_VAR_falcon_cid="YOUR-CID-HERE-12345678901234567890123456789012-AB"
```

2. Initialize and apply:

```bash
terraform init
terraform plan
terraform apply
```

3. Use the task definition with an ECS service:

```bash
aws ecs create-service \
  --cluster my-cluster \
  --service-name my-service \
  --task-definition $(terraform output -raw task_definition_family) \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-12345],securityGroups=[sg-12345]}"
```

## Inputs

| Name | Description | Default |
|------|-------------|---------|
| app_image | Application container image URI | (required) |
| falcon_image | Falcon sensor image URI | (required) |
| falcon_cid | CrowdStrike Customer ID | (required) |
| app_name | Application name | demo-app |
| app_port | Application port | 8080 |
| task_cpu | Task CPU units | 512 |
| task_memory | Task memory in MB | 1024 |

## Outputs

- `task_definition_arn` - Full ARN including revision
- `task_definition_family` - Family name for ECS service reference
- `execution_role_arn` - IAM role ARN for execution
- `container_name` - Application container name for load balancer targeting
