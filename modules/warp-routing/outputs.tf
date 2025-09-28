output "cf_azure_json_subnet_generation" {
  description = <<-EOT
    Azure subnet generation script execution result.

    Purpose: Tracks the execution of Python script for Azure WARP subnet calculation
    Usage: Internal module dependency tracking
    Format: Terraform null_resource object
    Related: Generates Azure WARP routing configuration from base CIDR
    Script: Calculates 100.96.1.0/24 subnet for Azure WARP connector
  EOT
  value       = null_resource.python_script_azure_infrastructure
  sensitive   = false
}

output "cf_gcp_json_subnet_generation" {
  description = <<-EOT
    GCP subnet generation script execution result.

    Purpose: Tracks the execution of Python script for GCP WARP subnet calculation
    Usage: Internal module dependency tracking
    Format: Terraform null_resource object
    Related: Generates GCP WARP routing configuration from base CIDR
    Script: Calculates 100.96.2.0/24 subnet for GCP WARP connector
  EOT
  value       = null_resource.python_script_gcp_infrastructure_warp
  sensitive   = false
}

output "cf_aws_json_subnet_generation" {
  description = <<-EOT
    AWS subnet generation script execution result.

    Purpose: Tracks the execution of Python script for AWS WARP subnet calculation
    Usage: Internal module dependency tracking
    Format: Terraform null_resource object
    Related: Generates AWS WARP routing configuration from base CIDR
    Script: Calculates 100.96.3.0/24 subnet for AWS WARP connector (future use)
  EOT
  value       = null_resource.python_script_aws_infrastructure
  sensitive   = false
}
