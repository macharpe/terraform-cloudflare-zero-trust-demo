#==========================================
# Cleanup scripts before the demo
#==========================================
# Known Host cleanup in ~/.ssh/known_hosts
resource "null_resource" "cleanup_known_hosts" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "python3 ${path.module}/scripts/cleanup/known_hosts_cleanup.py"
  }
}

# Cleanup device in Cloudflare Dashboard
resource "null_resource" "cleanup_devices" {
  provisioner "local-exec" {
    command = "chmod u+x ${path.root}/scripts/cleanup/cloudflare_devices_cleanup.sh && ${path.root}/scripts/cleanup/cloudflare_devices_cleanup.sh"
    environment = {
      CLOUDFLARE_EMAIL      = var.cloudflare_email
      CLOUDFLARE_API_KEY    = var.cloudflare_api_key
      CLOUDFLARE_ACCOUNT_ID = var.cloudflare_account_id
      DRY_RUN               = "false"
      FORCE_DELETE          = "true"
      PREFIX                = "cloudflare-warp-connector-"
    }
  }
}


#==========================================
# main.tf
#==========================================
data "http" "my_ip" {
  url = "https://4.ident.me/"
}

module "ssh_keys" {
  source                            = "./modules/keys"
  gcp_users                         = toset(var.gcp_users)
  aws_ec2_cloudflared_replica_count = var.aws_ec2_cloudflared_replica_count
  azure_vm_count                    = var.azure_vm_count
  gcp_vm_count                      = var.gcp_vm_count
}

module "cloudflare" {
  source = "./modules/cloudflare"

  cloudflare_account_id = var.cloudflare_account_id
  cloudflare_zone_id    = var.cloudflare_zone_id
  cloudflare_email      = var.cloudflare_email
  cloudflare_api_key    = var.cloudflare_api_key

  # Tunnel
  cf_tunnel_name_gcp             = var.cf_tunnel_name_gcp
  cf_tunnel_name_aws             = var.cf_tunnel_name_aws
  cf_windows_rdp_tunnel_name_gcp = var.cf_windows_rdp_tunnel_name_gcp

  cf_tunnel_warp_connector_azure_id = var.cf_tunnel_warp_connector_azure_id
  cf_tunnel_warp_connector_gcp_id   = var.cf_tunnel_warp_connector_gcp_id

  gcp_vm_internal_ip          = google_compute_instance.gcp_cloudflared_vm_instance.network_interface[0].network_ip
  gcp_windows_vm_internal_ip  = google_compute_instance.gcp_windows_rdp_server.network_interface[0].network_ip
  gcp_cloudflared_vm_instance = google_compute_instance.gcp_cloudflared_vm_instance
  gcp_ip_cidr_infra           = var.gcp_ip_cidr_infra
  gcp_ip_cidr_warp            = var.gcp_ip_cidr_warp
  gcp_ip_cidr_windows_rdp     = var.gcp_ip_cidr_windows_rdp

  # Domain
  cf_subdomain_ssh           = var.cf_subdomain_ssh
  cf_subdomain_vnc           = var.cf_subdomain_vnc
  cf_subdomain_web           = var.cf_subdomain_web
  cf_subdomain_web_sensitive = var.cf_subdomain_web_sensitive
  cf_target_name             = var.cf_target_name

  # SAML OKTA
  okta_infrastructureadmin_saml_group_name = var.okta_infrastructureadmin_saml_group_name
  okta_contractors_saml_group_name         = var.okta_contractors_saml_group_name
  okta_salesengineering_saml_group_name    = var.okta_salesengineering_saml_group_name
  okta_itadmin_saml_group_name             = var.okta_itadmin_saml_group_name
  okta_sales_saml_group_name               = var.okta_sales_saml_group_name

  okta_bob_user_login = var.okta_bob_user_login

  cf_email_domain = var.cf_email_domain

