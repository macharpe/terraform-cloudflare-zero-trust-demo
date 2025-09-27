#======================================================
# GCP CONFIGURATION
#======================================================

# Core GCP Settings
variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP Region"
  type        = string
  default     = "europe-west3"
}

variable "gcp_service_account_email" {
  description = "Service Account email for Terraform project in GCP"
  type        = string
}

# GCP Users and Authentication
variable "gcp_users" {
  description = "List of all the GCP users"
  type        = list(string)
}

variable "gcp_vm_default_user" {
  description = "default vm user for GCP VM"
  type        = string
}

variable "gcp_windows_user_name" {
  description = "vm user name for GCP Windows VM"
  type        = string
}

variable "gcp_windows_admin_password" {
  description = "Password for Windows Server admin user in GCP"
  type        = string
  sensitive   = true
}

variable "gcp_enable_oslogin" {
  description = "Whether to enable OS Login"
  type        = bool
  default     = true
}

# GCP VM Configuration
variable "gcp_vm_count" {
  description = "number of vm not running cloudflared"
  type        = number
  default     = 1
}

variable "gcp_machine_size" {
  description = "size of the compute engine instance"
  type        = string
  default     = "e2-micro"
}

variable "gcp_windows_machine_size" {
  description = "size of the compute engine instance for Windows specifically"
  type        = string
  default     = "e2-medium"
}

variable "gcp_linux_image" {
  description = "GCP Linux image for compute instances"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
}

variable "gcp_windows_image" {
  description = "GCP Windows image for compute instances"
  type        = string
  default     = "windows-server-2025-dc-v20250612"
}

# GCP VM Names
variable "gcp_cloudflared_vm_name" {
  description = "Name for the VM instance running cloudflared for infrastructure access demo"
  type        = string
}

variable "gcp_windows_rdp_vm_name" {
  description = "Name for the VM instance running cloudflared and Windows RDP Server on GCP"
  type        = string
}

variable "gcp_vm_name" {
  description = "Name for the VM instance NOT running cloudflared"
  type        = string
}

variable "gcp_warp_connector_vm_name" {
  description = "Name of the GCP VM where WARP Connector is installed"
  type        = string
}

# GCP Networking
variable "gcp_infra_cidr" {
  description = "CIDR Range for GCP VMs running cloudflared"
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
# AWS CONFIGURATION
#======================================================

# Core AWS Settings
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

# AWS EC2 Configuration
variable "aws_ec2_instance_config_type" {
  description = "type of EC2 instance"
  type        = string
  default     = "t3.micro"
}

variable "aws_ec2_instance_config_ami_id" {
  description = "AMI ID representing the VM type and ID to be used"
  type        = string
  default     = "ami-086ecbd485d8bb032"
}

variable "aws_cloudflared_count" {
  description = "number of cloudflared replicas"
  type        = number
  default     = 1
}

# AWS Instance Names
variable "aws_ec2_browser_ssh_name" {
  description = "Name of the EC2 instance browser rendered SSH"
  type        = string
}

variable "aws_ec2_browser_vnc_name" {
  description = "Name of the EC2 instance browser rendered VNC"
  type        = string
}

variable "aws_ec2_cloudflared_name" {
  description = "name of cloudflared replica"
  type        = string
}

# AWS Users and Authentication
variable "aws_users" {
  description = "List of all the AWS users"
  type        = list(string)
}

variable "aws_vm_default_user" {
  description = "default user for AWS VM"
  type        = string
}

variable "aws_vnc_password" {
  description = "VNC password for AWS VM"
  type        = string
  sensitive   = true
}

# AWS Networking
variable "aws_vpc_cidr" {
  description = "AWS vpc cidr, subnet for vpc in AWS"
  type        = string
}

variable "aws_private_cidr" {
  description = "AWS private subnet, subnet for VMs in AWS"
  type        = string
}

variable "aws_public_cidr" {
  description = "AWS public subnet"
  type        = string
}

#======================================================
# AZURE CONFIGURATION
#======================================================

# Core Azure Settings
variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "azure_resource_group_region" {
  description = "Location for all resources"
  type        = string
  default     = "Germany West Central"
}

variable "azure_resource_group_name" {
  description = "Ressource Group Name"
  type        = string
}

variable "azure_default_tags" {
  description = "default tags for Azure"
  type        = map(string)
  default = {
    environment = "dev"
    service     = "cloudflare-zero-trust-demo"
    Owner       = "macharpe"
  }
}

# Azure Users and Authentication
variable "azure_developer1_name" {
  description = "User 1 in Azure AD"
  type        = string
}

variable "azure_developer2_name" {
  description = "User 2 in Azure AD"
  type        = string
}

variable "azure_sales1_name" {
  description = "User 3 in Azure AD"
  type        = string
}

variable "azure_sales2_name" {
  description = "User 4 in Azure AD"
  type        = string
}

variable "azure_user_password" {
  description = "Password for Azure AD users"
  type        = string
  sensitive   = true
}

variable "azure_user_principal_domain" {
  description = "Domain for users created in Azure AD"
  type        = string
}

variable "azure_matthieu_user_object_id" {
  description = "Object ID in Azure for user Matthieu"
  type        = string
  sensitive   = true
}

# Azure VM Configuration
variable "azure_vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_B1ls"
}

variable "azure_image_publisher" {
  description = "Azure VM image publisher"
  type        = string
  default     = "Canonical"
}

