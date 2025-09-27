# My IP
output "MY_IP" {
  description = "This is your Public IP"
  value = {
    IPv4 = data.http.my_ip.response_body
  }
}

# GCP
output "GCP_COMPUTE_INSTANCES" {
  description = "GCP instance details"
  value = concat(
    [
      {
        name        = google_compute_instance.gcp_vm_cloudflared.name
        internal_ip = google_compute_instance.gcp_vm_cloudflared.network_interface[0].network_ip
        public_ip   = google_compute_address.cloud_nat_ip.address
        tunnel = {
          cf_tunnel_id     = module.cloudflare.gcp_tunnel_id
          cf_tunnel_status = module.cloudflare.gcp_tunnel_status
        }
      }
    ],
    [
      for idx, instance in google_compute_instance.gcp_vm_warp :
      {
        name        = instance.name
        internal_ip = instance.network_interface[0].network_ip
        public_ip   = google_compute_address.cloud_nat_ip.address
        ssh         = "ssh ${var.gcp_vm_default_user}@${idx == 0 ? "warp_ip" : instance.network_interface[0].network_ip} -i ${module.ssh_keys.gcp_vm_key_paths[idx]}"
      }
    ],
    [
      {
        name                 = google_compute_instance.gcp_vm_windows_rdp.name
        gcp_windows_username = var.gcp_windows_user_name
        internal_ip          = google_compute_instance.gcp_vm_windows_rdp.network_interface[0].network_ip
        public_ip            = google_compute_address.cloud_nat_ip.address
        ssh                  = "ssh -o PubkeyAuthentication=no ${var.gcp_windows_user_name}@${google_compute_instance.gcp_vm_windows_rdp.network_interface[0].network_ip}"
        tunnel = {
          cf_tunnel_id     = module.cloudflare.gcp_windows_rdp_tunnel_id
          cf_tunnel_status = module.cloudflare.gcp_windows_rdp_tunnel_status
        }
      }
    ]
  )
}


# AWS
output "AWS_EC2_INSTANCES" {
  description = "AWS instance details"
  value = concat(
    [for idx, instance in aws_instance.aws_vm_cloudflared : {
      tunnel = {
        cf_tunnel_id     = module.cloudflare.aws_tunnel_id
        cf_tunnel_status = module.cloudflare.aws_tunnel_status
      }
      name          = "${var.aws_ec2_cloudflared_name}-${idx}"
      internal_ip   = instance.private_ip
      public_ip_nat = aws_eip.nat_eip.public_ip
      ssh           = "ssh ${var.aws_vm_default_user}@${instance.private_ip} -i ${module.ssh_keys.aws_cloudflared_key_paths[idx]}"
    }],
    [{
      name          = var.aws_ec2_browser_ssh_name
      internal_ip   = aws_instance.aws_vm_service.private_ip
      public_ip_nat = aws_eip.nat_eip.public_ip
      ssh           = "ssh ${var.aws_vm_default_user}@${aws_instance.aws_vm_service.private_ip} -i ${module.ssh_keys.aws_service_key_path}"
    }],
    [{
      name          = var.aws_ec2_browser_vnc_name
      internal_ip   = aws_instance.aws_vm_vnc.private_ip
      public_ip_nat = aws_eip.nat_eip.public_ip
      ssh           = "ssh ${var.aws_vm_default_user}@${aws_instance.aws_vm_vnc.private_ip} -i ${module.ssh_keys.aws_vnc_key_path}"
    }]
  )
}

output "AZURE_VMS" {
  description = "Azure instance details"
  value = {
    for idx in toset(range(var.azure_vm_count)) :
    "${tonumber(idx) == 0 ? var.azure_warp_vm_name : var.azure_vm_name}-${idx}" => {
      internal_ip = azurerm_network_interface.nic[idx].private_ip_address
      public_ip   = azurerm_public_ip.nat_gateway_public_ip.ip_address
      public_dns  = "${tonumber(idx) == 0 ? var.azure_warp_vm_name : var.azure_vm_name}-${idx}.${var.azure_public_dns_domain}"
      ssh         = "ssh ${var.azure_vm_admin_username}@${tonumber(idx) == 0 ? "warp_ip" : azurerm_network_interface.nic[idx].private_ip_address} -i ${module.ssh_keys.azure_key_paths[idx]}"
    }
  }
  depends_on = [azurerm_linux_virtual_machine.azure_vm_linux]
}


# SSH COMMAND
output "SSH_FOR_INFRASTRUCTURE_ACCESS" {
  description = "SSH with Access for Infrastructure command"
  value = {
    for username in var.gcp_users :
    username => "ssh ${username}@${google_compute_instance.gcp_vm_cloudflared.network_interface[0].network_ip}"
  }
}

# Training Status Admin Portal Application Audience (AUD) Tag
output "TRAINING_STATUS_ADMIN_PORTAL_AUD" {
  description = "Application Audience (AUD) Tag for the Training Status Admin Portal - use this value for ACCESS_APP_AUD in your worker"
  value       = module.cloudflare.training_status_admin_portal_aud
}
