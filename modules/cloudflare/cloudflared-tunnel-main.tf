#==========================================================
# Local Variables
#==========================================================
locals {
  # Certificate data
  gateway_ca_certificate = jsondecode(data.http.short_lived_cloudflare_ssh_ca.response_body)

  # WARP connector tokens
  azure_warp_connector_token = jsondecode(data.http.cloudflare_warp_connector_token_azure.response_body).result
  gcp_warp_connector_token   = jsondecode(data.http.cloudflare_warp_connector_token_gcp.response_body).result

  # Tunnel configurations
  tunnels = {
    gcp_infrastructure = {
      name = var.cf_tunnel_name_gcp
      routes = [
        {
          comment = "Route making GCP subnet available in the Cloudflare network"
          network = var.gcp_infra_cidr
        }
      ]
      public_hostnames = [
        {
          hostname = var.cf_subdomain_web
          service  = "http://localhost:${var.cf_admin_web_app_port}"
          aud_tag  = "administration_web_app"
        },
        {
          hostname = var.cf_subdomain_web_sensitive
          service  = "http://localhost:${var.cf_sensitive_web_app_port}"
          aud_tag  = "sensitive_web_server"
        }
      ]
    }
    gcp_windows_rdp = {
      name = var.cf_windows_rdp_tunnel_name_gcp
      routes = [
        {
          comment = "Route making GCP Windows RDP subnet available in the Cloudflare network"
          network = var.gcp_windows_rdp_cidr
        }
      ]
    }
    aws_browser_rendering = {
      name = var.cf_tunnel_name_aws
      routes = [
        {
          comment = "Route making AWS private subnet available in the Cloudflare network"
          network = var.aws_private_cidr
        }
      ]
    }
  }

  # HTTP request headers for API calls
  cloudflare_api_headers = {
    "X-Auth-Email" = var.cloudflare_email
    "X-Auth-Key"   = var.cloudflare_api_key
    "Content-Type" = "application/json"
  }
}

#==========================================================
# Data Sources
#==========================================================
data "http" "short_lived_cloudflare_ssh_ca" {
  url             = "https://api.cloudflare.com/client/v4/accounts/${var.cloudflare_account_id}/access/gateway_ca"
  request_headers = local.cloudflare_api_headers
}

data "http" "cloudflare_warp_connector_token_azure" {
  url             = "https://api.cloudflare.com/client/v4/accounts/${var.cloudflare_account_id}/warp_connector/${var.cf_tunnel_warp_connector_azure_id}/token"
  request_headers = local.cloudflare_api_headers
}

data "http" "cloudflare_warp_connector_token_gcp" {
  url             = "https://api.cloudflare.com/client/v4/accounts/${var.cloudflare_account_id}/warp_connector/${var.cf_tunnel_warp_connector_gcp_id}/token"
  request_headers = local.cloudflare_api_headers
}

#==========================================================
# Cloudflare Tunnels
#==========================================================
resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnels" {
  for_each = local.tunnels

  account_id = var.cloudflare_account_id
  name       = each.value.name
  config_src = "cloudflare"
}

#==========================================================
# Tunnel Tokens
#==========================================================
data "cloudflare_zero_trust_tunnel_cloudflared_token" "tunnel_tokens" {
  for_each = local.tunnels

  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnels[each.key].id
}

#==========================================================
# Private Network Routes
#==========================================================
resource "cloudflare_zero_trust_tunnel_cloudflared_route" "routes" {
  for_each = {
    for route_key, route in flatten([
      for tunnel_key, tunnel in local.tunnels : [
        for route_idx, route in tunnel.routes : {
          key     = "${tunnel_key}_${route_idx}"
          tunnel  = tunnel_key
          comment = route.comment
          network = route.network
        }
      ]
    ]) : route.key => route
  }

  account_id = var.cloudflare_account_id
  comment    = each.value.comment
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnels[each.value.tunnel].id
  network    = each.value.network
}

#==========================================================
# Public Hostname Configurations - GCP Only (no AWS IPs dependency)
#==========================================================
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "gcp_public_hostname" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnels["gcp_infrastructure"].id

  config = {
    ingress = [
      {
        hostname = var.cf_subdomain_web
        service  = "http://localhost:${var.cf_admin_web_app_port}"
        origin_request = {
          access = {
            aud_tag   = [cloudflare_zero_trust_access_application.administration_web_app.aud]
            required  = true
            team_name = var.cf_team_name
          }
        }
      },
      {
        hostname = var.cf_subdomain_web_sensitive
        service  = "http://localhost:${var.cf_sensitive_web_app_port}"
        origin_request = {
          access = {
            aud_tag   = [cloudflare_zero_trust_access_application.sensitive_web_server.aud]
            required  = true
            team_name = var.cf_team_name
          }
        }
      },
      {
        service = "http_status:404"
      }
    ]
  }
}

#==========================================================
# AWS Public Hostname Configuration (requires AWS instances)
#==========================================================
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "aws_public_hostname" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnels["aws_browser_rendering"].id

  config = {
    ingress = [
      {
        hostname = var.cf_subdomain_ssh
        service  = "ssh://${var.aws_ec2_ssh_service_private_ip}:22"
        origin_request = {
          access = {
            aud_tag   = [cloudflare_zero_trust_access_application.ssh_aws_browser_rendering.aud]
            required  = true
            team_name = var.cf_team_name
          }
        }
      },
      {
        hostname = var.cf_subdomain_vnc
        service  = "tcp://${var.aws_ec2_vnc_service_private_ip}:5901"
        origin_request = {
          access = {
            aud_tag   = [cloudflare_zero_trust_access_application.vnc_aws_browser_rendering.aud]
            required  = true
            team_name = var.cf_team_name
          }
        }
      },
      {
        service = "http_status:404"
      }
    ]
  }
}
