#==========================================================
# Load Balancing Demo - Cloudflare Tunnels
#==========================================================
# This file creates Cloudflare tunnels for the Load Balancing demo.
# Two tunnels are created: AWS (DC1) and GCP (On-Prem).
#
# To remove: Delete this file and run terraform apply
#==========================================================

#==========================================================
# Local Variables for LB Tunnels
#==========================================================
locals {
  # LB Tunnel configurations (conditional)
  lb_tunnels = var.lb_demo_enabled ? {
    lb_aws_dc1 = {
      name = var.lb_tunnel_name_aws
    }
    lb_gcp_onprem = {
      name = var.lb_tunnel_name_gcp
    }
    lb_azure_dr = {
      name = var.lb_tunnel_name_azure
    }
  } : {}
}

#==========================================================
# Cloudflare Tunnels for LB Demo
#==========================================================
resource "cloudflare_zero_trust_tunnel_cloudflared" "lb_tunnels" {
  for_each = local.lb_tunnels

  account_id = var.cloudflare_account_id
  name       = each.value.name
  config_src = "cloudflare"
}

#==========================================================
# Tunnel Tokens for LB Demo
#==========================================================
data "cloudflare_zero_trust_tunnel_cloudflared_token" "lb_tunnel_tokens" {
  for_each = local.lb_tunnels

  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.lb_tunnels[each.key].id
}

#==========================================================
# Tunnel Configurations - Public Hostnames for LB Demo
#==========================================================

# AWS DC1 Tunnel Configuration
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "lb_aws_config" {
  count = var.lb_demo_enabled ? 1 : 0

  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.lb_tunnels["lb_aws_dc1"].id

  config = {
    ingress = [
      {
        hostname = "${var.lb_subdomain}.${var.cf_domain}"
        service  = "http://localhost:${var.lb_web_port}"
        # No access control - public website for demo
      },
      {
        service = "http_status:404"
      }
    ]
  }
}

# GCP On-Prem Tunnel Configuration
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "lb_gcp_config" {
  count = var.lb_demo_enabled ? 1 : 0

  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.lb_tunnels["lb_gcp_onprem"].id

  config = {
    ingress = [
      {
        hostname = "${var.lb_subdomain}.${var.cf_domain}"
        service  = "http://localhost:${var.lb_web_port}"
        # No access control - public website for demo
      },
      {
        service = "http_status:404"
      }
    ]
  }
}

# Azure DR Tunnel Configuration
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "lb_azure_config" {
  count = var.lb_demo_enabled ? 1 : 0

  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.lb_tunnels["lb_azure_dr"].id

  config = {
    ingress = [
      {
        hostname = "${var.lb_subdomain}.${var.cf_domain}"
        service  = "http://localhost:${var.lb_web_port}"
        # No access control - public website for demo
      },
      {
        service = "http_status:404"
      }
    ]
  }
}
