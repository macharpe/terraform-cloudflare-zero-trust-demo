#==========================================================
# Local Variables
#==========================================================
locals {
  # Precedence values - organized by policy type and purpose
  # Following Cloudflare best practices with 1000-spacing between major groups
  # Integrates with dashboard-managed policies (1000-3000, 5000-20000, 36000-40000)
  precedence = {
    # NETWORK (L4) Policies - Access Infrastructure Integration
    access_infra_target = 4000 # Access Infrastructure integration (between DNS groups)

    # NETWORK (L4) Policies - Zero Trust RDP Access Control
    rdp_admin_allow  = 21000 # Allow RDP for IT admins (identity-based)
    rdp_default_deny = 21700 # Default deny RDP (after allow, before lateral movement)

    # NETWORK (L4) Policies - Lateral Movement Prevention (East-West Traffic)
    block_lateral_ssh      = 22550 # Block SSH lateral movement
    block_lateral_rdp      = 22600 # Block RDP lateral movement
    block_lateral_smb      = 22200 # Block SMB lateral movement
    block_lateral_winrm    = 22300 # Block WinRM lateral movement
    block_lateral_database = 22400 # Block database lateral movement

    # NETWORK (L4) Policies - IP Access Control
    ip_access_block = 23000 # Block direct IP access to apps (force hostname-based access)

    # HTTP (L7) Policies - AI Application Governance
    ai_tools_redirect = 24000 # Redirect unreviewed AI tools to Claude
    chatgpt_allow_log = 24100 # Allow ChatGPT with prompt logging

    # HTTP (L7) Policies - Content Filtering & DLP
    pdf_block      = 25000 # Block PDF downloads for Sales Eng (identity-based DLP)
    gambling_block = 25100 # Block gambling websites (category blocking)
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
  # Following Cloudflare best practices with 1000-spacing between major groups
  # Integrates with dashboard-managed policies at precedence: 1000-3000, 5000-20000, 36000-40000
  gateway_policies = {
    #==========================================================
    # NETWORK (L4) POLICIES
    # Port/Protocol/IP-based filtering evaluated before HTTP policies
    # Terraform precedence ranges: 4000, 21000-23000
    # Dashboard precedence ranges: 1000-3000, 36000-37000
    #==========================================================

    # Access Infrastructure Integration (Precedence: 4000)
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

    # Zero Trust RDP Access Control (Precedence: 21000)
    rdp_admin_access = {
      name                 = "NETWORK-Allow: RDP - IT Admin Access Policy [Zero-Trust demo]"
      description          = "Allow RDP access for IT administrators with identity and device posture checks"
      enabled              = true
      action               = "allow"
      precedence           = local.precedence.rdp_admin_allow
      filters              = ["l4"]
      traffic              = "net.dst.ip == ${var.gcp_windows_vm_internal_ip} and net.dst.port == ${var.cf_domain_controller_rdp_port} and net.protocol == \"tcp\""
      identity             = "any(identity.saml_attributes[*] == \"groups=${var.okta_itadmin_saml_group_name}\") or any(identity.saml_attributes[*] == \"groups=${var.okta_infra_admin_saml_group_name}\")"
      device_posture       = "any(device_posture.checks.passed[*] == \"${var.cf_macos_posture_id}\") or any(device_posture.checks.passed[*] == \"${var.cf_windows_posture_id}\") or any(device_posture.checks.passed[*] == \"${var.cf_linux_posture_id}\")"
      notification_enabled = false
    }

    # Lateral Movement Prevention - East-West Traffic (Precedence: 22000-22400)
    block_lateral_ssh = {
      name                 = "NETWORK-Block: SSH Lateral Movement [Zero-Trust demo]"
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
      name                 = "NETWORK-Block: RDP Lateral Movement [Zero-Trust demo]"
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
      name                 = "NETWORK-Block: SMB Lateral Movement [Zero-Trust demo]"
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
      name                 = "NETWORK-Block: WinRM Lateral Movement [Zero-Trust demo]"
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
      name                 = "NETWORK-Block: Database Lateral Movement [Zero-Trust demo]"
      description          = "Block database connections between internal VMs for lateral movement prevention, while allowing direct database access from WARP clients"
      enabled              = true
      action               = "block"
      precedence           = local.precedence.block_lateral_database
      filters              = ["l4"]
      traffic              = "net.dst.port in {3306 5432 1433 1521 27017} and net.protocol == \"tcp\" and (net.dst.ip in {${var.aws_private_cidr} ${var.gcp_infra_cidr} ${var.gcp_windows_rdp_cidr} ${var.gcp_warp_cidr} ${var.azure_subnet_cidr}}) and (net.src.ip in {${var.aws_private_cidr} ${var.gcp_infra_cidr} ${var.gcp_windows_rdp_cidr} ${var.gcp_warp_cidr} ${var.azure_subnet_cidr}}) and not (net.src.ip in {${var.cf_warp_cgnat_cidr}})"
      block_reason         = "Database lateral movement blocked - use authorized methods"
      notification_enabled = true
    }

    # IP-based Access Control (Precedence: 23000)
    block_ip_access = {
      name                 = "NETWORK-Block: Access GCP Apps via Private IP [Zero-Trust demo]"
      description          = "This rule blocks the access of Competition App and Administration App via ip address and port"
      enabled              = true
      action               = "block"
      precedence           = local.precedence.ip_access_block
      filters              = ["l4"]
      traffic              = "(net.dst.ip == ${var.gcp_vm_internal_ip} and net.dst.port == ${var.cf_intranet_app_port}) or (net.dst.ip == ${var.gcp_vm_internal_ip} and net.dst.port == ${var.cf_competition_app_port})"
      block_reason         = "This website is blocked because you are trying to access an internal app via its IP address"
      notification_enabled = true
    }

    # Default Deny - Evaluated Last (Precedence: 21700)
    rdp_default_deny = {
      name                 = "NETWORK-Block: Default Deny Policy [Zero-Trust demo]"
      description          = "Deny RDP access for users without IT admin privileges (evaluated after allow policy)"
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
    # Terraform precedence ranges: 24000-25100
    # Dashboard precedence ranges: 13000-20000
    # Note: Dashboard Do-Not-Inspect policies (13000-15000) evaluated before Terraform HTTP policies
    #==========================================================

    # AI Application Governance (Precedence: 24000-24100)
    redirect_ai_to_claude = {
      name                 = "HTTP-Redirect: Redirect users to claude.ai [Zero-Trust demo]"
      description          = "Redirect any unreviewed AI application to claude.ai instead"
      enabled              = true
      action               = "redirect"
      precedence           = local.precedence.ai_tools_redirect
      filters              = ["http"]
      traffic              = "any(app.type.ids[*] in {25}) and any(app.statuses[*] == \"unreviewed\")"
      redirect_url         = "https://claude.ai"
      notification_enabled = false
    }

    # Content Filtering & DLP (Precedence: 25000-25100)
    block_pdf_download = {
      name                 = "HTTP-Block: PDF Files download [Zero-Trust demo]"
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

    block_gambling = {
      name                 = "HTTP-Block: Gambling websites [Zero-Trust demo]"
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

    allow_chatgpt_log = {
      name                 = "HTTP-Allow: ChatGPT logging [Zero-Trust demo]"
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
