#======================================================
# Extracted Token
#======================================================
output "gcp_extracted_token" {
  description = <<-EOT
    Cloudflared tunnel token for GCP infrastructure VM.

    Purpose: Authenticates the cloudflared daemon on GCP VMs
    Usage: Injected into VM startup script via cloud-init
    Security: Marked as sensitive - do not expose in logs
    Related: Used by gcp_vm_cloudflared instance
  EOT
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.tunnel_tokens["gcp_infrastructure"].token
  sensitive   = true
}

output "aws_extracted_token" {
  description = <<-EOT
    Cloudflared tunnel token for AWS browser rendering VM.

    Purpose: Authenticates the cloudflared daemon for browser-rendered services
    Usage: Injected into AWS EC2 startup script via cloud-init
    Security: Marked as sensitive - do not expose in logs
    Related: Used by aws_vm_service instance for SSH/VNC browser access
  EOT
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.tunnel_tokens["aws_browser_rendering"].token
  sensitive   = true
}

output "gcp_windows_extracted_token" {
  description = <<-EOT
    Cloudflared tunnel token for GCP Windows RDP VM.

    Purpose: Authenticates the cloudflared daemon for Windows RDP access
    Usage: Injected into GCP Windows VM startup script
    Security: Marked as sensitive - do not expose in logs
    Related: Used by gcp_vm_windows_rdp instance for browser-rendered RDP
  EOT
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.tunnel_tokens["gcp_windows_rdp"].token
  sensitive   = true
}

output "azure_extracted_warp_token" {
  description = <<-EOT
    WARP Connector token for Azure VM routing.

    Purpose: Authenticates Azure WARP connector for private network routing
    Usage: Injected into Azure VM startup script via cloud-init
    Security: Marked as sensitive - do not expose in logs
    Related: Used by azure_vm_linux[0] (WARP connector) for cross-cloud connectivity
  EOT
  value       = local.azure_warp_connector_token
  sensitive   = true
}

output "gcp_extracted_warp_token" {
  description = <<-EOT
    WARP Connector token for GCP VM routing.

    Purpose: Authenticates GCP WARP connector for private network routing
    Usage: Injected into GCP VM startup script via cloud-init
    Security: Marked as sensitive - do not expose in logs
    Related: Used by gcp_vm_warp instance for cross-cloud connectivity
  EOT
  value       = local.gcp_warp_connector_token
  sensitive   = true
}



#======================================================
# Short Lived Certificate
#======================================================
output "pubkey_short_lived_certificate" {
  description = <<-EOT
    Short-lived certificate public key for browser-rendered SSH access.

    Purpose: Enables certificate-based SSH authentication through browser
    Usage: Used by Cloudflare Access for secure SSH connections
    Security: Public key portion - safe to expose
    Duration: Short-lived certificate (typically 1-24 hours)
    Related: Used with cf_app_ssh application for browser SSH access
  EOT
  value       = cloudflare_zero_trust_access_short_lived_certificate.zero_trust_access_short_lived_certificate_database_browser.public_key
  sensitive   = true
}



##### Tunnel IDs
output "gcp_tunnel_id" {
  description = <<-EOT
    Cloudflare Zero Trust Tunnel ID for GCP infrastructure.

    Purpose: Unique identifier for the GCP cloudflared tunnel
    Usage: Reference for tunnel configuration and monitoring
    Format: UUID string
    Related: Used by gcp_vm_cloudflared for secure connectivity
  EOT
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnels["gcp_infrastructure"].id
  sensitive   = false
}

output "gcp_windows_rdp_tunnel_id" {
  description = <<-EOT
    Cloudflare Zero Trust Tunnel ID for GCP Windows RDP access.

    Purpose: Unique identifier for the Windows RDP tunnel
    Usage: Reference for RDP tunnel configuration and monitoring
    Format: UUID string
    Related: Used by gcp_vm_windows_rdp for browser-rendered RDP access
  EOT
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnels["gcp_windows_rdp"].id
  sensitive   = false
}

output "aws_tunnel_id" {
  description = <<-EOT
    Cloudflare Zero Trust Tunnel ID for AWS browser rendering services.

    Purpose: Unique identifier for the AWS browser rendering tunnel
    Usage: Reference for SSH/VNC tunnel configuration and monitoring
    Format: UUID string
    Related: Used by aws_vm_service for browser-rendered SSH and VNC access
  EOT
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
  description = <<-EOT
    Real-time connection status of the GCP infrastructure tunnel.

    Purpose: Monitor tunnel health and connectivity
    Values: "active", "inactive", "down", "degraded"
    Usage: Use for monitoring and alerting on tunnel health
    Related: Corresponds to gcp_vm_cloudflared tunnel status
  EOT
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnels["gcp_infrastructure"].status
  depends_on  = [cloudflare_zero_trust_tunnel_cloudflared.tunnels]
}

