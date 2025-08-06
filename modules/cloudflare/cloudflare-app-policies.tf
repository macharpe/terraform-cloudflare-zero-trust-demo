#==========================================================
# Local Variables
#==========================================================
locals {
  # Group mapping for policies (supports both SAML and composite groups)
  policy_groups = {
    # Composite groups
    employees   = cloudflare_zero_trust_access_group.employees_rule_group.id
    sales_team  = cloudflare_zero_trust_access_group.sales_team_rule_group.id
    admins      = cloudflare_zero_trust_access_group.admins_rule_group.id
    contractors = cloudflare_zero_trust_access_group.contractors_rule_group.id
    
    # Individual SAML groups
    infrastructure_admin = cloudflare_zero_trust_access_group.saml_groups["infrastructure_admin"].id
    sales_engineering    = cloudflare_zero_trust_access_group.saml_groups["sales_engineering"].id
    sales                = cloudflare_zero_trust_access_group.saml_groups["sales"].id
    it_admin             = cloudflare_zero_trust_access_group.saml_groups["it_admin"].id
  }

  # Common access policy configurations
  access_policies = {
    intranet_web_app = {
      name                  = "Intranet App Policy"
      include_groups        = ["employees", "contractors"]
      require_posture       = true
      require_mfa           = false
      purpose_justification = false
    }
    competition_web_app = {
      name                            = "Competition App Policy"
      include_groups                  = ["sales_team"]
      require_posture                 = true
      require_mfa                     = true
      purpose_justification           = true
      purpose_justification_prompt    = "Please enter a justification for entering this protected domain."
      lifecycle_create_before_destroy = true
    }
    employees_browser_rendering = {
      name                         = "Employees AWS Database Policy"
      include_groups               = ["infrastructure_admin"]
      require_posture              = true
      require_mfa                  = false
      purpose_justification        = true
      purpose_justification_prompt = "Please enter a justification as this is a production Application."
      require_login_method         = true
    }
    contractors_browser_rendering = {
      name                         = "Contractors AWS Database Policy"
      include_groups               = ["contractors"]
      require_posture              = true
      require_mfa                  = false
      purpose_justification        = true
      purpose_justification_prompt = "Please enter a justification as this is a production Application."
    }
    aws = {
      name            = "AWS Cloud Policy"
      include_groups  = ["sales_engineering"]
      require_posture = true
      require_mfa     = true
    }
    salesforce = {
      name               = "Salesforce Policy"
      include_groups     = ["sales_team"]
      require_posture    = true
      require_mfa        = true
      require_country    = true
      require_os_version = true
    }
    okta = {
      name            = "Okta Policy"
      include_groups  = ["it_admin"]
      require_posture = true
      require_mfa     = true
    }
    meraki = {
      name            = "Meraki Policy"
      include_groups  = ["it_admin"]
      require_posture = true
      require_mfa     = true
    }
  }
}

#==========================================================
# Access Policies
#==========================================================
resource "cloudflare_zero_trust_access_policy" "policies" {
  for_each = local.access_policies

  account_id       = var.cloudflare_account_id
  decision         = "allow"
  name             = each.value.name
  session_duration = "0s"

  # Purpose justification
  purpose_justification_prompt   = try(each.value.purpose_justification_prompt, null)
  purpose_justification_required = try(each.value.purpose_justification, false)

  # Include groups
  include = concat(
    # Groups (both SAML and composite groups via mapping)
    [
      for group in each.value.include_groups : {
        group = {
          id = local.policy_groups[group]
        }
      }
    ],
    # Email domain (for contractors)
    try(each.value.include_email_domain, false) ? [{
      email_domain = {
        domain = var.cf_email_domain
      }
    }] : []
  )

  # Require conditions
  require = concat(
    # Device posture (always required if specified)
    try(each.value.require_posture, false) ? [{
      device_posture = {
        integration_uid = var.cf_gateway_posture_id
      }
    }] : [],
    # MFA requirement
    try(each.value.require_mfa, false) ? [{
      auth_method = {
        auth_method = "mfa"
      }
    }] : [],
    # Login method (for specific policies)
    try(each.value.require_login_method, false) ? [{
      login_method = {
        id = var.cf_okta_identity_provider_id
      }
    }] : [],
    # Country requirements
    try(each.value.require_country, false) ? [{
      group = {
        id = cloudflare_zero_trust_access_group.country_requirements_rule_group.id
      }
    }] : [],
    # OS version requirements
    try(each.value.require_os_version, false) ? [{
      group = {
        id = cloudflare_zero_trust_access_group.latest_os_version_requirements_rule_group.id
      }
    }] : []
  )

  # Exclude SMS (for MFA policies)
  exclude = try(each.value.require_mfa, false) ? [{
    auth_method = {
      auth_method = "sms"
    }
  }] : []

  # Note: lifecycle blocks cannot be conditional in for_each resources
}
