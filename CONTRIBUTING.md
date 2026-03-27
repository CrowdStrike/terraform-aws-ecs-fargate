# Contributing to CrowdStrike Falcon ECS Fargate Module

Thank you for your interest in contributing to this Terraform module! We welcome contributions from the community.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Process](#development-process)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)

## Code of Conduct

This project adheres to the CrowdStrike Code of Conduct. By participating, you are expected to uphold this code. Please be respectful and constructive in all interactions.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/terraform-aws-ecs-fargate.git
   cd terraform-aws-ecs-fargate
   ```
3. **Create a branch** for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Process

### Prerequisites

Install the required development tools:

```bash
# Terraform (>= 1.6.0)
brew install terraform

# Pre-commit hooks
brew install pre-commit
pre-commit install

# terraform-docs
brew install terraform-docs

# tflint
brew install tflint
```

### Making Changes

1. **Make your changes** in your feature branch
2. **Run pre-commit checks** to validate your changes:
   ```bash
   pre-commit run --all-files
   ```
3. **Test your changes** (see Testing section below)
4. **Update documentation** if needed (see Documentation section below)
5. **Commit your changes** with clear, descriptive commit messages:
   ```bash
   git commit -m "Add feature: brief description"
   ```

## Pull Request Process

1. **Update the CHANGELOG.md** with details of your changes under the `[Unreleased]` section
2. **Ensure all tests pass** and pre-commit hooks succeed
3. **Update documentation** if you've added or changed functionality
4. **Push your branch** to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```
5. **Open a Pull Request** against the `main` branch
6. **Provide a clear PR description** including:
   - What the change does
   - Why it's needed
   - Any breaking changes
   - Testing performed
7. **Respond to review feedback** promptly

### Pull Request Guidelines

- Keep PRs focused on a single feature or fix
- Write clear, concise commit messages
- Include tests for new functionality
- Update documentation for user-facing changes
- Follow the existing code style and conventions
- Ensure backward compatibility when possible
- Add examples if introducing new features

## Coding Standards

### Terraform Style

- Follow the [Terraform Style Guide](https://developer.hashicorp.com/terraform/language/syntax/style)
- Run `terraform fmt -recursive` before committing
- Use meaningful variable and resource names
- Add descriptions to all variables and outputs
- Include validation rules for variables when appropriate

### File Organization

- `main.tf` - Main resource definitions and data sources
- `variables.tf` - Input variable declarations
- `outputs.tf` - Output value declarations
- `versions.tf` - Terraform and provider version constraints
- `examples/` - Usage examples
- `docs/` - Documentation source files

### Variable Naming

- Use descriptive names: `app_name` not `name`
- Use snake_case: `app_port_mappings` not `appPortMappings`
- Boolean variables should start with verbs: `enable_logging`, `create_role`
- Default values should be production-ready and secure

### Comments

- Add comments for complex logic or non-obvious decisions
- Use `#` for single-line comments
- Keep comments up-to-date with code changes
- Document why, not what (code should be self-documenting)

## Testing

### Manual Testing

1. **Test the module** with the basic example:
   ```bash
   cd examples/basic
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   terraform init
   terraform apply
   ```

3. **Verify functionality**:
   - Task definition created successfully
   - Containers start and run properly
   - Falcon sensor integrates correctly
   - Logs appear in CloudWatch

4. **Clean up**:
   ```bash
   terraform destroy
   ```

### Validation

Run these commands before submitting a PR:

```bash
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Run pre-commit checks
pre-commit run --all-files

# Regenerate documentation
terraform-docs markdown table --output-file README.md --output-mode inject .
```

## Documentation

### README Updates

The README.md is generated from source files in the `docs/` directory:

- `docs/.header.md` - Main documentation content (features, notes, usage)
- `docs/.usage.tf` - Usage example code

After making changes to these files, regenerate the README:

```bash
terraform-docs markdown table --output-file README.md --output-mode inject .
```

### Variable Documentation

All variables must have:
- Clear, concise descriptions
- Appropriate type constraints
- Sensible defaults (when applicable)
- Validation rules (when appropriate)

Example:
```hcl
variable "app_stop_timeout" {
  type        = number
  description = "Time duration (in seconds) to wait before the container is forcefully killed if it doesn't exit normally on its own. ECS default is 30 seconds."
  default     = null
}
```

### Output Documentation

All outputs must have clear descriptions explaining:
- What the output contains
- How it should be used
- Any important notes or warnings

### Examples

When adding new features:
- Update `examples/basic` if the feature affects common use cases
- Add comments explaining the configuration
- Include sensible, production-ready defaults

## Questions or Problems?

- **General questions**: Open a GitHub Discussion
- **Bug reports**: Open a GitHub Issue with:
  - Clear description of the problem
  - Steps to reproduce
  - Expected vs actual behavior
  - Terraform version
  - Module version
  - Relevant configuration snippets
- **Feature requests**: Open a GitHub Issue with:
  - Clear description of the feature
  - Use case and benefits
  - Proposed implementation (if you have ideas)

## License

By contributing to this project, you agree that your contributions will be licensed under the project's license.

## Recognition

Contributors will be recognized in the project documentation. Thank you for helping improve this module!
