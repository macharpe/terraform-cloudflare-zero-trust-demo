#============================================================================
# Define precedence values that fit into your existing policy landscape
#============================================================================
locals {
  # RDP Admin Allow - needs to be very high priority but not conflict with precedence 1
  rdp_admin_allow_precedence = 10

  # Block policies - fit between existing ranges, avoiding conflicts
  pdf_block_precedence        = 170
  sfdc_setup_block_precedence = 252
  ai_tools_block_precedence   = 335
  gambling_block_precedence   = 502
  ip_access_block_precedence  = 669

  rdp_default_deny_precedence = 29000 # Before your 30000 range
}

#=======================================================================================
# Gateway Network Policy: Windows RDP Server - ALLOW FIRST
#=======================================================================================
resource "cloudflare_zero_trust_gateway_policy" "rdp_admin_access_policy" {
  account_id  = var.cloudflare_account_id
  name        = "Zero-Trust demo RDP - IT Admin Access Policy"
  description = "Allow RDP access for IT administrators"
  enabled     = true
  action      = "allow"
  precedence  = local.rdp_admin_allow_precedence

  filters = ["l4"]

  traffic        = "net.dst.ip == ${var.gcp_windows_vm_internal_ip} and net.dst.port == ${var.cf_domain_controller_rdp_port} and net.protocol == \"tcp\""
  identity       = "any(identity.saml_attributes[*] == \"groups=${var.okta_itadmin_saml_group_name}\") or any(identity.saml_attributes[*] == \"groups=${var.okta_infrastructureadmin_saml_group_name}\")"
  device_posture = "any(device_posture.checks.passed[*] == \"${var.cf_latest_macOS_version_posture_id}\") or any(device_posture.checks.passed[*] == \"${var.cf_latest_windows_version_posture_id}\") or any(device_posture.checks.passed[*] == \"${var.cf_latest_linux_kernel_version_posture_id}\")"

  rule_settings = {
    block_page_enabled                 = false
    insecure_disable_dnssec_validation = false
    notification_settings = {
      enabled = false
    }
  }
}

#======================================================
# Block pdf file download for specific groups
#======================================================
resource "cloudflare_zero_trust_gateway_policy" "block_pdf_file_download_policy" {
  account_id  = var.cloudflare_account_id
  name        = "Zero-Trust demo Block PDF Files download"
  description = "Block Downloading PDF Files for Sales Engineering group"
  enabled     = false
  action      = "block"
  precedence  = local.pdf_block_precedence

  filters = ["http"]

  traffic  = "any(http.download.file.types[*] in {\"pdf\"})"
  identity = "any(identity.saml_attributes[*] == \"groups=${var.okta_salesengineering_saml_group_name}\")"

  rule_settings = {
    block_page_enabled                 = false
    block_reason                       = "This download is blocked because it is a pdf file (not approved)"
    ip_categories                      = false
    ip_indicator_feeds                 = false
    insecure_disable_dnssec_validation = false
    notification_settings = {
      enabled = true
      msg     = "This download is blocked because it is a pdf file (not approved)"
    }
  }
}

#=======================================================================================
# Block access to setup pages in Salesforce.com
#=======================================================================================
resource "cloudflare_zero_trust_gateway_policy" "block_setup_page_sfdc_policy" {
  account_id  = var.cloudflare_account_id
  name        = "Zero-Trust demo Block Access to \"Setup\" in Salesforce"
  description = "Block the access to \"setup\" in salesforce.com"
  enabled     = true
  action      = "block"
  precedence  = local.sfdc_setup_block_precedence

  filters = ["http"]

  traffic = "http.request.uri == \"https://power-business-8049.lightning.force.com/lightning/setup/home?setupApp=all\" or http.request.uri == \"https://power-business-8049.lightning.force.com/lightning/setup/SetupOneHome/home\""

  rule_settings = {
    block_page_enabled                 = false
    block_reason                       = "You are not allowed to access setup page on SFDC"
    ip_categories                      = false
    ip_indicator_feeds                 = false
    insecure_disable_dnssec_validation = false
    notification_settings = {
      enabled = true
      msg     = "You are not allowed to access setup page on SFDC"
    }
  }
}

