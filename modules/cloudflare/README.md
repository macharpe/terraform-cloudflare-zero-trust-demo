# Cloudflare Zero Trust Module

This module configures comprehensive Cloudflare Zero Trust infrastructure including tunnels, access applications, policies, and DNS records.

## Overview

The Cloudflare module is the core of the Zero Trust implementation, providing:

- Cloudflared tunnels for secure connectivity
- WARP connectors for private network routing
- Access applications with identity-based policies
- DNS records for service discovery
- Device posture checks and enrollment policies

## Features

### Tunnels & Connectivity

- **Cloudflared Tunnels**: Secure tunnels for AWS, GCP infrastructure and Windows RDP
- **WARP Connectors**: Private network routing for Azure and GCP
- **Browser Rendering**: SSH, VNC, and RDP access through the browser

### Access Control

- **Identity Providers**: Integration with Okta SAML, Azure AD, and OneTime PIN
- **Access Policies**: Role-based and identity-aware policies
- **Device Posture**: OS version compliance checks
- **Geoblocking**: Country-based access restrictions

### Applications

- **Service Applications**: SSH, VNC, RDP browser rendering
- **Demo Applications**: Professional HTML portals for testing
- **Admin Portals**: Training status and admin interfaces
- **SaaS Integrations**: Okta, Meraki, Salesforce applications

## Usage

```hcl
module "cloudflare" {
  source = "./modules/cloudflare"

  # Required variables
  cloudflare_account_id = var.cloudflare_account_id
  cloudflare_zone_id    = var.cloudflare_zone_id

  # Tunnel configurations
  cf_tunnel_aws_browser_rendering_id = var.cf_tunnel_aws_browser_rendering_id
  cf_tunnel_gcp_infrastructure_id    = var.cf_tunnel_gcp_infrastructure_id
  cf_tunnel_gcp_windows_rdp_id       = var.cf_tunnel_gcp_windows_rdp_id

  # WARP connector configurations
  cf_warp_tunnel_azure_id = var.cf_warp_tunnel_azure_id
  cf_warp_tunnel_gcp_id   = var.cf_warp_tunnel_gcp_id

  # Identity providers
  cf_idp_okta_id     = var.cf_idp_okta_id
  cf_idp_azuread_id  = var.cf_idp_azuread_id
  cf_idp_otp_id      = var.cf_idp_otp_id

  # Device posture checks
  cf_posture_windows_id = var.cf_posture_windows_id
  cf_posture_macos_id   = var.cf_posture_macos_id
  cf_posture_linux_id   = var.cf_posture_linux_id

  # Network configurations
  aws_public_ips  = module.aws_infrastructure.public_ips
  gcp_public_ips  = module.gcp_infrastructure.public_ips
  azure_public_ip = module.azure_infrastructure.public_ip
}
```

## Required Manual Setup

Before using this module, manually configure in Cloudflare dashboard:

1. **WARP Connector Tunnels**: Create WARP connector tunnels (not cloudflared)
2. **Identity Providers**: Configure Okta SAML, Azure AD, and OTP
3. **Device Enrollment**: Set up enrollment policies
4. **Device Posture**: Configure OS compliance checks

## Inputs

| Name | Type | Description | Required |
|------|------|-------------|----------|
| `cloudflare_account_id` | `string` | Cloudflare account ID | Yes |
| `cloudflare_zone_id` | `string` | Cloudflare DNS zone ID | Yes |
| `cf_tunnel_*_id` | `string` | Tunnel IDs for various services | Yes |
| `cf_warp_tunnel_*_id` | `string` | WARP connector tunnel IDs | Yes |
| `cf_idp_*_id` | `string` | Identity provider IDs | Yes |
| `cf_posture_*_id` | `string` | Device posture check IDs | Yes |
| `cf_email_domain` | `string` | Email domain for access policies | Yes |

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| `gcp_extracted_token` | Cloudflared token for GCP infrastructure | Yes |
| `aws_extracted_token` | Cloudflared token for AWS browser rendering | Yes |
| `gcp_windows_extracted_token` | Cloudflared token for Windows RDP | Yes |
| `azure_extracted_warp_token` | WARP connector token for Azure | Yes |
| `gcp_extracted_warp_token` | WARP connector token for GCP | Yes |
| `training_admin_app_aud` | Access app AUD for Worker integration | No |
| `dns_records` | Created DNS records for services | No |

## Security Considerations

- All tokens are marked as sensitive outputs
- Access policies enforce identity-based controls
- Device posture checks ensure endpoint compliance
- Geoblocking restricts access from specific countries
- Browser rendering eliminates need for local clients

## Dependencies

This module depends on:

- AWS, GCP, and Azure infrastructure modules for IP addresses
- SSH keys module for instance access
- WARP routing module for subnet calculations

## Maintenance

Regular maintenance tasks:

- Review and update access policies
- Monitor tunnel health and connectivity
- Update device posture requirements
- Audit identity provider integrations
- Clean up unused applications and policies

## Troubleshooting

Common issues and solutions:

### Tunnel Connection Issues
- Verify tunnel IDs match dashboard configuration
- Check cloudflared service status on VMs
- Ensure public IPs are correctly configured

### Access Policy Problems
- Verify identity provider configuration
- Check user group memberships
- Review policy evaluation logs in dashboard

### WARP Routing Issues
- Confirm WARP connector is running
- Check route advertisements
- Verify subnet configurations

## Related Documentation

- [Cloudflare Zero Trust Documentation](https://developers.cloudflare.com/cloudflare-one/)
- [Cloudflared Tunnel Guide](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [WARP Connector Setup](https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/)
- [Access Policies](https://developers.cloudflare.com/cloudflare-one/policies/access/)