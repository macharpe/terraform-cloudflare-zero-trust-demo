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
    cf_warp_cgnat_cidr      = var.cf_warp_cgnat_cidr
    aws_private_subnet_cidr = var.aws_private_subnet_cidr
    azure_address_prefixes  = var.azure_address_prefixes
    gcp_ip_cidr_warp        = var.gcp_ip_cidr_warp
  }

  # Common Cloudflare configuration
  global_cloudflare = {
    admin_web_app_port     = var.cf_admin_web_app_port
    sensitive_web_app_port = var.cf_sensitive_web_app_port
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
