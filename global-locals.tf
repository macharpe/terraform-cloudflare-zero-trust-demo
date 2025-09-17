#==========================================================
# Global Local Values for Cross-Cloud Configuration
#==========================================================
# This file contains shared configuration values that are
# used across multiple cloud providers (AWS, GCP, Azure)
#==========================================================

locals {
  # Common monitoring and observability configuration
  global_monitoring = {
    datadog_api_key = var.datadog_api_key
    datadog_region  = var.datadog_region
  }

  # Common network configuration for cross-cloud connectivity
  global_network = {
    cf_warp_cgnat_cidr = var.cf_warp_cgnat_cidr
    aws_private_cidr   = var.aws_private_cidr
    azure_subnet_cidr  = var.azure_subnet_cidr
    gcp_warp_cidr      = var.gcp_warp_cidr
  }

  # Common Cloudflare configuration
  global_cloudflare = {
    intranet_app_port    = var.cf_intranet_app_port
    competition_app_port = var.cf_competition_app_port
  }

  # Common OKTA configuration for contractor access
  global_okta = {
    okta_contractor_username = split("@", var.okta_bob_user_login)[0]
    okta_contractor_password = var.okta_bob_user_linux_password
  }

  # Common security configuration
  global_security = {
    vnc_password = var.aws_vnc_password # Used across clouds for VNC access
  }

  # Common user management
  global_users = {
    aws_users = var.aws_users
    gcp_users = var.gcp_users
  }
}
