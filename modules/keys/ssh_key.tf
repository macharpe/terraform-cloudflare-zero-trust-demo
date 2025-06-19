#==========================================================
# Local Variables
#==========================================================
locals {
  # Common SSH key configuration
  ssh_algorithm = "RSA"
  ssh_rsa_bits  = 4096

  # Flatten all SSH key requirements into a single map
  all_ssh_keys = merge(
    # GCP user keys
    {
      for user in var.gcp_users : "gcp_user_${user}" => {
        type        = "user"
        cloud       = "gcp"
        identifier  = user
        name_prefix = "gcp_ssh_${user}"
      }
    },
    # GCP VM keys  
    {
      for i in range(var.gcp_vm_count) : "gcp_vm_${i}" => {
        type        = "vm"
        cloud       = "gcp"
        identifier  = i
        name_prefix = "gcp_vm_key_pair_${i}"
      }
    },
    # AWS Cloudflared keys
    {
      for i in range(var.aws_cloudflared_count) : "aws_cloudflared_${i}" => {
        type        = "cloudflared"
        cloud       = "aws"
        identifier  = i
        name_prefix = "aws_ssh_cloudflared_key_pair_${i}"
      }
    },
    # AWS Service key
    {
      "aws_service" = {
        type        = "service"
        cloud       = "aws"
        identifier  = "service"
        name_prefix = "aws_ssh_service_key_pair"
      }
    },
    # AWS VNC key
    {
      "aws_vnc" = {
        type        = "vnc"
        cloud       = "aws"
        identifier  = "vnc"
        name_prefix = "aws_vnc_service_key_pair"
      }
    },
    # Azure VM keys
    {
      for i in range(var.azure_vm_count) : "azure_vm_${i}" => {
        type        = "vm"
        cloud       = "azure"
        identifier  = i
        name_prefix = "azure_ssh_key_pair_${i}"
      }
    }
  )
}

#==========================================================
# SSH Key Generation
#==========================================================
resource "tls_private_key" "ssh_keys" {
  for_each = local.all_ssh_keys

  algorithm = local.ssh_algorithm
  rsa_bits  = local.ssh_rsa_bits
}

#==========================================================
# File Generation - Private Keys
#==========================================================
resource "local_file" "private_keys" {
  for_each = local.all_ssh_keys

  content         = tls_private_key.ssh_keys[each.key].private_key_pem
  filename        = "${path.module}/out/${each.value.name_prefix}"
  file_permission = "0600"
}

#==========================================================
# File Generation - Public Keys
#==========================================================
resource "local_file" "public_keys" {
  for_each = local.all_ssh_keys

  content         = tls_private_key.ssh_keys[each.key].public_key_openssh
  filename        = "${path.module}/out/${each.value.name_prefix}.pub"
  file_permission = "0600"
}
