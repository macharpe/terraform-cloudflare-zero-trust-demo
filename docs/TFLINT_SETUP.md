# TFLint Setup and Configuration Guide

This guide provides comprehensive instructions for setting up and using TFLint in the Zero Trust Demo project to ensure code quality, catch potential issues early, and enforce Terraform best practices across multi-cloud environments.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [GitHub Actions Integration](#github-actions-integration)
- [Pre-commit Hooks](#pre-commit-hooks)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Overview

TFLint is a pluggable Terraform linter that helps identify potential errors, violations of best practices, and inconsistencies in Terraform configurations before deployment. This project uses TFLint to validate code across multiple cloud providers (AWS, Azure, GCP) and Cloudflare.

### Key Benefits

- **Early Error Detection**: Catch issues before `terraform apply`
- **Provider-Specific Validation**: AWS, Azure, GCP, and Cloudflare best practices
- **Code Quality Enforcement**: Consistent naming conventions and documentation requirements
- **Security Scanning**: Identify potential security misconfigurations
- **CI/CD Integration**: Automated validation in GitHub Actions

## Installation

### Local Installation

#### Option 1: Direct Installation (Linux/macOS)
```bash
# Install TFLint
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Verify installation
tflint --version
```

#### Option 2: Package Managers

**macOS (Homebrew):**
```bash
brew install tflint
```

**Windows (Chocolatey):**
```bash
choco install tflint
```

#### Option 3: Docker
```bash
# Run TFLint in Docker
docker run --rm -v $(pwd):/data -t ghcr.io/terraform-linters/tflint

# With initialization
docker run --rm -v $(pwd):/data -t --entrypoint /bin/sh ghcr.io/terraform-linters/tflint -c "tflint --init && tflint"
```

### Project Setup

After installing TFLint, initialize the project configuration:

```bash
# Navigate to project root
cd /path/to/terraform-cloudflare-zero-trust-demo

# Initialize TFLint (downloads provider plugins)
tflint --init

# Verify setup
tflint --version
```

## Configuration

The project includes a comprehensive `.tflint.hcl` configuration file with the following features:

### Enabled Plugins

1. **Core Terraform Plugin**: Essential Terraform language rules
2. **AWS Plugin**: AWS provider-specific validations
3. **Azure Plugin**: Azure provider-specific validations
4. **Google Cloud Plugin**: GCP provider-specific validations

### Key Rules Enabled

- **Documentation Requirements**: All variables and outputs must be documented
- **Naming Conventions**: Enforces snake_case naming across resources
- **Type Constraints**: Validates variable type specifications
- **Provider Validation**: Cloud-specific resource validation
- **Security Rules**: Identifies potential security misconfigurations
- **Best Practices**: Enforces Terraform and cloud provider best practices

### Configuration File Structure

```hcl
# .tflint.hcl
tflint {
  required_version = ">= 0.50"
}

config {
  format = "compact"
  plugin_dir = "~/.tflint.d/plugins"
  module = true
  varfile = ["terraform.tfvars", "*.auto.tfvars"]
}

# Plugins for each cloud provider
plugin "terraform" { enabled = true, preset = "recommended" }
plugin "aws" { enabled = true, version = "0.31.0" }
plugin "azurerm" { enabled = true, version = "0.26.0" }
plugin "google" { enabled = true, version = "0.29.0" }
```

## Usage

### Basic Commands

```bash
# Run TFLint on current directory
tflint

# Run with compact output (CI-friendly)
tflint --format compact

# Run recursively on all subdirectories
tflint --recursive

# Run with specific configuration file
tflint --config .tflint.hcl

# Initialize plugins (run after config changes)
tflint --init
```

### Advanced Usage

```bash
# Run on specific directory
tflint modules/cloudflare/

# Output in different formats
tflint --format json          # JSON output
tflint --format checkstyle    # Checkstyle XML
tflint --format junit         # JUnit XML
tflint --format sarif         # SARIF format

# Enable/disable specific rules
tflint --enable-rule terraform_required_version
tflint --disable-rule aws_instance_previous_type

# Verbose output for debugging
tflint --loglevel trace
```

### Module-Specific Validation

```bash
# Validate individual modules
tflint --config ../../.tflint.hcl modules/cloudflare/
tflint --config ../../.tflint.hcl modules/azure/
tflint --config ../../.tflint.hcl modules/keys/
tflint --config ../../.tflint.hcl modules/warp-routing/
```

## GitHub Actions Integration

The project includes a comprehensive GitHub Actions workflow (`.github/workflows/tflint.yml`) that:

### Workflow Features

- **Automatic Triggers**: Runs on push/PR to main branch for Terraform files
- **Plugin Caching**: Caches TFLint plugins for faster runs
- **Multi-Module Validation**: Validates root module and all submodules
- **Format Checking**: Runs `terraform fmt` validation
- **Security Scanning**: Includes Trivy security scans for PRs
- **Summary Reports**: Provides detailed validation summaries

### Workflow Structure

```yaml
jobs:
  tflint:          # TFLint analysis on all modules
  terraform-validate:  # terraform fmt and validate
  security-scan:   # Security scanning with Trivy
  summary:         # Validation results summary
```

### Workflow Benefits

- **PR Integration**: Automatic validation on pull requests
- **Problem Matchers**: GitHub annotations for issues
- **Parallel Execution**: Fast validation across modules
- **Security Integration**: Combined with security scanning
- **Detailed Reporting**: Comprehensive validation summaries

## Pre-commit Hooks

The project includes pre-commit hooks configuration (`.pre-commit-config.yaml`) for local development:

### Setup Pre-commit Hooks

```bash
# Install pre-commit (one-time setup)
pip install pre-commit

# Install git hooks in repository
pre-commit install

# Run all hooks manually
pre-commit run --all-files

# Update hook versions
pre-commit autoupdate
```

### Included Hooks

1. **terraform_fmt**: Automatically formats Terraform files
2. **terraform_validate**: Validates Terraform syntax
3. **terraform_tflint**: Runs TFLint analysis
4. **terraform_docs**: Generates module documentation
5. **terraform_checkov**: Security scanning with Checkov
6. **General hooks**: Trailing whitespace, JSON/YAML validation, etc.

### Hook Configuration

```yaml
# Pre-commit hook for TFLint
- id: terraform_tflint
  args:
    - --args=--config=__GIT_WORKING_DIR__/.tflint.hcl
    - --args=--format=compact
    - --args=--color
```

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Plugin Download Failures
```bash
# Problem: Plugins fail to download
# Solution: Check network connectivity and GitHub access
tflint --init --loglevel trace

# Alternative: Set GitHub token
export GITHUB_TOKEN="your_token_here"
tflint --init
```

#### Issue 2: Module Path Issues
```bash
# Problem: TFLint can't find modules
# Solution: Use absolute config path
tflint --config $(pwd)/.tflint.hcl
```

#### Issue 3: Rule Conflicts
```bash
# Problem: Rules conflict with project architecture
# Solution: Disable specific rules in .tflint.hcl
rule "aws_instance_previous_type" {
  enabled = false
}
```

#### Issue 4: Large Repository Performance
```bash
# Problem: TFLint runs slowly on large repos
# Solution: Use targeted validation
tflint --filter="*.tf" --exclude-path=".terraform/"
```

### Debug Commands

```bash
# Check TFLint configuration
tflint --print-config

# Verbose logging for troubleshooting
tflint --loglevel trace

# Check plugin status
ls -la ~/.tflint.d/plugins/

# Validate configuration syntax
tflint --config .tflint.hcl --print-config
```

## Best Practices

### Development Workflow

1. **Local Development**:
   ```bash
   # Before committing
   terraform fmt -recursive
   terraform validate
   tflint
   ```

2. **Pre-commit Integration**:
   - Install pre-commit hooks for automatic validation
   - Hooks prevent commits with linting issues
   - Ensures consistent code quality

3. **Module Development**:
   ```bash
   # Validate individual modules during development
   cd modules/cloudflare/
   tflint --config ../../.tflint.hcl
   ```

### Configuration Management

1. **Centralized Configuration**: Use single `.tflint.hcl` for entire project
2. **Provider Versions**: Pin plugin versions for consistency
3. **Rule Customization**: Disable conflicting rules, enable security rules
4. **Documentation**: Document any disabled rules and reasons

### CI/CD Integration

1. **Automatic Validation**: TFLint runs on every PR
2. **Fail Fast**: Stop builds on linting errors
3. **Security Integration**: Combine with security scanning tools
4. **Reporting**: Generate detailed validation reports

### Team Guidelines

1. **Consistent Usage**: All team members use same TFLint configuration
2. **Local Validation**: Run TFLint before pushing changes
3. **Rule Discussions**: Team discussions for rule changes
4. **Documentation**: Keep validation documentation updated

## Rule Reference

### Core Terraform Rules

- `terraform_required_version`: Terraform version constraints
- `terraform_required_providers`: Provider version requirements
- `terraform_documented_variables`: Variable documentation
- `terraform_documented_outputs`: Output documentation
- `terraform_naming_convention`: Resource naming standards

### AWS-Specific Rules

- `aws_instance_invalid_type`: EC2 instance type validation
- `aws_resource_missing_tags`: Required resource tagging
- `aws_security_group_rule_invalid_protocol`: Security group validation
- `aws_s3_bucket_invalid_policy`: S3 bucket policy validation

### Azure-Specific Rules

- `azurerm_resource_missing_tags`: Azure resource tagging
- `azurerm_linux_virtual_machine_invalid_size`: VM size validation
- `azurerm_network_security_rule_invalid_protocol`: NSG rule validation

### GCP-Specific Rules

- `google_compute_instance_invalid_machine_type`: Compute instance validation
- `google_resource_missing_labels`: GCP resource labeling
- `google_compute_firewall_invalid_protocol`: Firewall rule validation

## Performance Optimization

### Caching Strategy

```bash
# Local plugin cache
export TFLINT_PLUGIN_DIR="~/.tflint.d/plugins"

# CI cache in GitHub Actions
uses: actions/cache@v4
with:
  path: ~/.tflint.d/plugins
  key: ${{ runner.os }}-tflint-${{ hashFiles('.tflint.hcl') }}
```

### Targeted Validation

```bash
# Validate only changed files
git diff --name-only main...HEAD | grep '\.tf$' | xargs -I {} tflint {}

# Exclude specific directories
tflint --exclude-path=".terraform/" --exclude-path="vendor/"
```

## Integration with Other Tools

### Terraform Workflow Integration

```bash
# Complete validation pipeline
terraform fmt -recursive && \
terraform validate && \
tflint && \
terraform plan
```

### Security Scanning Integration

```bash
# Combined security and linting
tflint && \
checkov -d . && \
trivy config .
```

### IDE Integration

- **VS Code**: Use TFLint extension for real-time feedback
- **IntelliJ**: Configure TFLint as external tool
- **Vim/Neovim**: Use ALE plugin with TFLint integration

## Maintenance

### Regular Updates

```bash
# Update TFLint
brew upgrade tflint  # macOS
# or download latest release

# Update plugins
tflint --init

# Update pre-commit hooks
pre-commit autoupdate
```

### Configuration Review

- Review `.tflint.hcl` quarterly for new rules
- Update plugin versions regularly
- Adjust rules based on project evolution
- Document any configuration changes

---

For additional help or questions about TFLint setup, refer to:
- [Official TFLint Documentation](https://github.com/terraform-linters/tflint)
- [Provider Plugin Documentation](https://github.com/terraform-linters/tflint-ruleset-aws)
- Project CLAUDE.md for workflow integration