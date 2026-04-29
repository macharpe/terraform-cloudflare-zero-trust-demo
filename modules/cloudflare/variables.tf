#======================================================
# CLOUDFLARE CORE CONFIGURATION
#======================================================
variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID"
  type        = string
}

variable "cf_team_name" {
  description = "Name of the Team in Cloudflare, essentially zero-trust org name"
  type        = string
}

variable "cf_email_domain" {
  description = "Email Domain used for email authentication in App policies"
  type        = string
}

#======================================================
# IDENTITY PROVIDERS
#======================================================
variable "cf_okta_new_identity_provider_id" {
  description = "Okta Identity Provider ID in Cloudflare (OIDC)"
  type        = string
  sensitive   = true
}

variable "cf_otp_identity_provider_id" {
  description = "OneTime PIN identity provider ID in Cloudflare"
  type        = string
  sensitive   = true
}

variable "cf_azure_identity_provider_id" {
  description = "Azure Entra ID identity provider ID in Cloudflare"
  type        = string
  sensitive   = true
}

variable "cf_azure_admin_rule_group_id" {
  description = "Azure Administrators Rule Group ID in Cloudflare"
  type        = string
  sensitive   = true
}

#======================================================
# DEVICE POSTURE CHECKS
#======================================================
variable "cf_gateway_posture_id" {
  description = "Gateway posture ID in Cloudflare"
  type        = string
  sensitive   = true
}

variable "cf_macos_posture_id" {
  description = "Latest macOS version posture ID in Cloudflare"
  type        = string
  sensitive   = true
}

variable "cf_windows_posture_id" {
  description = "Latest Windows version posture ID in Cloudflare"
  type        = string
  sensitive   = true
}

variable "cf_linux_posture_id" {
  description = "Latest Linux Kernel version posture ID in Cloudflare"
  type        = string
  sensitive   = true
}

variable "cf_device_os" {
  description = "This is the OS you are running on your own client machine"
  type        = string
}


#======================================================
# TUNNEL CONFIGURATION
#======================================================
variable "cf_tunnel_name_gcp" {
  description = "Name of the Cloudflared tunnel for GCP"
  type        = string
}

variable "cf_tunnel_name_aws" {
  description = "Name of the Cloudflared tunnel for AWS"
  type        = string
}

variable "cf_windows_rdp_tunnel_name_gcp" {
  description = "Name of the Cloudflared tunnel for Windows RDP Server GCP"
  type        = string
}

#======================================================
# DNS SUBDOMAIN CONFIGURATION
#======================================================
variable "cf_subdomain_ssh" {
  description = "Name of the subdomain for ssh public hostname of tunnel"
  type        = string
}

variable "cf_subdomain_vnc" {
  description = "Name of the subdomain for VNC public hostname of tunnel"
  type        = string
}

variable "cf_subdomain_web" {
  description = "Name of the subdomain for web public hostname of tunnel"
  type        = string
}

variable "cf_subdomain_web_sensitive" {
  description = "Name of the subdomain for web sensitive public hostname of tunnel"
  type        = string
}

variable "cf_subdomain_rdp" {
  description = "Name of the subdomain for rdp browser rendered public hostname"
  type        = string
}

variable "cf_subdomain_training_status" {
  description = "Name of the subdomain for training status admin portal (OPTIONAL: only needed if using optional-cloudflare-apps.tf)"
  type        = string
}

variable "cf_subdomain_rbi_warning" {
  description = "Subdomain for the Warning-to-RBI Worker (OPTIONAL: only needed if using the RBI audit portal in access_applications_optional.tf). Example: warning-to-rbi.macharpe.com"
  type        = string
  default     = ""
}

#======================================================
# ACCESS APPLICATION CONFIGURATION
#======================================================
variable "cf_infra_app_name" {
  description = "Name of the Infrastructure App in Cloudflare"
  type        = string
}

variable "cf_browser_ssh_app_name" {
  description = "Name of the Browser Rendering SSH App in Cloudflare"
  type        = string
}

variable "cf_browser_vnc_app_name" {
  description = "Name of the Browser Rendering VNC App in Cloudflare"
  type        = string
}

