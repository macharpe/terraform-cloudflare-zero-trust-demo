#==========================================================
# Local Variables
#==========================================================
locals {
  # SAML groups from Okta
  saml_groups = {
    contractors          = var.okta_contractors_saml_group_name
    infrastructure_admin = var.okta_infra_admin_saml_group_name
    sales_engineering    = var.okta_sales_eng_saml_group_name
    sales                = var.okta_sales_saml_group_name
    it_admin             = var.okta_itadmin_saml_group_name
  }

  # Azure AD groups
  azure_groups = {
    azure_engineering    = var.azure_engineering_group_id
    azure_sales          = var.azure_sales_group_id
    azure_administrators = var.cf_azure_admin_rule_group_id
  }

  # Allowed countries
  allowed_countries = ["FR", "DE", "US", "GB"]
  blocked_countries = ["CN", "RU"]

  # OS posture checks
  os_posture_checks = [
    var.cf_linux_posture_id,
    var.cf_macos_posture_id,
    var.cf_windows_posture_id
  ]
}

#==================================================
# SAML Rule Groups
#===================================================
resource "cloudflare_zero_trust_access_group" "saml_groups" {
  for_each   = local.saml_groups
  account_id = var.cloudflare_account_id
  name       = each.value

  include = [{
    saml = {
      identity_provider_id = var.cf_okta_identity_provider_id
      attribute_name       = "groups"
      attribute_value      = each.value
    }
  }]
}

#==================================================
# Geographic Rule Groups
#===================================================
resource "cloudflare_zero_trust_access_group" "country_requirements_rule_group" {
  account_id = var.cloudflare_account_id
  name       = "Country Requirements"

  include = [
    for country in local.allowed_countries : {
      geo = {
        country_code = country
      }
    }
  ]
  exclude = [
    for country in local.blocked_countries : {
      geo = {
        country_code = country
      }
    }
  ]
}

#==================================================
# Device Posture Rule Groups
#===================================================
resource "cloudflare_zero_trust_access_group" "latest_os_version_requirements_rule_group" {
  account_id = var.cloudflare_account_id
  name       = "Latest OS Version Requirements"

  include = [
    for posture_id in local.os_posture_checks : {
      device_posture = {
        integration_uid = posture_id
      }
    }
  ]
}

#==================================================
# Composite Rule Groups
#===================================================
resource "cloudflare_zero_trust_access_group" "employees_rule_group" {
  account_id = var.cloudflare_account_id
  name       = "Employees"

  include = [
    for group_key in ["it_admin", "sales", "sales_engineering", "infrastructure_admin"] : {
      group = {
        id = cloudflare_zero_trust_access_group.saml_groups[group_key].id
      }
    }
  ]
}

resource "cloudflare_zero_trust_access_group" "sales_team_rule_group" {
  account_id = var.cloudflare_account_id
  name       = "Sales Team"

  include = [
    for group_key in ["sales", "sales_engineering"] : {
      group = {
        id = cloudflare_zero_trust_access_group.saml_groups[group_key].id
      }
    }
  ]
}

resource "cloudflare_zero_trust_access_group" "admins_rule_group" {
  account_id = var.cloudflare_account_id
  name       = "Administrators"

  include = [
    for group_key in ["it_admin", "infrastructure_admin"] : {
      group = {
        id = cloudflare_zero_trust_access_group.saml_groups[group_key].id
      }
    }
  ]
}

resource "cloudflare_zero_trust_access_group" "contractors_rule_group" {
  account_id = var.cloudflare_account_id
  name       = "Contractors Extended"

  include = [
    {
      group = {
        id = cloudflare_zero_trust_access_group.saml_groups["contractors"].id
      }
    },
    {
      email_domain = {
        domain = var.cf_email_domain
      }
    }
  ]
}

#==================================================
# Azure AD Rule Groups
#===================================================
resource "cloudflare_zero_trust_access_group" "azure_groups" {
  for_each   = local.azure_groups
  account_id = var.cloudflare_account_id
  name       = replace(title(replace(each.key, "_", " ")), "Azure", "Azure")

  include = [{
    azure_ad = {
      identity_provider_id = var.cf_azure_identity_provider_id
      id                   = each.value
    }
  }]
}
