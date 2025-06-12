#======================================
# Output: GCP key pairs
#======================================
output "gcp_public_keys" {
  value = {
    for username, key in tls_private_key.gcp_user_keys :
    username => local_file.gcp_public_keys[username].content # Add .content
  }
}

output "gcp_vm_key" {
  value = [for key in tls_private_key.gcp_vm_key : key.public_key_openssh]
}

# Used in main outputs.tf
output "gcp_vm_key_paths" {
  value = [for k in local_file.gcp_vm_private_key : k.filename]
}



#======================================
# Output: AWS key pairs
#======================================
output "aws_ssh_public_key" {
  value = [for key in tls_private_key.aws_ssh_key : key.public_key_openssh]
}

output "aws_ssh_service_public_key" {
  value = tls_private_key.aws_ssh_service_key.public_key_openssh
}

output "aws_vnc_service_public_key" {
  value = tls_private_key.aws_vnc_service_key.public_key_openssh
}


# Used in main outputs.tf
output "aws_cloudflared_key_paths" {
  value = [for k in local_file.aws_private_key : k.filename]
}

# Used in main outputs.tf
output "aws_service_key_path" {
  value = local_file.aws_service_private_key.filename
}

# Used in main outputs.tf
output "aws_vnc_key_path" {
  value = local_file.aws_vnc_private_key.filename
}



#======================================
# Output: Azure key pairs
#======================================
output "azure_ssh_public_key" {
  value = [for key in tls_private_key.azure_ssh_key : key.public_key_openssh]
}

# Used in main outputs.tf
output "azure_key_paths" {
  value = [for k in local_file.azure_private_key : k.filename]
}
