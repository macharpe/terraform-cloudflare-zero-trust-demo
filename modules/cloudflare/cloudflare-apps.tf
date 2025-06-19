#======================================================
# Access for Infrastructure App
#======================================================
# Creating the Target
resource "cloudflare_zero_trust_access_infrastructure_target" "ssh_gcp_instance" {
  account_id = var.cloudflare_account_id
  hostname   = var.cf_target_name
  ip = {
    ipv4 = {
      ip_addr = var.gcp_vm_internal_ip
    }
  }
}

# Creating the infrastructure Application
resource "cloudflare_zero_trust_access_application" "ssh_gcp_infrastructure" {
  account_id       = var.cloudflare_account_id
  type             = "infrastructure"
  name             = var.cf_infra_app_name
  logo_url         = "https://upload.wikimedia.org/wikipedia/commons/0/01/Google-cloud-platform.svg"
  tags             = [cloudflare_zero_trust_access_tag.zero_trust_demo_tag.name]
  session_duration = "0s"

  target_criteria = [{
    port     = "22",
    protocol = "SSH"
    target_attributes = {
      hostname = [var.cf_target_name]
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
# SELF-HOSTED: AWS Database (Browser rendered SSH)
#======================================================
# Creating the Self-hosted Application for Browser rendering SSH
resource "cloudflare_zero_trust_access_application" "ssh_aws_browser_rendering" {
  account_id           = var.cloudflare_account_id
  type                 = "ssh"
  name                 = var.cf_browser_ssh_app_name
  app_launcher_visible = true
  logo_url             = "https://cdn.iconscout.com/icon/free/png-256/free-database-icon-download-in-svg-png-gif-file-formats--ui-elements-pack-user-interface-icons-444649.png"
  tags                 = [cloudflare_zero_trust_access_tag.zero_trust_demo_tag.name]
  session_duration     = "0s"

  destinations = [{
    type = "public"
    uri  = var.cf_subdomain_ssh
  }]

  allowed_idps                = [var.cf_okta_identity_provider_id, var.cf_otp_identity_provider_id]
  auto_redirect_to_identity   = false
  allow_authenticate_via_warp = false

  policies = [
    {
      decision = "allow"
      id       = cloudflare_zero_trust_access_policy.policies["employees_browser_rendering"].id
    },
    {
      decision = "allow"
      id       = cloudflare_zero_trust_access_policy.policies["contractors_browser_rendering"].id
    },
  ]
}

#======================================================
# SELF-HOSTED: AWS Browser Rendered VNC
#======================================================
# Creating the Self-hosted Application for Browser rendering VNC
resource "cloudflare_zero_trust_access_application" "vnc_aws_browser_rendering" {
  account_id           = var.cloudflare_account_id
  type                 = "vnc"
  name                 = var.cf_browser_vnc_app_name
  app_launcher_visible = true
  logo_url             = "https://blog.zwindler.fr/2015/07/vnc.png"
  tags                 = [cloudflare_zero_trust_access_tag.zero_trust_demo_tag.name]
  session_duration     = "0s"

  destinations = [{
    type = "public"
    uri  = var.cf_subdomain_vnc
  }]

  allowed_idps                = [var.cf_okta_identity_provider_id, var.cf_otp_identity_provider_id]
  auto_redirect_to_identity   = false
  allow_authenticate_via_warp = false

  policies = [
    {
      decision = "allow"
      id       = cloudflare_zero_trust_access_policy.policies["employees_browser_rendering"].id
    },
    {
      decision = "allow"
      id       = cloudflare_zero_trust_access_policy.policies["contractors_browser_rendering"].id
    },
  ]
}



#======================================================
# SELF-HOSTED App: Competition App
#======================================================
# Creating the Self-hosted Application for Competition web application
resource "cloudflare_zero_trust_access_application" "sensitive_web_server" {
  account_id           = var.cloudflare_account_id
  type                 = "self_hosted"
  name                 = var.cf_sensitive_web_app_name
  app_launcher_visible = true
  logo_url             = "https://img.freepik.com/free-vector/trophy_78370-345.jpg"
  tags                 = [cloudflare_zero_trust_access_tag.zero_trust_demo_tag.name]
  session_duration     = "0s"

  destinations = [{
    type = "public"
    uri  = var.cf_subdomain_web_sensitive
  }]

  allowed_idps                = [var.cf_okta_identity_provider_id]
  auto_redirect_to_identity   = true
  allow_authenticate_via_warp = false

  policies = [{
    decision = "allow"
    id       = cloudflare_zero_trust_access_policy.policies["sensitive_web_server"].id
  }]
}




#======================================================
# SELF-HOSTED App: Administration APP
#======================================================
# Creating the Self-hosted Application for Administration web application
resource "cloudflare_zero_trust_access_application" "administration_web_app" {
  account_id           = var.cloudflare_account_id
  type                 = "self_hosted"
  name                 = var.cf_admin_web_app_name
  app_launcher_visible = true
  logo_url             = "https://raw.githubusercontent.com/uditkumar489/Icon-pack/master/Entrepreneur/digital-marketing/svg/computer-1.svg"
  tags                 = [cloudflare_zero_trust_access_tag.zero_trust_demo_tag.name]
  session_duration     = "0s"

  destinations = [{
    type = "public"
    uri  = var.cf_subdomain_web
  }]

  allowed_idps                = [var.cf_okta_identity_provider_id]
  auto_redirect_to_identity   = true
  allow_authenticate_via_warp = false

  policies = [{
    decision = "allow"
    id       = cloudflare_zero_trust_access_policy.policies["web_app"].id
  }]
}
