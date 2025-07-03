#==========================================================
# Local Variables
#==========================================================
locals {
  # Precedence values
  precedence = {
    access_infra_target = 5
    rdp_admin_allow     = 10
    pdf_block           = 170
    sfdc_setup_block    = 252
    ai_tools_block      = 335
    gambling_block      = 502
    ip_access_block     = 669
    rdp_default_deny    = 29000
  }

  # Common rule settings for block policies
  default_block_settings = {
    block_page_enabled                 = false
    ip_categories                      = false
    ip_indicator_feeds                 = false
    insecure_disable_dnssec_validation = false
  }

  # Gateway policies configuration
  gateway_policies = {
    access_infra_target = {
      name                 = "Access Infra Target Policy"
      description          = "Evaluate Access applications before or after specific Gateway policies"
      enabled              = true
      action               = "allow"
      precedence           = local.precedence.access_infra_target
      filters              = ["l4"]
      traffic              = "access.target"
      notification_enabled = false
    }
    rdp_admin_access = {
      name                 = "Zero-Trust demo RDP - IT Admin Access Policy"
      description          = "Allow RDP access for IT administrators"
      enabled              = true
      action               = "allow"
      precedence           = local.precedence.rdp_admin_allow
      filters              = ["l4"]
      traffic              = "net.dst.ip == ${var.gcp_windows_vm_internal_ip} and net.dst.port == ${var.cf_domain_controller_rdp_port} and net.protocol == \"tcp\""
      identity             = "any(identity.saml_attributes[*] == \"groups=${var.okta_itadmin_saml_group_name}\") or any(identity.saml_attributes[*] == \"groups=${var.okta_infra_admin_saml_group_name}\")"
      device_posture       = "any(device_posture.checks.passed[*] == \"${var.cf_macos_posture_id}\") or any(device_posture.checks.passed[*] == \"${var.cf_windows_posture_id}\") or any(device_posture.checks.passed[*] == \"${var.cf_linux_posture_id}\")"
      notification_enabled = false
    }
    block_pdf_download = {
      name                 = "Zero-Trust demo Block PDF Files download"
      description          = "Block Downloading PDF Files for Sales Engineering group"
      enabled              = false
      action               = "block"
      precedence           = local.precedence.pdf_block
      filters              = ["http"]
      traffic              = "any(http.download.file.types[*] in {\"pdf\"})"
      identity             = "any(identity.saml_attributes[*] == \"groups=${var.okta_sales_eng_saml_group_name}\")"
      block_reason         = "This download is blocked because it is a pdf file (not approved)"
      notification_enabled = true
    }
    block_sfdc_setup = {
      name                 = "Zero-Trust demo Block Access to \"Setup\" in Salesforce"
      description          = "Block the access to \"setup\" in salesforce.com"
      enabled              = true
      action               = "block"
      precedence           = local.precedence.sfdc_setup_block
      filters              = ["http"]
      traffic              = "http.request.uri == \"https://power-business-8049.lightning.force.com/lightning/setup/home?setupApp=all\" or http.request.uri == \"https://power-business-8049.lightning.force.com/lightning/setup/SetupOneHome/home\""
      block_reason         = "You are not allowed to access setup page on SFDC"
      notification_enabled = true
    }
    block_ai_tools = {
      name                 = "Zero-Trust demo Block Access to popular AI Tools"
      description          = "This rule blocks access to popular AI Tools"
      enabled              = false
      action               = "block"
      precedence           = local.precedence.ai_tools_block
      filters              = ["http"]
      traffic              = "any(app.type.ids[*] in {25})"
      block_reason         = "This website is blocked because it is considered an AI Tool not approved"
      notification_enabled = true
    }
    block_gambling = {
      name                 = "Zero-Trust demo Block Gambling websites"
      description          = "Block Gambling website according to corporate policies (HTTP)."
      enabled              = true
      action               = "block"
      precedence           = local.precedence.gambling_block
      filters              = ["http"]
      traffic              = "any(http.request.uri.content_category[*] in {99})"
      identity             = "not(any(identity.groups.name[*] in {\"${var.okta_contractors_saml_group_name}\"})) and not(identity.email == \"${var.okta_bob_user_login}\")"
      block_reason         = "This website is blocked according to corporate policies (HTTP)"
      notification_enabled = true
    }
    block_ip_access = {
      name                 = "Zero-Trust demo Blocking access GCP Apps via Private IP"
      description          = "This rule blocks the access of Competition App and Administration App via ip address and port"
      enabled              = true
      action               = "block"
      precedence           = local.precedence.ip_access_block
      filters              = ["l4"]
      traffic              = "(net.dst.ip == ${var.gcp_vm_internal_ip} and net.dst.port == ${var.cf_admin_web_app_port}) or (net.dst.ip == ${var.gcp_vm_internal_ip} and net.dst.port == ${var.cf_sensitive_web_app_port})"
      block_reason         = "This website is blocked because you are trying to access an internal app via its IP address"
      notification_enabled = true
    }
    rdp_default_deny = {
      name                 = "Zero-Trust demo RDP - Default Deny Policy"
      description          = "Deny RDP access for others"
      enabled              = true
      action               = "block"
      precedence           = local.precedence.rdp_default_deny
      filters              = ["l4"]
      traffic              = "net.dst.ip == ${var.gcp_windows_vm_internal_ip} and net.dst.port == ${var.cf_domain_controller_rdp_port} and net.protocol == \"tcp\""
      block_reason         = "RDP access denied - insufficient privileges"
      notification_enabled = true
    }
  }
}

#==========================================================
# Gateway Policies
#==========================================================
resource "cloudflare_zero_trust_gateway_policy" "policies" {
  for_each = local.gateway_policies

  account_id  = var.cloudflare_account_id
  name        = each.value.name
  description = each.value.description
  enabled     = each.value.enabled
  action      = each.value.action
  precedence  = each.value.precedence
  filters     = each.value.filters
  traffic     = each.value.traffic

  # Optional fields
  identity       = try(each.value.identity, null)
  device_posture = try(each.value.device_posture, null)

  rule_settings = merge(
    local.default_block_settings,
    {
      block_reason = try(each.value.block_reason, "")
      notification_settings = {
        enabled = try(each.value.notification_enabled, false)
        msg     = try(each.value.block_reason, "")
      }
    }
  )
}
