#======================================================
# Short lived Certificate CA for Infrastructure Access
#======================================================
locals {
  gateway_ca_certificate = jsondecode(data.http.short_lived_cloudflare_ssh_ca.response_body)
}

data "http" "short_lived_cloudflare_ssh_ca" {
  url = "https://api.cloudflare.com/client/v4/accounts/${var.cloudflare_account_id}/access/gateway_ca"

  request_headers = {
    "X-Auth-Email" = var.cloudflare_email
    "X-Auth-Key"   = var.cloudflare_api_key
    "Content-Type" = "application/json"
  }
}

#=====================================
# GCP Tunnel: Access for Infrastruture
#=====================================
resource "cloudflare_zero_trust_tunnel_cloudflared" "gcp_cloudflared_tunnel" {
  account_id = var.cloudflare_account_id
  name       = var.cf_tunnel_name_gcp
  config_src = "cloudflare"
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "gcp_tunnel_cloudflared_token" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.gcp_cloudflared_tunnel.id
}

# Private Network Tab configuration
resource "cloudflare_zero_trust_tunnel_cloudflared_route" "gcp_private_network" {
  account_id = var.cloudflare_account_id
  comment    = "This is a route making GCP subnet available in the Cloudflare network"
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.gcp_cloudflared_tunnel.id
  network    = var.gcp_ip_cidr_infra
}


# Public Hostname Tab configuration for GCP Tunnel
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "gcp_public_hostname" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.gcp_cloudflared_tunnel.id

  config = {
    ingress = [
      {
        hostname = var.cf_subdomain_web
        service  = "http://localhost:${var.cf_administration_web_app_port}"
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


#===========================================
# GCP Tunnel: Cloudflared Windows RDP Server
#===========================================
resource "cloudflare_zero_trust_tunnel_cloudflared" "gcp_cloudflared_windows_rdp_tunnel" {
  account_id = var.cloudflare_account_id
  name       = var.cf_windows_rdp_tunnel_name_gcp
  config_src = "cloudflare"
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "gcp_tunnel_cloudflared_windows_rdp_token" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.gcp_cloudflared_windows_rdp_tunnel.id
}

# Private Network Tab configuration
resource "cloudflare_zero_trust_tunnel_cloudflared_route" "gcp_private_network_windows_rdp" {
  account_id = var.cloudflare_account_id
  comment    = "This is a route making GCP Windows RDP subnet available in the Cloudflare network"
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.gcp_cloudflared_windows_rdp_tunnel.id
  network    = var.gcp_ip_cidr_windows_rdp
}




#=====================================
# AWS Tunnel: SSH browser rendered
#=====================================
resource "cloudflare_zero_trust_tunnel_cloudflared" "aws_cloudflared_tunnel" {
  account_id = var.cloudflare_account_id
  name       = var.cf_tunnel_name_aws
  config_src = "cloudflare"
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "aws_tunnel_cloudflared_token" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.aws_cloudflared_tunnel.id
}

# Private Network Tab configuration (Private Network AWS)
resource "cloudflare_zero_trust_tunnel_cloudflared_route" "aws_private_network" {
  account_id = var.cloudflare_account_id
  comment    = "This is a route making AWS private subnet available in the Cloudflare network"
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.aws_cloudflared_tunnel.id
  network    = var.aws_private_subnet_cidr
}

# Public Hostname Tab configuration for AWS Tunnel
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "aws_public_hostname" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.aws_cloudflared_tunnel.id

  config = {
    ingress = [{
      hostname = var.cf_subdomain_ssh
      service  = "ssh://${var.aws_ec2_service_private_ip}:22"
      origin_request = {
        access = {
          aud_tag   = [cloudflare_zero_trust_access_application.ssh_aws_browser_rendering.aud]
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




#=====================================
# Azure Tunnel: WARP Connector
#=====================================
locals {
  azure_warp_connector_token = jsondecode(data.http.cloudflare_warp_connector_token_azure.response_body).result
}

data "http" "cloudflare_warp_connector_token_azure" {
  url = "https://api.cloudflare.com/client/v4/accounts/${var.cloudflare_account_id}/warp_connector/${var.cf_tunnel_warp_connector_azure_id}/token"
  request_headers = {
    "X-Auth-Email" = "${var.cloudflare_email}"
    "X-Auth-Key"   = "${var.cloudflare_api_key}"
    "Content-Type" = "application/json"
  }
}

# data "cloudflare_zero_trust_tunnel_warp_connector_token" "azure_warp_connector_token" {
#   account_id = var.cloudflare_account_id
#   tunnel_id  = var.cf_tunnel_warp_connector_azure_id
# }


#=====================================
# GCP Tunnel: WARP Connector
#=====================================
locals {
  gcp_warp_connector_token = jsondecode(data.http.cloudflare_warp_connector_token_gcp.response_body).result
}

data "http" "cloudflare_warp_connector_token_gcp" {
  url = "https://api.cloudflare.com/client/v4/accounts/${var.cloudflare_account_id}/warp_connector/${var.cf_tunnel_warp_connector_gcp_id}/token"
  request_headers = {
    "X-Auth-Email" = "${var.cloudflare_email}"
    "X-Auth-Key"   = "${var.cloudflare_api_key}"
    "Content-Type" = "application/json"
  }
}

# data "cloudflare_zero_trust_tunnel_warp_connector_token" "gcp_warp_connector_token_test" {
#   account_id = var.cloudflare_account_id
#   tunnel_id  = var.cf_tunnel_warp_connector_gcp_id
# }