#=======================================================================================
# Block Popular AI Tools (Currently Disabled)
#=======================================================================================
resource "cloudflare_zero_trust_gateway_policy" "block_ai_tools_policy" {
  account_id  = var.cloudflare_account_id
  name        = "Zero-Trust demo Block Access to popular AI Tools"
  description = "This rule blocks access to popular AI Tools"
  enabled     = false # Currently disabled
  action      = "block"
  precedence  = local.ai_tools_block_precedence

  filters = ["http"]

  traffic = "any(app.type.ids[*] in {25})"

  rule_settings = {
    block_page_enabled                 = false
    block_reason                       = "This website is blocked because it is considered an AI Tool not approved"
    ip_categories                      = false
    ip_indicator_feeds                 = false
    insecure_disable_dnssec_validation = false
    notification_settings = {
      enabled = true
      msg     = "This website is blocked because it is considered an AI Tool not approved"
    }
  }
}

#=============================================================
# Block access to gambling site for everyone but Contractors
#=============================================================
resource "cloudflare_zero_trust_gateway_policy" "block_gambling_site_policy" {
  account_id  = var.cloudflare_account_id
  name        = "Zero-Trust demo Block Gambling websites"
  description = "Block Gambling website according to corporate policies (HTTP)."
  enabled     = true
  action      = "block"
  precedence  = local.gambling_block_precedence

  filters = ["http"]

  traffic  = "any(http.request.uri.content_category[*] in {99})"
  identity = "not(any(identity.groups.name[*] in {\"${var.okta_contractors_saml_group_name}\"})) and not(identity.email == \"${var.okta_bob_user_login}\")"

  rule_settings = {
    block_page_enabled                 = false
    block_reason                       = "This website is blocked according to corporate policies (HTTP)"
    ip_categories                      = false
    ip_indicator_feeds                 = false
    insecure_disable_dnssec_validation = false
    notification_settings = {
      enabled = true
      msg     = "This website is blocked according to corporate policies (HTTP)"
    }
  }
}

#=======================================================================================
# Block access via IP addresses and port to Application Competition and Administration
#=======================================================================================
resource "cloudflare_zero_trust_gateway_policy" "block_ip_access_to_internal_app_policy" {
  account_id  = var.cloudflare_account_id
  name        = "Zero-Trust demo Blocking access GCP Apps via Private IP"
  description = "This rule blocks the access of Competition App and Administration App via ip address and port"
  enabled     = true
  action      = "block"
  precedence  = local.ip_access_block_precedence

  filters = ["l4"]

  traffic = "(net.dst.ip == ${var.gcp_vm_internal_ip} and net.dst.port == ${var.cf_administration_web_app_port}) or (net.dst.ip == ${var.gcp_vm_internal_ip} and net.dst.port == ${var.cf_sensitive_web_app_port})"

  rule_settings = {
    block_page_enabled                 = false
    block_reason                       = "This website is blocked because you are trying to access an internal app via its IP address"
    ip_categories                      = false
    ip_indicator_feeds                 = false
    insecure_disable_dnssec_validation = false
    notification_settings = {
      enabled = true
      msg     = "This website is blocked because you are trying to access an internal app via its IP address"
    }
  }
}

#=======================================================================================
# Default Deny RDP Policy - MUST BE LAST
#=======================================================================================
resource "cloudflare_zero_trust_gateway_policy" "rdp_default_deny_policy" {
  account_id  = var.cloudflare_account_id
  name        = "Zero-Trust demo RDP - Default Deny Policy"
  description = "Deny RDP access for others"
  enabled     = true
  action      = "block"
  precedence  = local.rdp_default_deny_precedence

  filters = ["l4"]

  traffic = "net.dst.ip == ${var.gcp_windows_vm_internal_ip} and net.dst.port == ${var.cf_domain_controller_rdp_port} and net.protocol == \"tcp\""

  rule_settings = {
    block_page_enabled                 = false
    block_reason                       = "RDP access denied - insufficient privileges"
    insecure_disable_dnssec_validation = false
    notification_settings = {
      enabled = true
      msg     = "RDP access denied - insufficient privileges"
    }
  }
}