variable "azure_image_offer" {
  description = "Azure VM image offer"
  type        = string
  default     = "ubuntu-24_04-lts"
}

variable "azure_image_sku" {
  description = "Azure VM image SKU"
  type        = string
  default     = "server"
}

variable "azure_image_version" {
  description = "Azure VM image version"
  type        = string
  default     = "latest"
}

variable "azure_vm_admin_username" {
  description = "Administrator username"
  type        = string
}

variable "azure_vm_admin_password" {
  description = "Administrator password (min 12 characters)"
  type        = string
  sensitive   = true
}

variable "azure_vm_count" {
  description = "number of Azure VM"
  type        = number
  default     = 1
}

# Azure VM Names
variable "azure_warp_vm_name" {
  description = "Name of the Azure VM where WARP Connector is installed"
  type        = string
}

variable "azure_vm_name" {
  description = "Azure VM name where WARP Connector is NOT installed"
  type        = string
}

# Azure Networking
variable "azure_subnet_cidr" {
  description = "Azure address prefix, subnet for VM in Azure"
  type        = string
}

variable "azure_vnet_cidr" {
  description = "Azure address vnet, subnet for vnet in Azure"
  type        = string
}

variable "azure_public_dns_domain" {
  description = "Azure Public DNS Domain"
  type        = string
}

#======================================================
# CLOUDFLARE CORE CONFIGURATION
#======================================================

# Cloudflare Authentication
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
# CLOUDFLARE TUNNEL CONFIGURATION
#======================================================

variable "cf_tunnel_name_gcp" {
  description = "Name of the Cloudflare tunnel to GCP"
  type        = string
}

variable "cf_tunnel_name_aws" {
  description = "Name of the Cloudflare tunnel to AWS"
  type        = string
}

variable "cf_windows_rdp_tunnel_name" {
  description = "Name of the Cloudflared tunnel for Windows RDP Server GCP"
  type        = string
}

#======================================================
# CLOUDFLARE DNS SUBDOMAIN CONFIGURATION
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

#======================================================
# CLOUDFLARE ACCESS APPLICATION CONFIGURATION
#======================================================

variable "cf_browser_ssh_app_name" {
  description = "Name of the Browser Rendering SSH App in Cloudflare"
  type        = string
}

variable "cf_browser_vnc_app_name" {
  description = "Name of the Browser Rendering VNC App in Cloudflare"
  type        = string
}

variable "cf_infra_app_name" {
  description = "Name of the Infrastructure App in Cloudflare"
  type        = string
}

variable "cf_sensitive_web_app_name" {
  description = "Name of the Sensitive web App in Cloudflare"
  type        = string
}

variable "cf_intranet_web_app_name" {
  description = "Name of the Intranet web App in Cloudflare"
  type        = string
}

variable "cf_browser_rdp_app_name" {
  description = "Name of the RDP windows browser rendered App in Cloudflare"
  type        = string
}

#======================================================
# CLOUDFLARE APPLICATION PORTS
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
  description = "Port for the Domain Controller RDP in Cloudflare"
  type        = number
}

#======================================================
# CLOUDFLARE TARGET NAMES
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
# CLOUDFLARE IDENTITY PROVIDERS
#======================================================

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

#======================================================
# CLOUDFLARE DEVICE POSTURE CHECKS
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

variable "cf_ios_posture_id" {
  description = "Latest iOS version posture ID in Cloudflare"
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
# CLOUDFLARE WARP CONNECTOR CONFIGURATION
#======================================================

variable "cf_default_cgnat_routes" {
  description = "default cgnat routes"
  type = list(object({
    address     = string
    description = string
  }))
  default = [{
    address     = "100.64.0.0/10"
    description = "Default CGNAT Range"
  }]
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
# OKTA CONFIGURATION
#======================================================

# Okta Group IDs (only used variables retained)

# Okta SAML Group Names
variable "okta_infra_admin_saml_group_name" {
  description = "SAML Group name for InfrastructureAdmin group"
  type        = string
}

variable "okta_contractors_saml_group_name" {
  description = "SAML Group name for Contractors group"
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

# Okta User IDs (unused variables removed)

# Okta User Logins
variable "okta_bob_user_login" {
  description = "User login for bob, in an email format"
  type        = string
}

# Unused okta_jose_user_login and okta_stephane_user_login removed

variable "okta_matthieu_user_login" {
  description = "User login for matthieu, in an email format"
  type        = string
}

# Okta User Passwords
variable "okta_bob_user_linux_password" {
  description = "Linux password for user bob in EC2 instance"
  type        = string
  sensitive   = true
}

#======================================================
# DATADOG CONFIGURATION
#======================================================

variable "datadog_api_key" {
  description = "Datadog API Key from https://app.datadoghq.com/organization-settings/api-keys"
  type        = string
}

variable "datadog_region" {
  description = "location of the datadog region"
  type        = string
  default     = "datadoghq.eu"
}

#======================================================
# WARP CONNECTOR TUNNEL IDS
#======================================================

variable "cf_warp_tunnel_azure_id" {
  description = "ID of the WARP Connector Tunnel manually created for Azure in UI"
  type        = string
}

variable "cf_warp_tunnel_gcp_id" {
  description = "ID of the WARP Connector Tunnel manually created for GCP in UI"
  type        = string
}

#======================================================
# TAGS
#======================================================

variable "cf_aws_tag" {
  description = "tag to be assigned to cloudflare application and aws environment"
  type        = string
}