variable "cf_sensitive_web_app_name" {
  description = "Name of the competition app in Cloudflare"
  type        = string
}

variable "cf_intranet_web_app_name" {
  description = "Name of the Intranet web app in Cloudflare"
  type        = string
}

variable "cf_browser_rdp_app_name" {
  description = "Name of the RDP windows browser rendered App in Cloudflare"
  type        = string
}

#======================================================
# APPLICATION PORTS
#======================================================
variable "cf_intranet_app_port" {
  description = "Port for the Intranet web App in Cloudflare"
  type        = number
}

variable "cf_competition_app_port" {
  description = "Port for the Competition web App in Cloudflare"
  type        = number
}

variable "cf_domain_controller_rdp_port" {
  description = "Port for the RDP domain controller"
  type        = number
}

#======================================================
# TARGET NAMES
#======================================================
variable "cf_target_ssh_name" {
  description = "Friendly name for the Target hostname in Infrastructure App"
  type        = string
}

variable "cf_target_rdp_name" {
  description = "Friendly name for the Target hostname in RDP windows browser rendered App"
  type        = string
}

#======================================================
# OKTA GROUPS (OIDC)
#======================================================
variable "okta_infra_admin_group_name" {
  description = "Okta group name for InfrastructureAdmin"
  type        = string
}

variable "okta_contractors_group_name" {
  description = "Okta group name for Contractors"
  type        = string
}

variable "okta_sales_eng_group_name" {
  description = "Okta group name for SalesEngineering"
  type        = string
}

variable "okta_sales_group_name" {
  description = "Okta group name for Sales"
  type        = string
}

variable "okta_itadmin_group_name" {
  description = "Okta group name for ITAdmin"
  type        = string
}

#======================================================
# OKTA USER LOGINS
#======================================================
variable "okta_bob_user_login" {
  description = "User login for bob, in an email format"
  type        = string
}

variable "okta_matthieu_user_login" {
  description = "User login for matthieu, in an email format"
  type        = string
}

#======================================================
# GCP INFRASTRUCTURE
#======================================================
variable "gcp_vm_internal_ip" {
  description = "Internal Private IP of GCP Compute Engine Instance"
  type        = string
}

variable "gcp_windows_vm_internal_ip" {
  description = "Internal Private IP of GCP Compute Engine Instance running Windows RDP"
  type        = string
}

variable "gcp_infra_cidr" {
  description = "CIDR Range for GCP VMs"
  type        = string
}

variable "gcp_warp_cidr" {
  description = "CIDR Range for GCP VMs running warp"
  type        = string
}

variable "gcp_windows_rdp_cidr" {
  description = "CIDR Range for GCP VMs running cloudflared, Windows and RDP Server"
  type        = string
}

#======================================================
# AWS INFRASTRUCTURE
#======================================================
variable "aws_ec2_ssh_service_private_ip" {
  description = "private ip address of the SSH service running in AWS"
  type        = string
}

variable "aws_ec2_vnc_service_private_ip" {
  description = "private ip address of the VNC service running in AWS"
  type        = string
}

variable "aws_private_cidr" {
  description = "AWS private subnet, subnet for VMs in AWS"
  type        = string
}

#======================================================
# AZURE INFRASTRUCTURE
#======================================================
variable "azure_engineering_group_id" {
  description = "Object ID of Azure_Engineering group from Azure AD"
  type        = string
}

variable "azure_sales_group_id" {
  description = "Object ID of Azure_Sales group from Azure AD"
  type        = string
}

variable "azure_subnet_cidr" {
  description = "Azure address prefix, subnet for VM in Azure"
  type        = string
}

#======================================================
# WARP CONNECTOR CONFIGURATION
#======================================================
variable "cf_default_cgnat_routes" {
  description = "default cgnat routes"
  type = list(object({
    address     = string
    description = string
  }))
}

variable "cf_custom_cgnat_routes" {
  description = "List of custom CGNAT routes to add to the device profile"
  type = list(object({
    address     = string
    description = string
  }))
}

variable "cf_warp_cgnat_cidr" {
  description = "default ip range for WARP when overriding local interface IP"
  type        = string
}

