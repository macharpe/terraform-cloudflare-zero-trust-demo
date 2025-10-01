#==========================================================
# Local Variables
#==========================================================
locals {
  # Precedence values - organized by policy type and purpose
  precedence = {
    # NETWORK (L4) Policies - Port/Protocol/IP-based filtering
    access_infra_target    = 5     # Access Infrastructure integration
    rdp_admin_allow        = 10    # Allow RDP for IT admins
    block_lateral_ssh      = 15    # Block SSH lateral movement
    block_lateral_rdp      = 20    # Block RDP lateral movement
    block_lateral_smb      = 25    # Block SMB lateral movement
    block_lateral_winrm    = 30    # Block WinRM lateral movement
    block_lateral_database = 35    # Block database lateral movement
    ip_access_block        = 669   # Block direct IP access to apps
    rdp_default_deny       = 29000 # Default deny RDP (lowest priority)

    # HTTP (L7) Policies - Application/Content-based filtering
    ai_tools_redirect = 170   # Redirect unreviewed AI tools to Claude
    pdf_block         = 180   # Block PDF downloads for Sales Eng
    gambling_block    = 502   # Block gambling websites
    chatgpt_allow_log = 12000 # Allow ChatGPT with prompt logging
  }


  # Common rule settings for block policies
  default_block_settings = {
    block_page_enabled                 = false
    ip_categories                      = false
    ip_indicator_feeds                 = false
    insecure_disable_dnssec_validation = false
  }

  # Gateway policies configuration
  # Organized by policy type: NETWORK (L4) policies first, then HTTP (L7) policies
  gateway_policies = {
    #==========================================================
    # NETWORK (L4) POLICIES
    # Port/Protocol/IP-based filtering evaluated before HTTP policies
    # Precedence range: 5 - 29000
    #==========================================================

    # Access Infrastructure Integration (Precedence: 5)
    access_infra_target = {
      name                 = "NETWORK-Allow: Access Infra Target Policy"
      description          = "Evaluate Access applications before or after specific Gateway policies"
      enabled              = true
      action               = "allow"
      precedence           = local.precedence.access_infra_target
      filters              = ["l4"]
      traffic              = "access.target"
      notification_enabled = false
    }

    # Allow Policies (Precedence: 10)
    rdp_admin_access = {
      name                 = "NETWORK-Allow: Zero-Trust demo RDP - IT Admin Access Policy"
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

    # Lateral Movement Prevention (Precedence: 15-35)
    block_lateral_ssh = {
      name                 = "NETWORK-Block: Zero-Trust demo Block SSH Lateral Movement"
      description          = "Block SSH connections between internal VMs for lateral movement prevention, while allowing direct SSH from WARP clients"
      enabled              = true
      action               = "block"
      precedence           = local.precedence.block_lateral_ssh
      filters              = ["l4"]
      traffic              = "net.dst.port == 22 and net.protocol == \"tcp\" and (net.dst.ip in {${var.aws_private_cidr} ${var.gcp_infra_cidr} ${var.gcp_windows_rdp_cidr} ${var.gcp_warp_cidr} ${var.azure_subnet_cidr}}) and (net.src.ip in {${var.aws_private_cidr} ${var.gcp_infra_cidr} ${var.gcp_windows_rdp_cidr} ${var.gcp_warp_cidr} ${var.azure_subnet_cidr}}) and not (net.src.ip in {${var.cf_warp_cgnat_cidr}})"
      block_reason         = "SSH lateral movement blocked - use authorized access methods or ensure device compliance"
      notification_enabled = true
    }
    block_lateral_rdp = {
      name                 = "NETWORK-Block: Zero-Trust demo Block RDP Lateral Movement"
      description          = "Block RDP connections between internal VMs for lateral movement prevention, while allowing direct RDP from WARP clients"
      enabled              = true
      action               = "block"
      precedence           = local.precedence.block_lateral_rdp
      filters              = ["l4"]
      traffic              = "net.dst.port == 3389 and net.protocol == \"tcp\" and (net.dst.ip in {${var.aws_private_cidr} ${var.gcp_infra_cidr} ${var.gcp_warp_cidr} ${var.azure_subnet_cidr}}) and (net.src.ip in {${var.aws_private_cidr} ${var.gcp_infra_cidr} ${var.gcp_windows_rdp_cidr} ${var.gcp_warp_cidr} ${var.azure_subnet_cidr}}) and not (net.src.ip in {${var.cf_warp_cgnat_cidr}})"
      block_reason         = "RDP lateral movement blocked - use authorized methods"
      notification_enabled = true
    }
    block_lateral_smb = {
      name                 = "NETWORK-Block: Zero-Trust demo Block SMB Lateral Movement"
      description          = "Block SMB/CIFS connections between internal VMs for lateral movement prevention, while allowing direct SMB from WARP clients"
      enabled              = true
      action               = "block"
      precedence           = local.precedence.block_lateral_smb
      filters              = ["l4"]
      traffic              = "net.dst.port in {445 139} and net.protocol == \"tcp\" and (net.dst.ip in {${var.aws_private_cidr} ${var.gcp_infra_cidr} ${var.gcp_windows_rdp_cidr} ${var.gcp_warp_cidr} ${var.azure_subnet_cidr}}) and (net.src.ip in {${var.aws_private_cidr} ${var.gcp_infra_cidr} ${var.gcp_windows_rdp_cidr} ${var.gcp_warp_cidr} ${var.azure_subnet_cidr}}) and not (net.src.ip in {${var.cf_warp_cgnat_cidr}})"
      block_reason         = "SMB lateral movement blocked - use authorized methods"
      notification_enabled = true
    }
    block_lateral_winrm = {
      name                 = "NETWORK-Block: Zero-Trust demo Block WinRM Lateral Movement"
      description          = "Block WinRM connections between internal VMs for lateral movement prevention, while allowing direct WinRM from WARP clients"
      enabled              = true
      action               = "block"
      precedence           = local.precedence.block_lateral_winrm
      filters              = ["l4"]
      traffic              = "net.dst.port in {5985 5986} and net.protocol == \"tcp\" and (net.dst.ip in {${var.aws_private_cidr} ${var.gcp_infra_cidr} ${var.gcp_windows_rdp_cidr} ${var.gcp_warp_cidr} ${var.azure_subnet_cidr}}) and (net.src.ip in {${var.aws_private_cidr} ${var.gcp_infra_cidr} ${var.gcp_windows_rdp_cidr} ${var.gcp_warp_cidr} ${var.azure_subnet_cidr}}) and not (net.src.ip in {${var.cf_warp_cgnat_cidr}})"
      block_reason         = "WinRM lateral movement blocked - use authorized methods"
      notification_enabled = true
    }
    block_lateral_database = {
      name                 = "NETWORK-Block: Zero-Trust demo Block Database Lateral Movement"
      description          = "Block database connections between internal VMs for lateral movement prevention, while allowing direct database access from WARP clients"
      enabled              = true
      action               = "block"
      precedence           = local.precedence.block_lateral_database
      filters              = ["l4"]
      traffic              = "net.dst.port in {3306 5432 1433 1521 27017} and net.protocol == \"tcp\" and (net.dst.ip in {${var.aws_private_cidr} ${var.gcp_infra_cidr} ${var.gcp_windows_rdp_cidr} ${var.gcp_warp_cidr} ${var.azure_subnet_cidr}}) and (net.src.ip in {${var.aws_private_cidr} ${var.gcp_infra_cidr} ${var.gcp_windows_rdp_cidr} ${var.gcp_warp_cidr} ${var.azure_subnet_cidr}}) and not (net.src.ip in {${var.cf_warp_cgnat_cidr}})"
      block_reason         = "Database lateral movement blocked - use authorized methods"
      notification_enabled = true
    }

    # IP-based Access Control (Precedence: 669)
    block_ip_access = {
      name                 = "NETWORK-Block: Zero-Trust demo Blocking access GCP Apps via Private IP"
      description          = "This rule blocks the access of Competition App and Administration App via ip address and port"
      enabled              = true
      action               = "block"
      precedence           = local.precedence.ip_access_block
      filters              = ["l4"]
      traffic              = "(net.dst.ip == ${var.gcp_vm_internal_ip} and net.dst.port == ${var.cf_intranet_app_port}) or (net.dst.ip == ${var.gcp_vm_internal_ip} and net.dst.port == ${var.cf_competition_app_port})"
      block_reason         = "This website is blocked because you are trying to access an internal app via its IP address"
      notification_enabled = true
    }

    # Default Deny - Evaluated Last (Precedence: 29000)
    rdp_default_deny = {
      name                 = "NETWORK-Block: Zero-Trust demo RDP - Default Deny Policy"
      description          = "Deny RDP access for others"
      enabled              = true
      action               = "block"
      precedence           = local.precedence.rdp_default_deny
      filters              = ["l4"]
      traffic              = "net.dst.ip == ${var.gcp_windows_vm_internal_ip} and net.dst.port == ${var.cf_domain_controller_rdp_port} and net.protocol == \"tcp\""
      block_reason         = "RDP access denied - insufficient privileges"
      notification_enabled = true
    }

    #==========================================================
    # HTTP (L7) POLICIES
    # Application/Content-based filtering
    # Precedence range: 170 - 12000
    #==========================================================

    # AI Application Control (Precedence: 170)
    redirect_ai_to_claude = {
      name                 = "HTTP-Redirect: Zero-Trust demo Redirect users to claude.ai"
      description          = "Redirect any unreviewed AI application to claude.ai instead"
      enabled              = true
      action               = "redirect"
      precedence           = local.precedence.ai_tools_redirect
      filters              = ["http"]
      traffic              = "any(app.type.ids[*] in {25}) and any(app.statuses[*] == \"unreviewed\")"
      redirect_url         = "https://claude.ai"
      notification_enabled = false
    }

    # Content Filtering (Precedence: 180)
    block_pdf_download = {
      name                 = "HTTP-Block: Zero-Trust demo Block PDF Files download"
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

    # Category Blocking (Precedence: 502)
    block_gambling = {
      name                 = "HTTP-Block: Zero-Trust demo Block Gambling websites"
      description          = "Block Gambling website according to corporate policies (HTTP)."
      enabled              = true
      action               = "block"
      precedence           = local.precedence.gambling_block
      filters              = ["http"]
      traffic              = "any(http.request.uri.content_category[*] in {99})"
      identity             = "not(any(identity.saml_attributes[*] == \"groups=${var.okta_contractors_saml_group_name}\")) or not(identity.email == \"${var.okta_bob_user_login}\")"
      block_reason         = "This website is blocked according to corporate policies (HTTP)"
      notification_enabled = true
    }

    # AI Application Logging (Precedence: 12000)
    allow_chatgpt_log = {
      name                 = "HTTP-Allow: Zero-Trust demo ChatGPT [log-only]"
      description          = "Log ChatGPT requests"
      enabled              = true
      action               = "allow"
      precedence           = local.precedence.chatgpt_allow_log
      filters              = ["http"]
      traffic              = "any(app.ids[*] == 1199) and any(app_control.controls[*] in {1652})"
      notification_enabled = false
      gen_ai_prompt_log    = true
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
      redirect = try(each.value.redirect_url, null) != null ? {
        target_uri              = each.value.redirect_url
        preserve_path_and_query = false
        include_context         = false
      } : null
      gen_ai_prompt_log = try(each.value.gen_ai_prompt_log, null) != null ? {
        enabled = each.value.gen_ai_prompt_log
      } : null
    }
  )
}
