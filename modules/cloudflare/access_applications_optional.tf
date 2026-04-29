#======================================================
# OPTIONAL: Worker-backed Access Applications
#======================================================
# This file contains Access applications that front Cloudflare Workers
# deployed outside this Terraform repository. Each section is independent —
# only enable the sections relevant to Workers you have actually deployed.
#
# Applications in this file:
#   1. Training Status Admin Portal
#      Worker repo: https://github.com/macharpe/cloudflare-access-training-evaluator
#      Subdomain variable: cf_subdomain_training_status
#
#   2. Warning-to-RBI Audit Log Admin Portal
#      Worker repo: /Users/mcharpentier/Documents/2-github/cf-workers-projects/cf-warning-to-rbi/
#      Subdomain variable: cf_subdomain_rbi_warning
#      Routes protected: <subdomain>/admin and <subdomain>/admin*
#      Routes public:    <subdomain>/warn and <subdomain>/proceed (required by Gateway redirect flow)
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

  allowed_idps                = [var.cf_okta_new_identity_provider_id]
  auto_redirect_to_identity   = true
  allow_authenticate_via_warp = false

  policies = [{
    id = cloudflare_zero_trust_access_policy.training_status_admin_policy.id
  }]
}


#======================================================
# OPTIONAL: Warning-to-RBI Audit Log Admin Portal
#======================================================
# Only enable this section if you have deployed the Warning-to-RBI Worker.
#
# Worker repo: /Users/mcharpentier/Documents/2-github/cf-workers-projects/cf-warning-to-rbi/
# Deployed at: warning-to-rbi.macharpe.com
#
# The Worker /admin route reads the rbi-warning-audit-log KV namespace and
# renders a dashboard of all user proceed actions (who clicked through the
# warning page, to which site, and when).
#
# Protected paths: <subdomain>/admin and <subdomain>/admin*
# Public paths:    <subdomain>/warn and <subdomain>/proceed (by design —
#                  required for the Gateway redirect flow to work)
#
# Mirrors the training portal pattern: only /admin routes are Access-protected.
#======================================================

#======================================================
# Warning-to-RBI Audit Portal — Access Policy
#======================================================
resource "cloudflare_zero_trust_access_policy" "rbi_audit_admin_policy" {
  account_id       = var.cloudflare_account_id
  decision         = "allow"
  name             = "Warning-to-RBI Audit Log Admin Policy"
  session_duration = "24h"

  # Restrict to IT Admin + Infrastructure Admin (admins composite group)
  include = [{
    group = {
      id = local.policy_groups["admins"]
    }
  }]

  # Require device posture and MFA — same requirements as training portal
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
# Warning-to-RBI Audit Portal — Access Application
#======================================================
resource "cloudflare_zero_trust_access_application" "cf_app_rbi_audit_portal" {
  account_id           = var.cloudflare_account_id
  type                 = "self_hosted"
  name                 = "Warning-to-RBI Audit Log Portal"
  app_launcher_visible = true
  logo_url             = "https://pub-ff52653899f447f999d673ac6de72bb4.r2.dev/warning-to-rbi-access-app.jpg"
  tags                 = [cloudflare_zero_trust_access_tag.zero_trust_demo_tag.name]
  session_duration     = "24h"
  custom_deny_url              = "https://denied.macharpe.com/"
  custom_non_identity_deny_url = "https://denied.macharpe.com/"

  # Protect only the /admin routes — /warn and /proceed remain public by design
  destinations = [
    {
      type = "public"
      uri  = "${var.cf_subdomain_rbi_warning}/admin"
    },
    {
      type = "public"
      uri  = "${var.cf_subdomain_rbi_warning}/admin*"
    }
  ]

  allowed_idps                = [var.cf_okta_new_identity_provider_id]
  auto_redirect_to_identity   = true
  allow_authenticate_via_warp = false

  policies = [{
    id = cloudflare_zero_trust_access_policy.rbi_audit_admin_policy.id
  }]
}
