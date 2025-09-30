#==========================================================
# GCP Network
#==========================================================
resource "google_compute_network" "gcp_vpc_main" {
  name                    = "zero-trust-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gcp_subnet_cloudflared" {
  name          = "zero-trust-cloudflared-subnet"
  ip_cidr_range = var.gcp_infra_cidr
  region        = var.gcp_region
  network       = google_compute_network.gcp_vpc_main.id
}

resource "google_compute_subnetwork" "gcp_subnet_warp" {
  name          = "zero-trust-warp-subnet"
  ip_cidr_range = var.gcp_warp_cidr
  region        = var.gcp_region
  network       = google_compute_network.gcp_vpc_main.id
}

resource "google_compute_subnetwork" "gcp_subnet_windows_rdp" {
  name          = "zero-trust-cloudflared-windows-rdp-subnet"
  ip_cidr_range = var.gcp_windows_rdp_cidr
  region        = var.gcp_region
  network       = google_compute_network.gcp_vpc_main.id
}

# Default route to internet gateway (REQUIRED)
resource "google_compute_route" "default_route" {
  name             = "egress-internet"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.gcp_vpc_main.name
  next_hop_gateway = "default-internet-gateway"
}



#==========================================================
# GCP Cloud NAT
#==========================================================
# pre-creating one  google_compute_address resources (static external IP addresses)
resource "google_compute_address" "cloud_nat_ip" {
  name   = "cloud-nat-static-ip"
  region = var.gcp_region
}

# Create a Cloud Router in the same region as your subnets
resource "google_compute_router" "cloud_router" {
  name    = "zero-trust-cloud-router"
  network = google_compute_network.gcp_vpc_main.id
  region  = var.gcp_region
}

# Create a Cloud NAT gateway attached to the Cloud Router
resource "google_compute_router_nat" "cloud_nat" {
  name   = "zero-trust-cloud-nat"
  router = google_compute_router.cloud_router.name
  region = var.gcp_region

  # Automatically allocate external IPs for NAT
  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = [google_compute_address.cloud_nat_ip.self_link]

  # Specify that NAT applies only to explicitly listed subnetworks
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  # List the subnetworks to NAT, with all IP ranges included
  subnetwork {
    name                    = google_compute_subnetwork.gcp_subnet_cloudflared.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  subnetwork {
    name                    = google_compute_subnetwork.gcp_subnet_warp.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  subnetwork {
    name                    = google_compute_subnetwork.gcp_subnet_windows_rdp.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  # Enable logging for NAT translations (optional but recommended)
  log_config {
    enable = true
    filter = "ALL"
  }
}



#==========================================================
# Local Values for GCP Instance Configuration
#==========================================================
locals {
  # Common GCP instance configuration
  common_gcp_config = {
    zone    = "${var.gcp_region}-a"
    network = google_compute_network.gcp_vpc_main.id
  }

  # Common Linux boot disk configuration
  common_linux_boot_disk = {
    image = var.gcp_linux_image
  }

  # Common metadata variables
  common_metadata_vars = {
    enable-oslogin = var.gcp_enable_oslogin
  }

  # Common user-data template variables for GCP
  gcp_common_user_data_vars = merge(local.global_monitoring, local.global_cloudflare, {
    tunnel_secret_gcp      = module.cloudflare.gcp_extracted_token
    gateway_ca_certificate = module.cloudflare.gateway_ca_certificate
    warp_token             = module.cloudflare.gcp_extracted_warp_token
    intranet_html          = file("${path.module}/scripts/html/intranet.html")
    competition_html       = file("${path.module}/scripts/html/competition.html")
  })

  # Common scheduling for preemptible instances
  preemptible_scheduling = {
    preemptible       = true
    automatic_restart = false
  }

  # Common scheduling for standard instances
  standard_scheduling = {
    preemptible         = false
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    provisioning_model  = "STANDARD"
  }
}

#==========================================================
# GCP INSTANCE RUNNING CLOUDFLARED: Infrastructure Access
#==========================================================
resource "google_compute_instance" "gcp_vm_cloudflared" {
  name         = var.gcp_cloudflared_vm_name
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
  }

  # Optional config to make instance ephemeral 
  scheduling {
    preemptible       = local.preemptible_scheduling.preemptible
    automatic_restart = local.preemptible_scheduling.automatic_restart
  }

  timeouts {
    create = local.final_gcp_timeouts.vm_cloudflared.create
    update = local.final_gcp_timeouts.vm_cloudflared.update
    delete = local.final_gcp_timeouts.vm_cloudflared.delete
  }

  tags = ["infrastructure-access-instances"]

  metadata = merge(local.common_metadata_vars, {
    ssh-keys = join("\n", [
      for username in var.gcp_users :
      "${username}:${module.ssh_keys.gcp_public_keys[username]}"
    ])

    user-data = templatefile("${path.module}/scripts/cloud-init/gcp-init.tpl", merge(local.gcp_common_user_data_vars, {
      role = "cloudflared"
    }))
  })
}


#==========================================================
# GCP INSTANCE RUNNING CLOUDFLARED: Windows RDP Server
#==========================================================
resource "google_compute_instance" "gcp_vm_windows_rdp" {
  name         = var.gcp_windows_rdp_vm_name
  machine_type = var.gcp_windows_machine_size
  zone         = local.common_gcp_config.zone

  boot_disk {
    initialize_params {
      image = var.gcp_windows_image
      size  = 50
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = local.common_gcp_config.network
    subnetwork = google_compute_subnetwork.gcp_subnet_windows_rdp.id
  }

  scheduling {
    preemptible         = local.standard_scheduling.preemptible
    automatic_restart   = local.standard_scheduling.automatic_restart
    on_host_maintenance = local.standard_scheduling.on_host_maintenance
    provisioning_model  = local.standard_scheduling.provisioning_model
  }

  timeouts {
    create = local.final_gcp_timeouts.vm_windows.create
    update = local.final_gcp_timeouts.vm_windows.update
    delete = local.final_gcp_timeouts.vm_windows.delete
  }

  service_account {
    email  = var.gcp_service_account_email
    scopes = ["cloud-platform"]
  }

  tags = ["infrastructure-access-instances"]

  metadata = {
    enable-osconfig    = "TRUE"
    enable-core-plugin = "FALSE"

    windows-startup-script-cmd = templatefile("${path.module}/scripts/cloud-init/gcp-windows-rdp-init.cmd", {
      user_name                 = var.gcp_windows_user_name
      admin_password            = var.gcp_windows_admin_password
      tunnel_secret_windows_gcp = module.cloudflare.gcp_windows_extracted_token
      intranet_app_port         = var.cf_intranet_app_port
      competition_app_port      = var.cf_competition_app_port
      datadog_api_key           = var.datadog_api_key
      datadog_region            = var.datadog_region
    })
  }
}


#==========================================================
# GCP INSTANCES NOT RUNNING CLOUDFLARED
#==========================================================
resource "google_compute_instance" "gcp_vm_warp" {
  count        = var.gcp_vm_count
  name         = count.index == 0 ? "${var.gcp_warp_connector_vm_name}-${count.index}" : "${var.gcp_vm_name}-${count.index}"
  machine_type = var.gcp_machine_size
  zone         = local.common_gcp_config.zone

  boot_disk {
    initialize_params {
      # Use Ubuntu 22.04 for WARP connector (index 0), Ubuntu 24.04 for others
      image = count.index == 0 ? var.gcp_warp_connector_image : local.common_linux_boot_disk.image
    }
  }

  network_interface {
    network    = local.common_gcp_config.network
    subnetwork = google_compute_subnetwork.gcp_subnet_warp.id
    #    access_config {}
  }

  can_ip_forward = count.index == 0 ? true : false

  scheduling {
    preemptible       = local.preemptible_scheduling.preemptible
    automatic_restart = local.preemptible_scheduling.automatic_restart
  }

  timeouts {
    create = local.final_gcp_timeouts.vm_warp.create
    update = local.final_gcp_timeouts.vm_warp.update
    delete = local.final_gcp_timeouts.vm_warp.delete
  }

  tags = ["warp-instances"]

  metadata = merge(local.common_metadata_vars, {
    ssh-keys = "${var.gcp_vm_default_user}:${module.ssh_keys.gcp_vm_key[count.index]}"
    ROLE     = count.index == 0 ? "warp_connector" : "default"

    user-data = templatefile("${path.module}/scripts/cloud-init/gcp-init.tpl", merge(local.gcp_common_user_data_vars, {
      role = count.index == 0 ? "warp_connector" : "default"
    }))
  })
}




#==========================================================
# Routing Setup for WARP Connector
#==========================================================
resource "google_compute_route" "route_to_warp_subnet" {
  name       = "route-to-warp-subnet"
  network    = google_compute_network.gcp_vpc_main.name
  dest_range = var.cf_warp_cgnat_cidr

  next_hop_instance      = google_compute_instance.gcp_vm_warp[0].self_link
  next_hop_instance_zone = google_compute_instance.gcp_vm_warp[0].zone

  priority = 1000
}

resource "google_compute_route" "route_to_azure_subnet" {
  name       = "route-to-azure-subnet"
  network    = google_compute_network.gcp_vpc_main.name
  dest_range = var.azure_subnet_cidr

  next_hop_instance      = google_compute_instance.gcp_vm_warp[0].self_link
  next_hop_instance_zone = google_compute_instance.gcp_vm_warp[0].zone

  priority = 1000
}

resource "google_compute_route" "route_to_aws_subnet" {
  name       = "route-to-aws-subnet"
  network    = google_compute_network.gcp_vpc_main.name
  dest_range = var.aws_private_cidr

  next_hop_instance      = google_compute_instance.gcp_vm_warp[0].self_link
  next_hop_instance_zone = google_compute_instance.gcp_vm_warp[0].zone

  priority = 1000
}


#==========================================================
# GCP FIREWALL
#==========================================================
# Create a firewall rule to deny SSH from the internet

# Allow SSH only from my ip
resource "google_compute_firewall" "gcp_fw_ingress_ssh" {
  name    = "allow-ssh-from-my-ip"
  network = google_compute_network.gcp_vpc_main.name

  direction = "INGRESS"
  priority  = 900

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.cf_warp_cgnat_cidr]
  target_tags   = ["infrastructure-access-instances", "warp-instances"]
}


# Allow PING only from my ip
resource "google_compute_firewall" "gcp_fw_ingress_icmp" {
  name    = "allow-icmp-from-any"
  network = google_compute_network.gcp_vpc_main.name

  direction = "INGRESS"
  priority  = 901

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.cf_warp_cgnat_cidr, var.azure_subnet_cidr]
  target_tags   = ["infrastructure-access-instances", "warp-instances"]
}


# Delete default SSH rule first (if exists)
resource "google_compute_firewall" "gcp_fw_ingress_ssh_deny" {
  name    = "deny-all-external-ssh-zero-trust-vpc"
  network = google_compute_network.gcp_vpc_main.name

  direction = "INGRESS"
  priority  = 1000

  deny {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["infrastructure-access-instances"]
}


# Block ALL outbound SSH to prevent lateral movement
resource "google_compute_firewall" "gcp_fw_egress_ssh_deny" {
  name    = "deny-egress-ssh"
  network = google_compute_network.gcp_vpc_main.name

  direction = "EGRESS"
  priority  = 800 # Must be higher priority than any allow rules for SSH egress

  deny {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Applies to all destinations (block SSH to any IP)
  destination_ranges = ["0.0.0.0/0"]
  target_tags        = ["infrastructure-access-instances"]
}

resource "google_compute_firewall" "gcp_fw_egress_all" {
  name    = "allow-all-egress"
  network = google_compute_network.gcp_vpc_main.name

  direction = "EGRESS"
  priority  = 900

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
  target_tags        = ["infrastructure-access-instances", "warp-instances"]
}