output "gcp_windows_rdp_tunnel_status" {
  description = <<-EOT
    Real-time connection status of the GCP Windows RDP tunnel.

    Purpose: Monitor Windows RDP tunnel health and connectivity
    Values: "active", "inactive", "down", "degraded"
    Usage: Use for monitoring and alerting on RDP service availability
    Related: Corresponds to gcp_vm_windows_rdp tunnel status
  EOT
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnels["gcp_windows_rdp"].status
  depends_on  = [cloudflare_zero_trust_tunnel_cloudflared.tunnels]
}

output "aws_tunnel_status" {
  description = <<-EOT
    Real-time connection status of the AWS browser rendering tunnel.

    Purpose: Monitor browser rendering services (SSH/VNC) tunnel health
    Values: "active", "inactive", "down", "degraded"
    Usage: Use for monitoring and alerting on browser rendering availability
    Related: Corresponds to aws_vm_service tunnel status
  EOT
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnels["aws_browser_rendering"].status
  depends_on  = [cloudflare_zero_trust_tunnel_cloudflared.tunnels]
}

#output "azure_tunnel_status" {
#  value       = cloudflare_zero_trust_tunnel_cloudflared.ssh_azure_tunnel.status
#  description = "Azure Tunnel Status"
#  depends_on  = [cloudflare_zero_trust_tunnel_cloudflared.ssh_azure_tunnel]
#}








output "cf_subdomain_ssh" {
  description = <<-EOT
    Public hostname for browser-rendered SSH access.

    Purpose: User-friendly URL for accessing SSH through the browser
    Usage: Navigate to https://{subdomain}.{domain} for SSH access
    Format: Subdomain string (e.g., "ssh")
    Security: Protected by Cloudflare Access policies
    Related: Used by cf_app_ssh application
  EOT
  value       = var.cf_subdomain_ssh
}

output "cf_subdomain_web" {
  description = <<-EOT
    Public hostname for general web services and demo applications.

    Purpose: User-friendly URL for accessing web-based demo applications
    Usage: Navigate to https://{subdomain}.{domain} for web demos
    Format: Subdomain string (e.g., "web")
    Security: Protected by Cloudflare Access policies
    Related: Used by various cf_app_* applications for demo portals
  EOT
  value       = var.cf_subdomain_web
}

output "cf_subdomain_web_sensitive" {
  description = <<-EOT
    Public hostname for sensitive web services requiring enhanced security.

    Purpose: User-friendly URL for accessing sensitive administrative portals
    Usage: Navigate to https://{subdomain}.{domain} for admin access
    Format: Subdomain string (e.g., "admin")
    Security: Enhanced Access policies with device posture and MFA requirements
    Related: Used by training admin portal and other sensitive applications
  EOT
  value       = var.cf_subdomain_web_sensitive
}

output "gateway_ca_certificate" {
  description = <<-EOT
    Cloudflare Gateway root CA certificate for TLS inspection.

    Purpose: Root certificate for Cloudflare Gateway TLS inspection
    Usage: Install on client devices for transparent HTTPS inspection
    Format: PEM-encoded X.509 certificate
    Security: Marked sensitive to prevent accidental exposure
    Documentation: https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/install-cloudflare-cert/
    Related: Required for full Gateway inspection capabilities
  EOT
  value       = local.gateway_ca_certificate.result.public_key
  sensitive   = true
}

output "training_status_admin_portal_aud" {
  description = <<-EOT
    Cloudflare Access Application Audience (AUD) for Training Status Admin Portal.

    Purpose: JWT audience claim for Cloudflare Worker authentication
    Usage: Set as ACCESS_APP_AUD secret in Cloudflare Workers
    Format: Long alphanumeric string (e.g., "abc123def456...")
    Security: Safe to expose - used for JWT validation
    Documentation: https://developers.cloudflare.com/cloudflare-one/identity/authorization-cookie/
    Related: Required for Workers accessing the training admin portal
  EOT
  value = cloudflare_zero_trust_access_application.cf_app_training_portal.aud
}
