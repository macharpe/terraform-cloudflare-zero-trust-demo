#======================================================
# INFRASTRUCTURE APP: MySQL Database (Infrastructure)
#======================================================
# Creating the Target
resource "cloudflare_zero_trust_access_infrastructure_target" "gcp_ssh_target" {
  account_id = var.cloudflare_account_id
  hostname   = var.cf_target_ssh_name
  ip = {
    ipv4 = {
      ip_addr = var.gcp_vm_internal_ip
    }
  }
}

# Creating the infrastructure Application
resource "cloudflare_zero_trust_access_application" "cf_app_ssh_infra" {
  account_id                   = var.cloudflare_account_id
  type                         = "infrastructure"
  name                         = var.cf_infra_app_name
  logo_url                     = "https://upload.wikimedia.org/wikipedia/commons/0/01/Google-cloud-platform.svg"
  tags                         = [cloudflare_zero_trust_access_tag.zero_trust_demo_tag.name]
  custom_deny_url              = "https://denied.macharpe.com/"
  custom_non_identity_deny_url = "https://denied.macharpe.com/"

  target_criteria = [{
    port     = "22",
    protocol = "SSH"
    target_attributes = {
      hostname = [var.cf_target_ssh_name]
    },
  }]

  policies = [{
    name     = "SSH GCP Infrastructure Policy"
    decision = "allow"

    allowed_idps                = [var.cf_okta_identity_provider_id]
    auto_redirect_to_identity   = true
    allow_authenticate_via_warp = false

    include = [
      {
        saml = {
          identity_provider_id = var.cf_okta_identity_provider_id
          attribute_name       = "groups"
          attribute_value      = var.okta_infra_admin_saml_group_name
        }
      },
      {
        saml = {
          identity_provider_id = var.cf_okta_identity_provider_id
          attribute_name       = "groups"
          attribute_value      = var.okta_contractors_saml_group_name
        }
      },
      {
        email_domain = {
          domain = var.cf_email_domain
        }
      }
    ]

    require = [
      {
        device_posture = {
          integration_uid = var.cf_gateway_posture_id
        }
      },
      {
        auth_method = {
          auth_method = "mfa"
        }
      }
    ]

    exclude = [
      {
        auth_method = {
          auth_method = "sms"
        }
      }
    ]

    connection_rules = {
      ssh = {
        allow_email_alias = true
        usernames         = [] # None
      }
    }
  }]
}



#======================================================
# SELF-HOSTED APP: DB Server
#======================================================
# Creating the Self-hosted Application for Browser rendering SSH
resource "cloudflare_zero_trust_access_application" "cf_app_ssh_browser" {
  account_id                   = var.cloudflare_account_id
  type                         = "ssh"
  name                         = var.cf_browser_ssh_app_name
  app_launcher_visible         = true
  logo_url                     = "https://cdn.iconscout.com/icon/free/png-256/free-database-icon-download-in-svg-png-gif-file-formats--ui-elements-pack-user-interface-icons-444649.png"
  tags                         = [cloudflare_zero_trust_access_tag.zero_trust_demo_tag.name]
  session_duration             = "0s"
  custom_deny_url              = "https://denied.macharpe.com/"
  custom_non_identity_deny_url = "https://denied.macharpe.com/"

  destinations = [{
    type = "public"
    uri  = var.cf_subdomain_ssh
  }]

  allowed_idps                = [var.cf_okta_identity_provider_id, var.cf_otp_identity_provider_id]
  auto_redirect_to_identity   = false
  allow_authenticate_via_warp = false

  policies = [
    {
      id = cloudflare_zero_trust_access_policy.policies["employees_browser_rendering"].id
    },
    {
      id = cloudflare_zero_trust_access_policy.policies["contractors_browser_rendering"].id
    }
  ]
}

#======================================================
# SELF-HOSTED APP: PostgresDB Admin
#======================================================
# Creating the Self-hosted Application for Browser rendering VNC
resource "cloudflare_zero_trust_access_application" "cf_app_vnc_browser" {
  account_id                   = var.cloudflare_account_id
  type                         = "vnc"
  name                         = var.cf_browser_vnc_app_name
  app_launcher_visible         = true
  logo_url                     = "https://blog.zwindler.fr/2015/07/vnc.png"
  tags                         = [cloudflare_zero_trust_access_tag.zero_trust_demo_tag.name]
  session_duration             = "0s"
  custom_deny_url              = "https://denied.macharpe.com/"
  custom_non_identity_deny_url = "https://denied.macharpe.com/"

  destinations = [{
    type = "public"
    uri  = var.cf_subdomain_vnc
  }]

  allowed_idps                = [var.cf_okta_identity_provider_id, var.cf_otp_identity_provider_id]
  auto_redirect_to_identity   = false
  allow_authenticate_via_warp = false

  policies = [{
    id = cloudflare_zero_trust_access_policy.policies["employees_browser_rendering"].id
  }]
}



