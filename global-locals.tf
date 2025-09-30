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

  #==========================================================
  # Comprehensive Timeout Management System
  #==========================================================
  # Centralized timeout configuration for all cloud providers
  # and resource types to ensure consistency and maintainability
  #==========================================================

  # Base timeout configuration for different resource types
  base_timeouts = {
    # Standard VM instances (Linux, simple configurations)
    vm_standard = {
      create = "10m" # Standard VM creation time
      update = "5m"  # Most updates are configuration changes
      delete = "5m"  # VM deletion is usually quick
    }

    # Complex VM instances (Windows, GPU, large instances)
    vm_complex = {
      create = "15m" # Windows VMs and complex setups take longer
      update = "10m" # Complex updates may involve reboots
      delete = "5m"  # Deletion time is consistent
    }

    # Network resources (VPCs, subnets, security groups)
    network = {
      create = "5m" # Network resources create relatively quickly
      update = "3m" # Network updates are usually fast
      delete = "3m" # Network deletion is fast
    }

    # Storage resources (disks, volumes)
    storage = {
      create = "8m" # Storage provisioning can take time
      update = "5m" # Storage modifications
      delete = "5m" # Storage deletion
    }
  }

  # Cloud-specific timeout adjustments
  # Each cloud provider has different performance characteristics
  aws_timeouts = {
    # AWS EC2 instances (standard Linux VMs)
    vm = local.base_timeouts.vm_standard

    # AWS VNC instances (require desktop environment installation)
    vm_vnc = {
      create = "15m" # VNC setup with desktop environment takes longer
      update = "8m"  # VNC configuration updates
      delete = "5m"  # Standard deletion time
    }

    # AWS Cloudflared instances (lightweight)
    vm_cloudflared = local.base_timeouts.vm_standard

    # AWS network resources
    network = local.base_timeouts.network

    # AWS storage
    storage = local.base_timeouts.storage
  }

  gcp_timeouts = {
    # GCP Compute Engine instances
    vm = merge(local.base_timeouts.vm_standard, {
      create = "12m" # GCP can be slightly slower for complex setups
    })

    # GCP Windows instances (RDP-enabled)
    vm_windows = local.base_timeouts.vm_complex

    # GCP Cloudflared instances
    vm_cloudflared = local.base_timeouts.vm_standard

    # GCP WARP connector instances
    vm_warp = local.base_timeouts.vm_standard

    # GCP network resources
    network = local.base_timeouts.network

    # GCP storage
    storage = local.base_timeouts.storage
  }

  azure_timeouts = {
    # Azure VM instances
    vm = local.base_timeouts.vm_standard

    # Azure network resources
    network = local.base_timeouts.network

    # Azure storage
    storage = local.base_timeouts.storage
  }

  # Final timeout configurations (ready to use in resources)
  # These are the actual timeout values that should be used in resource definitions
  final_aws_timeouts = {
    vm             = local.aws_timeouts.vm
    vm_vnc         = local.aws_timeouts.vm_vnc
    vm_cloudflared = local.aws_timeouts.vm_cloudflared
    network        = local.aws_timeouts.network
    storage        = local.aws_timeouts.storage
  }

  final_gcp_timeouts = {
    vm             = local.gcp_timeouts.vm
    vm_windows     = local.gcp_timeouts.vm_windows
    vm_cloudflared = local.gcp_timeouts.vm_cloudflared
    vm_warp        = local.gcp_timeouts.vm_warp
    network        = local.gcp_timeouts.network
    storage        = local.gcp_timeouts.storage
  }

  final_azure_timeouts = {
    vm      = local.azure_timeouts.vm
    network = local.azure_timeouts.network
    storage = local.azure_timeouts.storage
  }
}
