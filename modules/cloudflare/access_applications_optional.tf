#======================================================
# OPTIONAL: Training Status Admin Portal Configuration
#======================================================
# This file is OPTIONAL and should only be used if you have deployed the
# "Training Compliance Gateway for Cloudflare Worker" application.
# 
# Repository: https://github.com/macharpe/cloudflare-access-training-evaluator
#
# This Cloudflare Worker application provides training status tracking and
# compliance evaluation capabilities for your Zero Trust environment.
# Only include this configuration if you plan to use the Training Compliance Gateway.
#
# NOTE: The resources are currently commented out due to API permission issues.
# To use these resources:
# 1. Ensure your Cloudflare API token has "Cloudflare Access:Edit" permissions
# 2. Uncomment the resources below by removing the /* and */ comment blocks
# 3. Run terraform apply
#======================================================

#======================================================
# Training Status Admin Portal Policy Terraform
#======================================================
resource "cloudflare_zero_trust_access_policy" "training_status_admin_policy" {
  account_id       = var.cloudflare_account_id
  decision         = "allow"
  name             = "Training Status Portal Admin Policy"
  session_duration = "24h"

  # Include admin groups using composite group
  include = [{
    group = {
      id = local.policy_groups["admins"]
    }
  }]

  # Require device posture and MFA
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

  # Exclude SMS authentication
  exclude = [{
    auth_method = {
      auth_method = "sms"
    }
  }]
}


#======================================================
# Training Status Admin Portal App Terraform
#======================================================
resource "cloudflare_zero_trust_access_application" "cf_app_training_portal" {
  account_id           = var.cloudflare_account_id
  type                 = "self_hosted"
  name                 = "Training Status Admin Portal"
  app_launcher_visible = true
  logo_url             = "https://cdn-icons-png.flaticon.com/512/6427/6427307.png"
  tags                 = [cloudflare_zero_trust_access_tag.zero_trust_demo_tag.name]
  session_duration     = "0s"

  # Multiple destinations matching the actual app configuration
  destinations = [
    {
      type = "public"
      uri  = "${var.cf_subdomain_training_status}/admin"
    },
    {
      type = "public"
      uri  = "${var.cf_subdomain_training_status}/api/*"
    },
    {
      type = "public"
      uri  = "${var.cf_subdomain_training_status}/admin*"
    },
    {
      type = "public"
      uri  = "${var.cf_subdomain_training_status}/init-db"
    }
  ]

  allowed_idps                = [var.cf_okta_identity_provider_id]
  auto_redirect_to_identity   = true
  allow_authenticate_via_warp = false

  policies = [{
    id = cloudflare_zero_trust_access_policy.training_status_admin_policy.id
  }]
}
