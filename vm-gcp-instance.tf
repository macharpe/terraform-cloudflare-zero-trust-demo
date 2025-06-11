#==========================================================
# GCP Network
#==========================================================
resource "google_compute_network" "gcp_custom_vpc" {
  name                    = "zero-trust-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gcp_cloudflared_subnet" {
  name          = "zero-trust-cloudflared-subnet"
  ip_cidr_range = var.gcp_ip_cidr_infra
  region        = var.gcp_region
  network       = google_compute_network.gcp_custom_vpc.id
}

resource "google_compute_subnetwork" "gcp_warp_subnet" {
  name          = "zero-trust-warp-subnet"
  ip_cidr_range = var.gcp_ip_cidr_warp
  region        = var.gcp_region
  network       = google_compute_network.gcp_custom_vpc.id
}

resource "google_compute_subnetwork" "gcp_cloudflared_windows_rdp_subnet" {
  name          = "zero-trust-cloudflared-windows-rdp-subnet"
  ip_cidr_range = var.gcp_ip_cidr_windows_rdp
  region        = var.gcp_region
  network       = google_compute_network.gcp_custom_vpc.id
}

# Default route to internet gateway (REQUIRED)
resource "google_compute_route" "default_route" {
  name             = "egress-internet"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.gcp_custom_vpc.name
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
  network = google_compute_network.gcp_custom_vpc.id
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
    name                    = google_compute_subnetwork.gcp_cloudflared_subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  subnetwork {
    name                    = google_compute_subnetwork.gcp_warp_subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  subnetwork {
    name                    = google_compute_subnetwork.gcp_cloudflared_windows_rdp_subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  # Enable logging for NAT translations (optional but recommended)
  log_config {
    enable = true
    filter = "ALL"
  }
}



#==========================================================
# GCP INSTANCE RUNNING CLOUDFLARED: Infrastructure Access
#==========================================================
resource "google_compute_instance" "gcp_cloudflared_vm_instance" {
  name         = var.gcp_cloudflared_instance_name
  machine_type = var.gcp_machine_size
  zone         = "${var.gcp_region}-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network    = google_compute_network.gcp_custom_vpc.id
    subnetwork = google_compute_subnetwork.gcp_cloudflared_subnet.id
  }

  // Optional config to make instance ephemeral 
  scheduling {
    preemptible       = true
    automatic_restart = false
  }

  tags = ["infrastructure-access-instances"]

  metadata = {
    ssh-keys = join("\n", [
      for username in var.gcp_users :
      "${username}:${module.ssh_keys.gcp_public_keys[username]}"
    ])

    enable-oslogin = var.gcp_enable_oslogin

    user-data = templatefile("${path.module}/scripts/gcp-cloudflared-init.tpl", {
      tunnel_name            = var.cf_tunnel_name_gcp
      account_id             = var.cloudflare_account_id
      cloudflare_domain      = var.cf_subdomain_ssh
      tunnel_secret_gcp      = module.cloudflare.gcp_extracted_token
      gateway_ca_certificate = module.cloudflare.gateway_ca_certificate
      datadog_api_key        = var.datadog_api_key
      datadog_region         = var.datadog_region
      admin_web_app_port     = var.cf_administration_web_app_port
      sensitive_web_app_port = var.cf_sensitive_web_app_port
    })
  }
}


#==========================================================
# GCP INSTANCE RUNNING CLOUDFLARED: Windows RDP Server
#==========================================================
resource "google_compute_instance" "gcp_windows_rdp_server" {
  name         = var.gcp_cloudflared_windows_rdp_name
  machine_type = var.gcp_windows_machine_size
  zone         = "${var.gcp_region}-a"

  boot_disk {
    initialize_params {
      image = "windows-server-2016-dc-v20250516"
      size  = 50
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.gcp_custom_vpc.id
    subnetwork = google_compute_subnetwork.gcp_cloudflared_windows_rdp_subnet.id
  }

  scheduling {
    preemptible         = false
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    provisioning_model  = "STANDARD"
  }

  service_account {
    email  = var.gcp_service_account_email
    scopes = ["cloud-platform"]
  }

  tags = ["rdp-server", "infrastructure-access-instances"]

  metadata = {
    enable-osconfig    = "TRUE"
    enable-core-plugin = "FALSE"

    windows-startup-script-cmd = templatefile("${path.module}/scripts/gcp-windows-rdp-init.cmd", {
      user_name                 = var.gcp_windows_user_name
      admin_password            = var.gcp_windows_admin_password
      tunnel_secret_windows_gcp = module.cloudflare.gcp_windows_extracted_token
    })
  }
}

#==========================================================
# GCP INSTANCES NOT RUNNING CLOUDFLARED
#==========================================================
resource "google_compute_instance" "gcp_vm_instance" {
  count        = var.gcp_vm_count
  name         = count.index == 0 ? "${var.gcp_warp_connector_vm_name}-${count.index}" : "${var.gcp_vm_name}-${count.index}"
  machine_type = var.gcp_machine_size
  zone         = "${var.gcp_region}-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network    = google_compute_network.gcp_custom_vpc.id
    subnetwork = google_compute_subnetwork.gcp_warp_subnet.id
    #    access_config {}
  }

  can_ip_forward = count.index == 0 ? true : false

  scheduling {
    preemptible       = true
    automatic_restart = false
  }

  tags = ["warp-instances"]

  metadata = {
    ssh-keys = "${var.gcp_vm_default_user}:${module.ssh_keys.gcp_vm_key[count.index]}"

    enable-oslogin = var.gcp_enable_oslogin

    ROLE = count.index == 0 ? "warp_connector" : "default"

    user-data = templatefile("${path.module}/scripts/gcp-vm-init.tpl", {
      role            = count.index == 0 ? "warp_connector" : "default"
      warp_token      = module.cloudflare.gcp_extracted_warp_token
      datadog_api_key = var.datadog_api_key
      datadog_region  = var.datadog_region
      timezone        = "Europe/Paris"
    })
  }
}




#==========================================================
# Routing Setup for WARP Connector
#==========================================================
resource "google_compute_route" "route_to_warp_subnet" {
  name       = "route-to-warp-subnet"
  network    = google_compute_network.gcp_custom_vpc.name
  dest_range = var.cf_warp_cgnat_cidr

  next_hop_instance      = google_compute_instance.gcp_vm_instance[0].self_link
  next_hop_instance_zone = google_compute_instance.gcp_vm_instance[0].zone

  priority = 1000
}

resource "google_compute_route" "route_to_azure_subnet" {
  name       = "route-to-azure-subnet"
  network    = google_compute_network.gcp_custom_vpc.name
  dest_range = var.azure_address_prefixes

  next_hop_instance      = google_compute_instance.gcp_vm_instance[0].self_link
  next_hop_instance_zone = google_compute_instance.gcp_vm_instance[0].zone

  priority = 1000
}

resource "google_compute_route" "route_to_aws_subnet" {
  name       = "route-to-aws-subnet"
  network    = google_compute_network.gcp_custom_vpc.name
  dest_range = var.aws_private_subnet_cidr

  next_hop_instance      = google_compute_instance.gcp_vm_instance[0].self_link
  next_hop_instance_zone = google_compute_instance.gcp_vm_instance[0].zone

  priority = 1000
}


#==========================================================
# GCP FIREWALL
#==========================================================
# Create a firewall rule to deny SSH from the internet

# Allow SSH only from my ip
resource "google_compute_firewall" "allow_ssh_from_my_ip" {
  name    = "allow-ssh-from-my-ip"
  network = google_compute_network.gcp_custom_vpc.name

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
resource "google_compute_firewall" "allow_icmp_from_any" {
  name    = "allow-icmp-from-any"
  network = google_compute_network.gcp_custom_vpc.name

  direction = "INGRESS"
  priority  = 901

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.cf_warp_cgnat_cidr, var.azure_address_prefixes]
  target_tags   = ["infrastructure-access-instances", "warp-instances"]
}


# Delete default SSH rule first (if exists)
resource "google_compute_firewall" "default_ssh_deny" {
  name    = "deny-all-external-ssh-zero-trust-vpc"
  network = google_compute_network.gcp_custom_vpc.name

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
resource "google_compute_firewall" "deny_egress_ssh" {
  name    = "deny-egress-ssh"
  network = google_compute_network.gcp_custom_vpc.name

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

resource "google_compute_firewall" "allow_egress" {
  name    = "allow-all-egress"
  network = google_compute_network.gcp_custom_vpc.name

  direction = "EGRESS"
  priority  = 900

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
  target_tags        = ["infrastructure-access-instances", "warp-instances"]
}

# Firewall Rule for RDP Access
resource "google_compute_firewall" "allow_rdp_from_my-ip" {
  name    = "allow-rdp-from-my-ip"
  network = google_compute_network.gcp_custom_vpc.name

  direction = "INGRESS"
  priority  = 900

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  # Allow from any IP - change to specific IPs for better security
  source_ranges = [var.cf_warp_cgnat_cidr]
  target_tags   = ["rdp-server"]
}
