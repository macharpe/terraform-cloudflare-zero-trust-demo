#==========================================================
# Gateway Categories Data Source
# Enables human-readable category names in policy definitions
# Reference: https://developers.cloudflare.com/cloudflare-one/traffic-policies/domain-categories/#terraform
#==========================================================
data "cloudflare_zero_trust_gateway_categories_list" "categories" {
  account_id = var.cloudflare_account_id
}

#==========================================================
# Local Variables
#==========================================================
locals {
  # Map category names to IDs for readable policy definitions
  # Usage: local.category_ids["Gambling"] instead of hardcoded 99
  category_ids = {
    for c in data.cloudflare_zero_trust_gateway_categories_list.categories.result :
    c.name => c.id
  }

  # Map subcategory names to IDs for granular filtering
  # Usage: local.subcategory_ids["Online Gambling"] for specific subcategories
  subcategory_ids = merge([
    for c in data.cloudflare_zero_trust_gateway_categories_list.categories.result :
    { for s in coalesce(c.subcategories, []) : s.name => s.id }
  ]...)

  # Application IDs for Gateway HTTP policies
  # Note: No data source available - these are hardcoded by Cloudflare
  # Reference: https://developers.cloudflare.com/cloudflare-one/traffic-policies/http-policies/granular-controls/
  app_ids = {
    claude  = 2430
    chatgpt = 1199
  }

  # Application Granular Control IDs
  # Note: No data source available - these are hardcoded by Cloudflare
  # Controls allow fine-grained actions like blocking uploads or prompts
  app_control_ids = {
    claude_prompt  = 2127 # Block/allow prompts to Claude
    chatgpt_upload = 1653 # Block/allow file uploads to ChatGPT
    chatgpt_prompt = 1652 # Block/allow prompts to ChatGPT
  }

  # Precedence values - organized by policy type and purpose
  # Following Cloudflare best practices with 1000-spacing between major groups
  # Dashboard-managed policies occupy: 1-11, 1000-3000, 6500-19000, 22000-22500, 36000-40000
  precedence = {
    # NETWORK (L4) Policies - Access Infrastructure Integration
    allow_access_infra = 4000 # Access Infrastructure integration (between DNS groups)

    # NETWORK (L4) Policies - Zero Trust RDP Access Control
    allow_rdp_admin = 21000 # Allow RDP for IT admins (identity-based)
    block_rdp_deny  = 21500 # Default deny RDP (after allow, before DNS rules at 22000-22500)

    # NETWORK (L4) Policies - Lateral Movement Prevention (East-West Traffic)
    # Note: Dashboard DNS rules occupy 22000-22500, so we start at 33000
    block_lateral_smb      = 33000 # Block SMB lateral movement
    block_lateral_winrm    = 34000 # Block WinRM lateral movement
    block_lateral_database = 35000 # Block database lateral movement
    block_lateral_ssh      = 35500 # Block SSH lateral movement (before VNC at 36000)
    block_lateral_rdp      = 35600 # Block RDP lateral movement

    # Note: Dashboard VNC rules at 36000-37000

    # NETWORK (L4) Policies - IP Access Control
    block_ip_access = 38000 # Block direct IP access to apps (force hostname-based access)

    # HTTP (L7) Policies - Warning-to-RBI Pattern
    # Inserted between block_ip_access (38000) and former block_gambling (39000)
    # Note: net.src.ip is L4-only. The correct HTTP-layer selector is http.conn.src_ip
    # per https://developers.cloudflare.com/cloudflare-one/traffic-policies/http-policies/
    # Note: Isolate policies are evaluated first by Gateway (before Allow/Block/Redirect)
    # regardless of their precedence number relative to other policy types.
    isolate_gambling_rbi        = 38300 # Isolate gambling sites for employees — disables print, copy & download in RBI session
    allow_rbi_traffic_exception = 38400 # Allow RBI egress re-evaluation — prevents double-isolation loop
    redirect_gambling_to_rbi    = 38800 # Redirect employees on gambling sites to Warning Worker
    block_gambling_contractors  = 39200 # Hard-block gambling for contractors (preserves original behavior)

    # HTTP (L7) Policies - AI Application Governance
    # Note: Dashboard Egress rule at 40000
    redirect_ai_tools  = 41000 # Redirect unreviewed AI tools to Claude
    block_genai_prompt = 42000 # Block sensitive data in GenAI prompts (DLP)
    allow_chatgpt_log  = 43000 # Allow ChatGPT with prompt logging
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
  # Dashboard-managed policies: 1-11, 1000-3000, 6500-19000, 22000-22500, 36000-40000
  gateway_policies = {
    #==========================================================
    # NETWORK (L4) POLICIES
    # Port/Protocol/IP-based filtering evaluated before HTTP policies
    # Terraform precedence ranges: 4000, 21000-21500, 33000-35600, 38000
    # Dashboard precedence ranges: 22000-22500 (DNS), 36000-37000 (VNC)
    #==========================================================

    # Access Infrastructure Integration (Precedence: 4000)
    allow_access_infra = {
      name                 = "NETWORK-Allow: Access Infra Target Policy"
      description          = "Evaluate Access applications before or after specific Gateway policies"
      enabled              = true
      action               = "allow"
      precedence           = local.precedence.allow_access_infra
      filters              = ["l4"]
      traffic              = "access.target"
      notification_enabled = false
    }

    # Zero Trust RDP Access Control (Precedence: 21000)
    allow_rdp_admin = {
      name                 = "NETWORK-Allow: RDP - IT Admin Access Policy [Zero-Trust demo]"
      description          = "Allow RDP access for IT administrators with identity and device posture checks"
      enabled              = true
      action               = "allow"
      precedence           = local.precedence.allow_rdp_admin
      filters              = ["l4"]
      traffic              = "net.dst.ip == ${var.gcp_windows_vm_internal_ip} and net.dst.port == ${var.cf_domain_controller_rdp_port} and net.protocol == \"tcp\""
      identity             = "any(identity.groups.name[*] in {\"${var.okta_itadmin_group_name}\"}) or any(identity.groups.name[*] in {\"${var.okta_infra_admin_group_name}\"})"
      device_posture       = "any(device_posture.checks.passed[*] == \"${var.cf_macos_posture_id}\") or any(device_posture.checks.passed[*] == \"${var.cf_windows_posture_id}\") or any(device_posture.checks.passed[*] == \"${var.cf_linux_posture_id}\")"
      notification_enabled = false
    }

    # Default RDP Deny (Precedence: 22000)
    block_rdp_deny = {
      name                 = "NETWORK-Block: RDP Default Deny Policy [Zero-Trust demo]"
      description          = "Deny RDP access for users without IT admin privileges (evaluated after allow policy)"
      enabled              = true
      action               = "block"
      precedence           = local.precedence.block_rdp_deny
      filters              = ["l4"]
      traffic              = "net.dst.ip == ${var.gcp_windows_vm_internal_ip} and net.dst.port == ${var.cf_domain_controller_rdp_port} and net.protocol == \"tcp\""
      block_reason         = "RDP access denied - insufficient privileges"
      notification_enabled = true
    }

    # Lateral Movement Prevention - East-West Traffic (Precedence: 33000-35600)
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

    # IP-based Access Control (Precedence: 38000)
    block_ip_access = {
      name                 = "NETWORK-Block: Access GCP Apps via Private IP [Zero-Trust demo]"
      description          = "This rule blocks the access of Competition App and Administration App via ip address and port"
      enabled              = true
      action               = "block"
      precedence           = local.precedence.block_ip_access
      filters              = ["l4"]
      traffic              = "(net.dst.ip == ${var.gcp_vm_internal_ip} and net.dst.port == ${var.cf_intranet_app_port}) or (net.dst.ip == ${var.gcp_vm_internal_ip} and net.dst.port == ${var.cf_competition_app_port})"
      block_reason         = "This website is blocked because you are trying to access an internal app via its IP address"
      notification_enabled = true
    }

    #==========================================================
    # HTTP (L7) POLICIES
    # Application/Content-based filtering
    # Terraform precedence ranges: 38400-39200 (Warning-to-RBI), 41000-43000 (AI)
    # Dashboard precedence ranges: 13000-19000, 40000 (Egress)
    # Note: Dashboard Do-Not-Inspect policies (13000-15000) evaluated before Terraform HTTP policies
    #==========================================================

    #==========================================================
    # HTTP (L7) POLICIES - Warning-to-RBI Pattern
    # Precedence: 38400 (allow RBI exception), 38800 (redirect), 39200 (contractor block)
    # Reference: 0-documentation/5-Roadmap/8-RBI/IMPL.md
    #
    # The allow exception uses http.conn.src_ip — the correct HTTP-layer Source IP
    # selector — NOT net.src.ip which is L4-only. This matches the pattern recommended
    # in the internal wiki (Daisuke Doi, page 1396049229).
    #==========================================================

    # Isolate gambling sites for employees — disables print + copy in RBI session (Precedence: 38300)
    # IMPORTANT: Gateway evaluates Isolate policies before Allow/Block/Redirect regardless of precedence.
    # To preserve the Warning Worker flow, this rule MUST be scoped to RBI egress IPs only
    # (http.conn.src_ip in {cf_rbi_source_cidr}), so it only fires on the second request
    # (after the user clicked "proceed" on the Warning Worker and was redirected into Clientless RBI).
    #
    # Correct flow:
    #   1. Initial request → Redirect (38800) fires → user sees Warning Worker
    #   2. User clicks proceed → Warning Worker redirects to Clientless RBI URL
    #   3. RBI egress IP makes request → Isolate fires (this rule) → biso_admin_controls applied
    #   4. Allow (38400) prevents re-evaluation loop on subsequent RBI requests
    #
    # Without the src_ip constraint, Isolate would fire on the initial request (step 1),
    # silently bypassing the Warning Worker and sending the user directly into RBI.
    isolate_gambling_rbi = {
      name                 = "HTTP-Isolate: Gambling — Disable Print, Copy & Download [RBI Warning Pattern]"
      description          = "Isolate gambling sites when accessed via Clientless RBI egress IPs. Disables printing, copy/paste, and file downloads. Scoped to RBI egress CIDR so the Warning Worker redirect fires first on initial requests."
      enabled              = true
      action               = "isolate"
      precedence           = local.precedence.isolate_gambling_rbi
      filters              = ["http"]
      traffic              = "http.conn.src_ip in {${var.cf_rbi_source_cidr}} and any(http.request.uri.content_category[*] in {${local.category_ids["Gambling"]}})"
      identity             = "any(identity.groups.name[*] in {\"${var.okta_infra_admin_group_name}\" \"${var.okta_sales_eng_group_name}\" \"${var.okta_sales_group_name}\" \"${var.okta_itadmin_group_name}\"})"
      notification_enabled = false
      # biso_admin_controls v1 API: true = restriction ON (capability disabled), false = restriction OFF (capability enabled)
      # Counterintuitive: "set to false to ENABLE" per provider schema — so true = DISABLE
      biso_admin_controls  = {
        dp  = true  # disable printing
        dcp = true  # disable copy-paste (remote → local clipboard)
        dd  = true  # disable download
      }
    }

    # Allow RBI egress re-evaluation — prevents double-isolation loop (Precedence: 38400)
    # http.conn.src_ip is the HTTP-layer Source IP selector (not net.src.ip which is L4-only)
    allow_rbi_traffic_exception = {
      name                 = "HTTP-Allow: RBI Clientless Browser Egress Exception [RBI Warning Pattern]"
      description          = "Allow HTTP traffic from Clientless RBI egress IPs targeting gambling sites. Prevents Gateway from re-matching the redirect policy and creating a double-isolation loop. Uses http.conn.src_ip (HTTP-layer selector) per Cloudflare docs."
      enabled              = true
      action               = "allow"
      precedence           = local.precedence.allow_rbi_traffic_exception
      filters              = ["http"]
      traffic              = "http.conn.src_ip in {${var.cf_rbi_source_cidr}} and any(http.request.uri.content_category[*] in {${local.category_ids["Gambling"]}})"
      identity             = "any(identity.groups.name[*] in {\"${var.okta_infra_admin_group_name}\" \"${var.okta_sales_eng_group_name}\" \"${var.okta_sales_group_name}\" \"${var.okta_itadmin_group_name}\"})"
      notification_enabled = false
    }

    # Redirect employees on gambling sites to Warning Worker (Precedence: 38800)
    redirect_gambling_to_rbi = {
      name                 = "HTTP-Redirect: Gambling → Warning Worker [RBI Warning Pattern]"
      description          = "Redirect employees accessing gambling-category sites to the Warning Worker. User is shown a warning page and may proceed to Clientless RBI."
      enabled              = true
      action               = "redirect"
      precedence           = local.precedence.redirect_gambling_to_rbi
      filters              = ["http"]
      traffic              = "any(http.request.uri.content_category[*] in {${local.category_ids["Gambling"]}})"
      identity             = "any(identity.groups.name[*] in {\"${var.okta_infra_admin_group_name}\" \"${var.okta_sales_eng_group_name}\" \"${var.okta_sales_group_name}\" \"${var.okta_itadmin_group_name}\"})"
      redirect_url         = var.cf_rbi_warning_worker_url
      include_context      = true
      notification_enabled = false
    }

    # Hard-block gambling for contractors — preserves original block_gambling behavior (Precedence: 39200)
    block_gambling_contractors = {
      name                 = "HTTP-Block: Gambling — Contractors Default Deny [Zero-Trust demo]"
      description          = "Hard-block gambling sites for contractors and Bob. Contractors do not receive the RBI warning flow."
      enabled              = true
      action               = "block"
      precedence           = local.precedence.block_gambling_contractors
      filters              = ["http"]
      traffic              = "any(http.request.uri.content_category[*] in {${local.category_ids["Gambling"]}})"
      identity             = "any(identity.groups.name[*] in {\"${var.okta_contractors_group_name}\"}) or identity.email == \"${var.okta_bob_user_login}\""
      block_reason         = "This website is blocked according to corporate policies (HTTP)"
      notification_enabled = true
    }

    # AI Application Governance (Precedence: 41000-43000)
    redirect_ai_to_claude = {
      name                 = "HTTP-Redirect: Redirect unapproved AI apps to Claude [AI Zero-Trust demo]"
      description          = "Redirect any unapproved AI application to claude.ai instead"
      enabled              = true
      action               = "redirect"
      precedence           = local.precedence.redirect_ai_tools
      filters              = ["http"]
      traffic              = "any(http.request.uri.content_category[*] in {${local.subcategory_ids["Artificial Intelligence"]}}) and any(app.statuses[*] == \"unapproved\")"
      redirect_url         = "https://claude.ai"
      notification_enabled = false
    }

    block_claude_prompt = {
      name                 = "HTTP-Block: Claude prompt control [AI Zero-Trust demo]"
      description          = "Stop sensitive information from ending up in Claude prompts"
      enabled              = true
      action               = "block"
      precedence           = local.precedence.block_genai_prompt
      filters              = ["http"]
      traffic              = "any(app.ids[*] == ${local.app_ids["claude"]}) and any(app_control.controls[*] in {${local.app_control_ids["claude_prompt"]}}) and any(dlp.profiles[*] in {\"${var.cf_dlp_profile_ai_prompt_ai_security}\" \"${var.cf_dlp_profile_ai_prompt_ai_customer}\" \"${var.cf_dlp_profile_ai_prompt_financial_information}\" \"${var.cf_dlp_profile_ai_prompt_pii}\" \"${var.cf_dlp_profile_ai_prompt_technical}\"})"
      block_reason         = "You cannot send sensitive data to AI applications"
      notification_enabled = true
      notification_msg     = "This action was blocked due to Claude prompt controls"
      gen_ai_prompt_log    = true # does not apply in Terraform
    }

    allow_chatgpt_log = {
      name                 = "HTTP-Allow: ChatGPT logging only [AI Zero-Trust demo]"
      description          = "Log ChatGPT requests"
      enabled              = true
      action               = "allow"
      precedence           = local.precedence.allow_chatgpt_log
      filters              = ["http"]
      traffic              = "any(app.ids[*] == ${local.app_ids["chatgpt"]}) and any(app_control.controls[*] in {${local.app_control_ids["chatgpt_prompt"]}}) and any(dlp.profiles[*] in {\"${var.cf_dlp_profile_ai_prompt_ai_security}\" \"${var.cf_dlp_profile_ai_prompt_ai_customer}\" \"${var.cf_dlp_profile_ai_prompt_financial_information}\" \"${var.cf_dlp_profile_ai_prompt_pii}\" \"${var.cf_dlp_profile_ai_prompt_technical}\"})"
      notification_enabled = false
      payload_log          = true
      gen_ai_prompt_log    = true # does not apply in Terraform
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
        msg     = try(each.value.notification_msg, try(each.value.block_reason, ""))
      }
      redirect = try(each.value.redirect_url, null) != null ? {
        target_uri              = each.value.redirect_url
        preserve_path_and_query = false
        include_context         = try(each.value.include_context, false)
      } : null
      gen_ai_prompt_log = try(each.value.gen_ai_prompt_log, null) != null ? {
        enabled = each.value.gen_ai_prompt_log
      } : null
      payload_log = try(each.value.payload_log, null) != null ? {
        enabled = each.value.payload_log
      } : null
      forensic_copy = try(each.value.forensic_copy, null) != null ? {
        enabled = each.value.forensic_copy
      } : null
      # biso_admin_controls: only set when policy defines it (isolate action only)
      # v1 API field names: dp=printing, dcp=copy, dd=download, du=upload, dk=keyboard
      # false = feature DISABLED, true = feature enabled (default)
      biso_admin_controls = try(each.value.biso_admin_controls, null) != null ? {
        dp  = try(each.value.biso_admin_controls.dp,  true)  # printing
        dcp = try(each.value.biso_admin_controls.dcp, true)  # copy-paste
        dd  = try(each.value.biso_admin_controls.dd,  true)  # download
        du  = try(each.value.biso_admin_controls.du,  true)  # upload
        dk  = try(each.value.biso_admin_controls.dk,  true)  # keyboard
      } : null
    }
  )
}