  # App names and ports
  cf_browser_rendering_ssh_app_name = var.cf_browser_rendering_ssh_app_name
  cf_browser_rendering_vnc_app_name = var.cf_browser_rendering_vnc_app_name
  cf_infra_app_name                 = var.cf_infra_app_name
  cf_sensitive_web_app_name         = var.cf_sensitive_web_app_name
  cf_administration_web_app_name    = var.cf_administration_web_app_name
  cf_team_name                      = var.cf_team_name
  cf_administration_web_app_port    = var.cf_administration_web_app_port
  cf_sensitive_web_app_port         = var.cf_sensitive_web_app_port
  cf_domain_controller_rdp_port     = var.cf_domain_controller_rdp_port

  # AWS
  aws_ec2_ssh_service_private_ip = aws_instance.aws_ec2_service_instance.private_ip
  aws_ec2_vnc_service_private_ip = aws_instance.aws_ec2_vnc_instance.private_ip
  aws_private_subnet_cidr        = var.aws_private_subnet_cidr
  aws_public_subnet_cidr         = var.aws_public_subnet_cidr

  # Azure
  azure_engineering_group_id = module.azure-ad.azure_engineering_group_id
  azure_sales_group_id       = module.azure-ad.azure_sales_group_id
  azure_address_prefixes     = var.azure_address_prefixes

  # Static definition
  cf_gateway_posture_id                     = var.cf_gateway_posture_id
  cf_latest_macOS_version_posture_id        = var.cf_latest_macOS_version_posture_id
  cf_latest_windows_version_posture_id      = var.cf_latest_windows_version_posture_id
  cf_latest_linux_kernel_version_posture_id = var.cf_latest_linux_kernel_version_posture_id
  cf_okta_identity_provider_id              = var.cf_okta_identity_provider_id
  cf_onetimepin_identity_provider_id        = var.cf_onetimepin_identity_provider_id
  cf_azure_identity_provider_id             = var.cf_azure_identity_provider_id
  cf_azure_administrators_rule_group_id     = var.cf_azure_administrators_rule_group_id

  # Device Profile
  cf_device_os                   = var.cf_device_os
  cf_osx_version_posture_rule_id = var.cf_osx_version_posture_rule_id
  cf_default_cgnat_routes        = var.cf_default_cgnat_routes
  cf_custom_cgnat_routes         = var.cf_custom_cgnat_routes

  # Subnet generation
  cf_azure_json_subnet_generation = module.warp-routing.cf_azure_json_subnet_generation
  cf_gcp_json_subnet_generation   = module.warp-routing.cf_gcp_json_subnet_generation
  cf_aws_json_subnet_generation   = module.warp-routing.cf_aws_json_subnet_generation

  # Tag
  cf_aws_tag = var.cf_aws_tag

  # variable name defined in module == var.variable name defined in variables in main folder
}

module "azure-ad" {
  source                        = "./modules/azure"
  azure_user_password           = var.azure_user_password
  azure_user_principal_domain   = var.azure_user_principal_domain
  azure_matthieu_user_object_id = var.azure_matthieu_user_object_id

  azure_developer1_name = var.azure_developer1_name
  azure_developer2_name = var.azure_developer2_name
  azure_sales1_name     = var.azure_sales1_name
  azure_sales2_name     = var.azure_sales2_name
}

module "warp-routing" {
  source                      = "./modules/warp-routing"
  gcp_cloudflared_vm_instance = google_compute_instance.gcp_cloudflared_vm_instance
  gcp_vm_instance             = [google_compute_instance.gcp_vm_instance[0]]

  azure_address_prefixes  = var.azure_address_prefixes
  gcp_ip_cidr_infra       = var.gcp_ip_cidr_infra
  gcp_ip_cidr_warp        = var.gcp_ip_cidr_warp
  aws_private_subnet_cidr = var.aws_private_subnet_cidr
  gcp_ip_cidr_windows_rdp = var.gcp_ip_cidr_windows_rdp
}
