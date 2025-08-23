#======================================================
# Extracted Token
#======================================================
output "gcp_extracted_token" {
  description = "token destined to be used in the startup script of GCP VM"
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.tunnel_tokens["gcp_infrastructure"].token
  sensitive   = "true"
}

output "aws_extracted_token" {
  description = "token destined to be used in the startup script of AWS VM"
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.tunnel_tokens["aws_browser_rendering"].token
  sensitive   = "true"
}

output "gcp_windows_extracted_token" {
  description = "token destined to be used in the startup script of GCP Windows VM"
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.tunnel_tokens["gcp_windows_rdp"].token
  sensitive   = "true"
}

output "azure_extracted_warp_token" {
  description = "token destined to be used in the startup script of Azure VM"
  value       = local.azure_warp_connector_token
  sensitive   = "true"
}

output "gcp_extracted_warp_token" {
  description = "token destined to be used in the startup script of GCP VM"
  value       = local.gcp_warp_connector_token
  sensitive   = "true"
}



#======================================================
# Short Lived Certificate
#======================================================
output "pubkey_short_lived_certificate" {
  description = "short lived certificate for Browser rendered App (SSH)"
  value       = cloudflare_zero_trust_access_short_lived_certificate.zero_trust_access_short_lived_certificate_database_browser.public_key
  sensitive   = true
}



##### Tunnel IDs
output "gcp_tunnel_id" {
  description = "ID of the Cloudflare Zero Trust Tunnel to GCP"
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnels["gcp_infrastructure"].id
  sensitive   = false
}

output "gcp_windows_rdp_tunnel_id" {
  description = "ID of the Cloudflare Zero Trust Tunnel to GCP for Windows RDP"
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnels["gcp_windows_rdp"].id
  sensitive   = false
}

output "aws_tunnel_id" {
  description = "ID of the Cloudflare Zero Trust Tunnel to AWS"
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnels["aws_browser_rendering"].id
  sensitive   = false
}

#output "azure_tunnel_id" {
#  value       = cloudflare_zero_trust_tunnel_cloudflared.ssh_aws_tunnel.id
#  description = "ID of the Cloudflare Zero Trust WARP Connector Tunnel to Azure"
#  sensitive   = "true"
#}


#======================================================
# Tunnel Status
#======================================================
output "gcp_tunnel_status" {
  description = "GCP Tunnel Status"
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnels["gcp_infrastructure"].status
  depends_on  = [cloudflare_zero_trust_tunnel_cloudflared.tunnels]
}

output "gcp_windows_rdp_tunnel_status" {
  description = "GCP Tunnel Status for Windows RDP"
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnels["gcp_windows_rdp"].status
  depends_on  = [cloudflare_zero_trust_tunnel_cloudflared.tunnels]
}

output "aws_tunnel_status" {
  description = "AWS Tunnel Status"
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnels["aws_browser_rendering"].status
  depends_on  = [cloudflare_zero_trust_tunnel_cloudflared.tunnels]
}

#output "azure_tunnel_status" {
#  value       = cloudflare_zero_trust_tunnel_cloudflared.ssh_azure_tunnel.status
#  description = "Azure Tunnel Status"
#  depends_on  = [cloudflare_zero_trust_tunnel_cloudflared.ssh_azure_tunnel]
#}








output "cf_subdomain_ssh" {
  description = "Public hostname for the Cloudflare Tunnel SSH service"
  value       = var.cf_subdomain_ssh
}

output "cf_subdomain_web" {
  description = "Public hostname for the Cloudflare Tunnel web service"
  value       = var.cf_subdomain_web
}

output "cf_subdomain_web_sensitive" {
  description = "Public hostname for the Cloudflare Tunnel sensitive web service"
  value       = var.cf_subdomain_web_sensitive
}

output "gateway_ca_certificate" {
  description = "The Cloudflare Gateway CA certificate"
  value       = local.gateway_ca_certificate.result.public_key
  sensitive   = true
}

output "training_status_admin_portal_aud" {
  description = "Application Audience (AUD) Tag for the Training Status Admin Portal"
  value       = cloudflare_zero_trust_access_application.training_status_admin_portal.aud
}
