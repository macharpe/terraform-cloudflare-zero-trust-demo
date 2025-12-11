#==========================================================
# Load Balancing Demo - GCP Compute Instance (On-Prem)
# VM Name: cloudflare-lb-demo-onprem-gcp
#==========================================================
# This file creates a GCP Compute instance for the Load Balancing demo.
# The VM runs nginx serving the Swiss Insurance website and is
# connected to Cloudflare via a cloudflared tunnel.
# This instance simulates an "on-premises" environment.
#
# To remove: Delete this file and run terraform apply
#==========================================================

#==========================================================
# GCP Subnet for LB Demo (reuse existing cloudflared subnet)
#==========================================================
# Using existing google_compute_subnetwork.gcp_subnet_cloudflared

#==========================================================
# GCP Compute Instance: Load Balancing Demo - On-Prem
#==========================================================
resource "google_compute_instance" "gcp_vm_lb_demo" {
  count        = var.lb_demo_enabled ? 1 : 0
  name         = var.lb_gcp_vm_name
  machine_type = var.gcp_machine_size
  zone         = local.common_gcp_config.zone

  boot_disk {
    initialize_params {
      image = local.common_linux_boot_disk.image
    }
  }

  network_interface {
    network    = local.common_gcp_config.network
    subnetwork = google_compute_subnetwork.gcp_subnet_cloudflared.id
    # No external IP - uses Cloud NAT for outbound
  }

  # Preemptible for cost savings (demo environment)
  scheduling {
    preemptible       = local.preemptible_scheduling.preemptible
    automatic_restart = local.preemptible_scheduling.automatic_restart
  }

  timeouts {
    create = local.final_gcp_timeouts.vm_cloudflared.create
    update = local.final_gcp_timeouts.vm_cloudflared.update
    delete = local.final_gcp_timeouts.vm_cloudflared.delete
  }

  tags = ["lb-demo-instances", "infrastructure-access-instances"]

  metadata = merge(local.common_metadata_vars, {
    ssh-keys = "${var.gcp_vm_default_user}:${module.ssh_keys.gcp_lb_demo_public_key}"

    user-data = templatefile("${path.module}/scripts/cloud-init/gcp-lb-init.tftpl", {
      hostname             = var.lb_gcp_vm_name
      lb_web_port          = var.lb_web_port
      tunnel_token         = module.cloudflare.lb_gcp_tunnel_token
      swiss_insurance_html = file("${path.module}/scripts/html/swiss-insurance.html")
      datadog_api_key      = var.datadog_api_key
      datadog_region       = var.datadog_region
    })
  })
}

#==========================================================
# Firewall Rule for LB Demo HTTP Traffic
#==========================================================
resource "google_compute_firewall" "gcp_fw_lb_demo_http" {
  count   = var.lb_demo_enabled ? 1 : 0
  name    = "allow-http-lb-demo"
  network = google_compute_network.gcp_vpc_main.name

  direction = "INGRESS"
  priority  = 850

  allow {
    protocol = "tcp"
    ports    = [tostring(var.lb_web_port)]
  }

  # Allow from within the VPC (cloudflared tunnel traffic)
  source_ranges = [var.gcp_infra_cidr]
  target_tags   = ["lb-demo-instances"]
}
