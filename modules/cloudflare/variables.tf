#==========================================
# Cloudflare
#==========================================
variable "cloudflare_api_key" {
  description = "Cloudflare API key"
  type        = string
  sensitive   = true
}

variable "cloudflare_email" {
  description = "Cloudflare login email"
  type        = string
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID"
  type        = string
}

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

variable "cf_okta_identity_provider_id" {
  description = "Okta Identity Provider ID in Cloudflare"
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

variable "cf_email_domain" {
  description = "Email Domain used for email authentication in App policies"
  type        = string
}



#==========================================
# Tunnel
#==========================================
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

variable "cf_tunnel_warp_connector_azure_id" {
  description = "ID of the WARP Connector Tunnel manually created for Azure in UI"
  type        = string
}

variable "cf_tunnel_warp_connector_gcp_id" {
  description = "ID of the WARP Connector Tunnel manually created for GCP in UI"
  type        = string
}

#variable "azure_warp_connector_name" {
#  type        = string
#  description = "Name of the Warp Connector tunnel for Azure"
#}



variable "cf_team_name" {
  description = "Name of the Team in Cloudflare, essentially zero-trust org name"
  type        = string
}


#==========================================
# DNS
#==========================================
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




#==========================================
# Target names
#==========================================
variable "cf_target_ssh_name" {
  description = "Friendly name for the Target hostname in Infrastructure App"
  type        = string
}

variable "cf_target_rdp_name" {
  description = "Friendly name for the Target hostname in RDP windows browser rendered App"
  type        = string
}



#==========================================
# Application names
#==========================================
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

variable "cf_admin_web_app_name" {
  description = "Name of the Administration web app in Cloudflare"
  type        = string
}

variable "cf_browser_rdp_app_name" {
  description = "Name of the RDP windows browser rendered App in Cloudflare"
  type        = string
}


variable "cf_admin_web_app_port" {
  description = "Name of the Sensitive web App in Cloudflare"
  type        = number
}

variable "cf_sensitive_web_app_port" {
  description = "Port for the Administration web App in Cloudflare"
  type        = number
}

variable "cf_domain_controller_rdp_port" {
  description = "Port for the Administration web App in Cloudflare"
  type        = number
}


#==========================================
# Okta
#==========================================
variable "okta_infra_admin_saml_group_name" {
  description = "SAML Group name for InfrastructureAdmin group"
  type        = string
}

variable "okta_contractors_saml_group_name" {
  description = "SAML Group name for InfrastructureAdmin group"
  type        = string
}

variable "okta_sales_eng_saml_group_name" {
  description = "SAML Group name for SalesEngineering group"
  type        = string
}

variable "okta_sales_saml_group_name" {
  description = "SAML Group name for Sales group"
  type        = string
}

variable "okta_itadmin_saml_group_name" {
  description = "SAML Group name for ITAdmin group"
  type        = string
}

variable "okta_bob_user_login" {
  description = "User login for bob, in an email format"
  type        = string
}


#==========================================
# GCP
#==========================================
variable "gcp_vm_internal_ip" {
  description = "Internal Private IP of GCP Compute Engine Instance"
  type        = string
}

variable "gcp_windows_vm_internal_ip" {
  description = "Internal Private IP of GCP Compute Engine Instance running Windows RDP"
  type        = string
}

variable "gcp_cloudflared_vm_instance" {
  type = any
}

variable "gcp_ip_cidr_infra" {
  description = "CIDR Range for GCP VMs"
  type        = string
}

variable "gcp_ip_cidr_warp" {
  description = "CIDR Range for GCP VMs running warp"
  type        = string
}

variable "gcp_ip_cidr_windows_rdp" {
  description = "CIDR Range for GCP VMs running cloudflared, Windows and RDP Server"
  type        = string
}


#==========================================
# AWS
#==========================================
variable "aws_ec2_ssh_service_private_ip" {
  description = "private ip address of the SSH service running in AWS"
  type        = string
}

variable "aws_ec2_vnc_service_private_ip" {
  description = "private ip address of the VNC service running in AWS"
  type        = string
}


variable "aws_private_subnet_cidr" {
  description = "AWS private subnet, subnet for VMs in AWS"
  type        = string
}

variable "aws_public_subnet_cidr" {
  description = "AWS public subnet"
  type        = string
}


#==========================================
# Azure
#==========================================
variable "azure_engineering_group_id" {
  type        = string
  description = "Object ID of Azure_Engineering group from Azure AD"
}

variable "azure_sales_group_id" {
  type        = string
  description = "Object ID of Azure_Sales group from Azure AD"
}

variable "azure_address_prefixes" {
  description = "Azure address prefix, subnet for VM in Azure"
  type        = string
}



#==========================================
# Device profile
#==========================================
variable "cf_device_os" {
  description = "This is the OS you are running on your own client machine"
  type        = string
}

variable "cf_osx_version_posture_rule_id" {
  description = "Rule ID for the posture check on latest version of macos"
  type        = string
}


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


#=====================================
# AWS and Cloudflare Tag
#=====================================
variable "cf_aws_tag" {
  description = "tag to be assigned to cloudflare application and aws environment"
  type        = string
}
