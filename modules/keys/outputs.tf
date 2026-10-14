#==========================================================
# Local Variables for Output Organization
#==========================================================
locals {
  # Extract SSH keys by type for backward compatibility
  gcp_user_keys = {
    for key, config in local.all_ssh_keys :
    config.identifier => tls_private_key.ssh_keys[key].public_key_openssh
    if config.cloud == "gcp" && config.type == "user"
  }

  gcp_vm_keys = [
    for key, config in local.all_ssh_keys :
    tls_private_key.ssh_keys[key].public_key_openssh
    if config.cloud == "gcp" && config.type == "vm"
  ]

  aws_cloudflared_keys = [
    for key, config in local.all_ssh_keys :
    tls_private_key.ssh_keys[key].public_key_openssh
    if config.cloud == "aws" && config.type == "cloudflared"
  ]

  azure_vm_keys = [
    for key, config in local.all_ssh_keys :
    tls_private_key.ssh_keys[key].public_key_openssh
    if config.cloud == "azure" && config.type == "vm"
  ]

  # Extract file paths by type for backward compatibility
  gcp_vm_key_paths = [
    for key, config in local.all_ssh_keys :
    local_file.private_keys[key].filename
    if config.cloud == "gcp" && config.type == "vm"
  ]

  aws_cloudflared_key_paths = [
    for key, config in local.all_ssh_keys :
    local_file.private_keys[key].filename
    if config.cloud == "aws" && config.type == "cloudflared"
  ]

  azure_key_paths = [
    for key, config in local.all_ssh_keys :
    local_file.private_keys[key].filename
    if config.cloud == "azure" && config.type == "vm"
  ]
}

#======================================
# Output: GCP key pairs
#======================================
output "gcp_public_keys" {
  description = <<-EOT
    SSH public keys for GCP user accounts.

    Purpose: User-specific SSH keys for individual GCP access
    Usage: Applied to GCP user accounts for SSH authentication
    Format: Map of identifier to OpenSSH public key format
    Security: Safe to expose - public key portion only
    Related: Used for individual user access to GCP instances
  EOT
  value       = local.gcp_user_keys
}

output "gcp_vm_key" {
  description = <<-EOT
    SSH public keys for GCP virtual machine instances.

    Purpose: Instance-level SSH keys for VM access
    Usage: Applied to GCP VM metadata for SSH authentication
    Format: List of OpenSSH public key strings
    Security: Safe to expose - public key portion only
    Related: Used by gcp_vm_cloudflared, gcp_vm_warp, and gcp_vm_windows_rdp
  EOT
  value       = local.gcp_vm_keys
}

output "gcp_vm_key_paths" {
  description = <<-EOT
    File system paths to private SSH keys for GCP VMs.

    Purpose: Local file paths for SSH private keys
    Usage: Use with ssh -i command for VM access
    Format: List of absolute file paths
    Security: Paths only - actual key content is sensitive
    Example: ["/path/to/gcp_vm_0.pem", "/path/to/gcp_vm_1.pem"]
  EOT
  value       = local.gcp_vm_key_paths
  sensitive   = false
}

#======================================
# Output: AWS key pairs
#======================================
output "aws_ssh_public_key" {
  description = <<-EOT
    SSH public keys for AWS Cloudflared tunnel instances.

    Purpose: SSH access to AWS instances running cloudflared services
    Usage: Applied to AWS EC2 key pairs and instance metadata
    Format: List of OpenSSH public key strings
    Security: Safe to expose - public key portion only
    Related: Used by aws_vm_service, aws_vm_vnc, and aws_vm_cloudflared
  EOT
  value       = local.aws_cloudflared_keys
}

output "aws_ssh_service_public_key" {
  description = <<-EOT
    SSH public key for the AWS service instance.

    Purpose: SSH access to the primary AWS service VM
    Usage: Applied to aws_vm_service EC2 instance
    Format: OpenSSH public key string
    Security: Safe to expose - public key portion only
    Related: Used by aws_vm_service for browser-rendered SSH access
  EOT
  value       = tls_private_key.ssh_keys["aws_service"].public_key_openssh
}

output "aws_vnc_service_public_key" {
  description = <<-EOT
    SSH public key for the AWS VNC service instance.

    Purpose: SSH access to the AWS VNC desktop VM
    Usage: Applied to aws_vm_vnc EC2 instance
    Format: OpenSSH public key string
    Security: Safe to expose - public key portion only
    Related: Used by aws_vm_vnc for browser-rendered VNC desktop access
  EOT
  value       = tls_private_key.ssh_keys["aws_vnc"].public_key_openssh
}

output "aws_cloudflared_key_paths" {
  description = "Private key file paths for AWS Cloudflared instances"
  value       = local.aws_cloudflared_key_paths
  sensitive   = false
}

output "aws_service_key_path" {
  description = "Private key file path for AWS service instance"
  value       = local_file.private_keys["aws_service"].filename
  sensitive   = false
}

output "aws_vnc_key_path" {
  description = "Private key file path for AWS VNC instance"
  value       = local_file.private_keys["aws_vnc"].filename
  sensitive   = false
}

#======================================
# Output: Azure key pairs
#======================================
output "azure_ssh_public_key" {
  description = <<-EOT
    SSH public keys for Azure virtual machines.

    Purpose: SSH access to Azure Linux VMs
    Usage: Applied to Azure VM admin_ssh_key configuration
    Format: List of OpenSSH public key strings
    Security: Safe to expose - public key portion only
    Related: Used by azure_vm_linux instances (WARP connector and standard VMs)
  EOT
  value       = local.azure_vm_keys
}

output "azure_key_paths" {
  description = "Private key file paths for Azure VMs"
  value       = local.azure_key_paths
  sensitive   = false
}