#======================================================
# SUBNET GENERATION (JSON)
#======================================================
variable "cf_azure_json_subnet_generation" {
  description = "Results of the Azure Subnet generation in json format"
  type        = any
}

variable "cf_gcp_json_subnet_generation" {
  description = "Results of the GCP Subnet generation in json format"
  type        = any
}

variable "cf_aws_json_subnet_generation" {
  description = "Results of the AWS Subnet generation in json format"
  type        = any
}

#======================================================
# TAGS
#======================================================
variable "cf_cloudflare_tag" {
  description = "tag name to be assigned to cloudflare zero trust access applications"
  type        = string
}

#======================================================
# WARP CONNECTOR TUNNEL IDS
#======================================================

variable "cf_tunnel_warp_connector_azure_id" {
  description = "ID of the WARP Connector Tunnel manually created for Azure in UI"
  type        = string
}

variable "cf_tunnel_warp_connector_gcp_id" {
  description = "ID of the WARP Connector Tunnel manually created for GCP in UI"
  type        = string
}

#======================================================
# LOAD BALANCING DEMO CONFIGURATION
#======================================================
variable "lb_demo_enabled" {
  description = "Enable/Disable the Load Balancing demo infrastructure"
  type        = bool
  default     = false
}

variable "lb_tunnel_name_aws" {
  description = "Name of the Cloudflare tunnel for AWS LB demo"
  type        = string
  default     = "Tunnel LB AWS - DC1"
}

variable "lb_tunnel_name_gcp" {
  description = "Name of the Cloudflare tunnel for GCP LB demo"
  type        = string
  default     = "Tunnel LB GCP - onprem"
}

variable "lb_tunnel_name_azure" {
  description = "Name of the Cloudflare tunnel for Azure LB demo"
  type        = string
  default     = "Tunnel LB Azure - DR"
}

variable "lb_web_port" {
  description = "Port for the web server on LB demo VMs"
  type        = number
  default     = 80
}

variable "lb_subdomain" {
  description = "Subdomain for the load balancer (e.g., 'roger' for roger.example.com)"
  type        = string
  default     = "roger"
}

variable "cf_domain" {
  description = "Domain name for Cloudflare DNS records (e.g., example.com)"
  type        = string
  default     = ""
}

#======================================================
# DLP PROFILE IDS (AI Prompt Controls)
#======================================================
variable "cf_dlp_profile_ai_prompt_ai_security" {
  description = "DLP Profile ID for AI Security detection in AI prompts"
  type        = string
  sensitive   = true
}

variable "cf_dlp_profile_ai_prompt_ai_customer" {
  description = "DLP Profile ID for AI Customer data detection in AI prompts"
  type        = string
  sensitive   = true
}

variable "cf_dlp_profile_ai_prompt_financial_information" {
  description = "DLP Profile ID for Financial Information detection in AI prompts"
  type        = string
  sensitive   = true
}

variable "cf_dlp_profile_ai_prompt_pii" {
  description = "DLP Profile ID for PII detection in AI prompts"
  type        = string
  sensitive   = true
}

variable "cf_dlp_profile_ai_prompt_technical" {
  description = "DLP Profile ID for Technical data detection in AI prompts"
  type        = string
  sensitive   = true
}

#======================================================
# WARNING-TO-RBI WORKER
#======================================================
variable "cf_rbi_warning_worker_url" {
  description = "Full URL of the Warning-to-RBI Worker warn endpoint (e.g. https://warning-to-rbi.macharpe.com/warn)"
  type        = string
  default     = "https://warning-to-rbi.macharpe.com/warn"
}

variable "cf_rbi_source_cidr" {
  description = "Source IP CIDR for Clientless RBI egress traffic. Used in the HTTP allow exception policy to prevent double-isolation loops. The correct HTTP-layer selector is http.conn.src_ip[*] (not net.src.ip which is L4-only). Cloudflare's current RBI egress range is 198.41.211.0/24."
  type        = string
  default     = "198.41.211.0/24"
}

#======================================================
# COMMENTED OUT VARIABLES
#======================================================
# The following variables are commented out but kept for reference

#variable "azure_warp_connector_name" {
#  type        = string
#  description = "Name of the Warp Connector tunnel for Azure"
#}
