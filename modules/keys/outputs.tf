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
  description = "Public keys for GCP users"
  value       = local.gcp_user_keys
}

output "gcp_vm_key" {
  description = "Public keys for GCP VMs"
  value       = local.gcp_vm_keys
}

output "gcp_vm_key_paths" {
  description = "Private key file paths for GCP VMs"
  value       = local.gcp_vm_key_paths
  sensitive   = false
}

#======================================
# Output: AWS key pairs
#======================================
output "aws_ssh_public_key" {
  description = "Public keys for AWS Cloudflared instances"
  value       = local.aws_cloudflared_keys
}

output "aws_ssh_service_public_key" {
  description = "Public key for AWS service instance"
  value       = tls_private_key.ssh_keys["aws_service"].public_key_openssh
}

output "aws_vnc_service_public_key" {
  description = "Public key for AWS VNC instance"
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
  description = "Public keys for Azure VMs"
  value       = local.azure_vm_keys
}

output "azure_key_paths" {
  description = "Private key file paths for Azure VMs"
  value       = local.azure_key_paths
  sensitive   = false
}
