#======================================================
# POLICY For Web app
#======================================================
resource "cloudflare_zero_trust_access_policy" "web_app_policy" {
  account_id       = var.cloudflare_account_id
  decision         = "allow"
  name             = "Administration Web App Policy"
  session_duration = "0s"

  include = [{
    group = {
      id = cloudflare_zero_trust_access_group.it_admin_rule_group.id
    }
  }]
  require = [{
    device_posture = {
      integration_uid = var.cf_gateway_posture_id
    }
  }]
}


#======================================================
# POLICY For Sensitive web app
#======================================================
resource "cloudflare_zero_trust_access_policy" "sensitive_web_server_policy" {
  account_id       = var.cloudflare_account_id
  decision         = "allow"
  name             = "Competition App Policy"
  session_duration = "0s"

  purpose_justification_prompt   = "Please enter a justification for entering this protected domain."
  purpose_justification_required = true

  include = [
    {
      group = {
        id = cloudflare_zero_trust_access_group.sales_rule_group.id
      }
    },
    {
      group = {
        id = cloudflare_zero_trust_access_group.sales_engineering_rule_group.id
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

  exclude = [{
    auth_method = {
      auth_method = "sms"
    }
  }]

  lifecycle {
    create_before_destroy = true
  }
}



#======================================================
# POLICY for Employees AWS Browser Rendering
#======================================================
resource "cloudflare_zero_trust_access_policy" "employees_browser_rendering_policy" {
  account_id       = var.cloudflare_account_id
  decision         = "allow"
  name             = "Employees AWS Database Policy"
  session_duration = "0s"

  purpose_justification_prompt   = "Please enter a justification as this is a production Application."
  purpose_justification_required = true

  include = [
    {
      group = {
        id = cloudflare_zero_trust_access_group.infrastructure_admin_rule_group.id
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
      login_method = {
        id = var.cf_okta_identity_provider_id
      }
    }
  ]
}



#======================================================
# POLICY for Contractors AWS Browser SSH database
#======================================================
resource "cloudflare_zero_trust_access_policy" "contractors_browser_rendering_policy" {
  account_id       = var.cloudflare_account_id
  decision         = "allow"
  name             = "Contractors AWS Database Policy"
  session_duration = "0s"

  purpose_justification_prompt   = "Please enter a justification as this is a production Application."
  purpose_justification_required = true

  include = [
    {
      email_domain = {
        domain = var.cf_email_domain
      }
    },
    {
      group = {
        id = cloudflare_zero_trust_access_group.contractors_rule_group.id
      }
    }
  ]

  require = [
    {
      device_posture = {
        integration_uid = var.cf_gateway_posture_id
      }
    },
  ]
}


#======================================================
# POLICY for AWS Cloud
#======================================================
resource "cloudflare_zero_trust_access_policy" "aws_policy" {
  account_id       = var.cloudflare_account_id
  decision         = "allow"
  name             = "AWS Cloud Policy"
  session_duration = "0s"

  include = [
    {
      group = {
        id = cloudflare_zero_trust_access_group.sales_engineering_rule_group.id
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

  exclude = [{
    auth_method = {
      auth_method = "sms"
    }
  }]
}



#======================================================
# POLICY for Salesforce
#======================================================
resource "cloudflare_zero_trust_access_policy" "salesforce_policy" {
  account_id       = var.cloudflare_account_id
  decision         = "allow"
  name             = "Salesforce Policy"
  session_duration = "0s"

  include = [
    {
      group = {
        id = cloudflare_zero_trust_access_group.sales_rule_group.id
      }
    },
    {
      group = {
        id = cloudflare_zero_trust_access_group.sales_engineering_rule_group.id
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
      group = {
        id = cloudflare_zero_trust_access_group.country_requirements_rule_group.id
      }
    },
    {
      group = {
        id = cloudflare_zero_trust_access_group.latest_os_version_requirements_rule_group.id
      }
    },
    {
      auth_method = {
        auth_method = "mfa"
      }
    }
  ]

  exclude = [{
    auth_method = {
      auth_method = "sms"
    }
  }]
}


#======================================================
# POLICY for Okta
#======================================================
resource "cloudflare_zero_trust_access_policy" "okta_policy" {
  account_id       = var.cloudflare_account_id
  decision         = "allow"
  name             = "Okta Policy"
  session_duration = "0s"

  include = [
    {
      group = {
        id = cloudflare_zero_trust_access_group.it_admin_rule_group.id
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

  exclude = [{
    auth_method = {
      auth_method = "sms"
    }
  }]
}


#======================================================
# POLICY for Meraki
#======================================================
resource "cloudflare_zero_trust_access_policy" "meraki_policy" {
  account_id       = var.cloudflare_account_id
  decision         = "allow"
  name             = "Meraki Policy"
  session_duration = "0s"

  include = [
    {
      group = {
        id = cloudflare_zero_trust_access_group.it_admin_rule_group.id
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

  exclude = [{
    auth_method = {
      auth_method = "sms"
    }
  }]
}
