resource "cloudflare_zero_trust_access_tag" "zero_trust_demo_tag" {
  account_id = var.cloudflare_account_id
  name       = var.cf_cloudflare_tag
}
