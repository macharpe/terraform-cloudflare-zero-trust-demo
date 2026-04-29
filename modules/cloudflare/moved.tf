#======================================================
# Moved Blocks — Resource Renames
# These blocks tell Terraform that resources were renamed
# in code but should not be destroyed and recreated.
#======================================================

# Renamed from saml_groups to okta_oidc_groups after migration from SAML to OIDC.
# The Okta integration now uses OIDC, making "saml_groups" a misleading name.
moved {
  from = cloudflare_zero_trust_access_group.saml_groups["contractors"]
  to   = cloudflare_zero_trust_access_group.okta_oidc_groups["contractors"]
}

moved {
  from = cloudflare_zero_trust_access_group.saml_groups["infrastructure_admin"]
  to   = cloudflare_zero_trust_access_group.okta_oidc_groups["infrastructure_admin"]
}

moved {
  from = cloudflare_zero_trust_access_group.saml_groups["sales_engineering"]
  to   = cloudflare_zero_trust_access_group.okta_oidc_groups["sales_engineering"]
}

moved {
  from = cloudflare_zero_trust_access_group.saml_groups["sales"]
  to   = cloudflare_zero_trust_access_group.okta_oidc_groups["sales"]
}

moved {
  from = cloudflare_zero_trust_access_group.saml_groups["it_admin"]
  to   = cloudflare_zero_trust_access_group.okta_oidc_groups["it_admin"]
}