#======================================================
# SELF-HOSTED APP: Competition App
#======================================================
# Creating the Self-hosted Application for Competition web application
resource "cloudflare_zero_trust_access_application" "cf_app_web_competition" {
  account_id                   = var.cloudflare_account_id
  type                         = "self_hosted"
  name                         = var.cf_sensitive_web_app_name
  app_launcher_visible         = true
  logo_url                     = "https://img.freepik.com/free-vector/trophy_78370-345.jpg"
  tags                         = [cloudflare_zero_trust_access_tag.zero_trust_demo_tag.name]
  session_duration             = "0s"
  custom_deny_url              = "https://denied.macharpe.com/"
  custom_non_identity_deny_url = "https://denied.macharpe.com/"

  destinations = [{
    type = "public"
    uri  = var.cf_subdomain_web_sensitive
  }]

  allowed_idps                = [var.cf_okta_identity_provider_id]
  auto_redirect_to_identity   = true
  allow_authenticate_via_warp = false

  policies = [{
    id = cloudflare_zero_trust_access_policy.policies["competition_web_app"].id
  }]
}




#======================================================
# SELF-HOSTED APP: Macharpe Intranet
#======================================================
# Creating the Self-hosted Application for Administration web application
resource "cloudflare_zero_trust_access_application" "cf_app_web_intranet" {
  account_id                   = var.cloudflare_account_id
  type                         = "self_hosted"
  name                         = var.cf_intranet_web_app_name
  app_launcher_visible         = true
  logo_url                     = "https://raw.githubusercontent.com/uditkumar489/Icon-pack/master/Entrepreneur/digital-marketing/svg/computer-1.svg"
  tags                         = [cloudflare_zero_trust_access_tag.zero_trust_demo_tag.name]
  session_duration             = "0s"
  custom_deny_url              = "https://denied.macharpe.com/"
  custom_non_identity_deny_url = "https://denied.macharpe.com/"

  destinations = [{
    type = "public"
    uri  = var.cf_subdomain_web
  }]

  allowed_idps                = [var.cf_okta_identity_provider_id]
  auto_redirect_to_identity   = true
  allow_authenticate_via_warp = false

  policies = [{
    id = cloudflare_zero_trust_access_policy.policies["intranet_web_app"].id
  }]
}



#======================================================
# SELF-HOSTED APP: Domain Controller
#======================================================
# Creating the Target
resource "cloudflare_zero_trust_access_infrastructure_target" "gcp_rdp_target" {
  account_id = var.cloudflare_account_id
  hostname   = var.cf_target_rdp_name
  ip = {
    ipv4 = {
      ip_addr = var.gcp_windows_vm_internal_ip
    }
  }
}

# Domain Controller Browser-Rendered RDP Application
resource "cloudflare_zero_trust_access_application" "cf_app_rdp_domain" {
  account_id                   = var.cloudflare_account_id
  type                         = "rdp"
  name                         = "Domain Controller"
  app_launcher_visible         = true
  logo_url                     = "https://www.kevinsubileau.fr/wp-content/uploads/2016/05/RDP_icon.png"
  tags                         = [cloudflare_zero_trust_access_tag.zero_trust_demo_tag.name]
  session_duration             = "0s"
  custom_deny_url              = "https://denied.macharpe.com/"
  custom_non_identity_deny_url = "https://denied.macharpe.com/"

  # Public hostname for browser rendering
  domain = var.cf_subdomain_rdp

  # Target criteria - references the existing gcp_rdp_target
  target_criteria = [{
    port     = 3389
    protocol = "RDP"
    target_attributes = {
      hostname = [var.cf_target_rdp_name] # This will be "Domain-Controller"
    }
  }]

  # Identity provider settings
  allowed_idps               = [var.cf_okta_identity_provider_id]
  auto_redirect_to_identity  = true
  enable_binding_cookie      = false
  http_only_cookie_attribute = false
  options_preflight_bypass   = false

  # Reference the policy from cloudflare-app-policies.tf
  policies = [{
    id = cloudflare_zero_trust_access_policy.policies["domain_controller"].id
  }]

  # Depends on the existing target
  depends_on = [
    cloudflare_zero_trust_access_infrastructure_target.gcp_rdp_target
  ]
}
