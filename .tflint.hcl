# TFLint Configuration for Multi-Cloud Zero Trust Demo
# Simplified configuration focusing on core rules that are definitely available

tflint {
  required_version = ">= 0.50"
}

# Global configuration
config {
  # Output format options: default, json, checkstyle, junit, compact, sarif
  format = "compact"

  # Plugin directory for storing downloaded plugins
  plugin_dir = "~/.tflint.d/plugins"

  # Module inspection settings
  call_module_type = "local"

  # Force mode and default behavior
  force = false
  disabled_by_default = false
}

# Core Terraform plugin - Essential for all Terraform projects
plugin "terraform" {
  enabled = true
  preset = "recommended"  # Enables comprehensive set of rules
}

# AWS provider plugin - For vm-aws-instance.tf and related resources
plugin "aws" {
  enabled = true
  version = "0.31.0"
  source = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Azure provider plugin - For vm-azure-instance.tf and azuread module
plugin "azurerm" {
  enabled = true
  version = "0.26.0"
  source = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# Google Cloud provider plugin - For vm-gcp-instance.tf
plugin "google" {
  enabled = true
  version = "0.29.0"
  source = "github.com/terraform-linters/tflint-ruleset-google"
}

#==========================================================
# Core Terraform Rules (Always Available)
#==========================================================

# Terraform version and provider requirements
rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

# Deprecated syntax and best practices
rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}

# Documentation requirements
rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

# Naming conventions
rule "terraform_naming_convention" {
  enabled = true

  # Enforce snake_case for most resources
  variable {
    format = "snake_case"
  }

  locals {
    format = "snake_case"
  }

  output {
    format = "snake_case"
  }

  resource {
    format = "snake_case"
  }

  module {
    format = "snake_case"
  }

  data {
    format = "snake_case"
  }
}

# Type constraints validation
rule "terraform_typed_variables" {
  enabled = true
}

# Standard module structure
rule "terraform_standard_module_structure" {
  enabled = true
}

#==========================================================
# Basic AWS Rules (Core only)
#==========================================================

# Instance type validation
rule "aws_instance_invalid_type" {
  enabled = true
}

# AMI validation
rule "aws_instance_invalid_ami" {
  enabled = true
}

#==========================================================
# Basic Azure Rules (Core only)
#==========================================================

# Virtual machine size validation
rule "azurerm_linux_virtual_machine_invalid_size" {
  enabled = true
}

#==========================================================
# Basic Google Cloud Rules (Core only)
#==========================================================

# Compute instance validation
rule "google_compute_instance_invalid_machine_type" {
  enabled = true
}

#==========================================================
# Custom Rules for Zero Trust Demo Project
#==========================================================

# Note: Only using rules that are confirmed to exist in current plugin versions