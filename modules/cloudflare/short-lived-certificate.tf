#==================================================
# Short lived Certificate for Browser Rendered App
#===================================================
resource "cloudflare_zero_trust_access_short_lived_certificate" "zero_trust_access_short_lived_certificate_database_browser" {
  app_id  = cloudflare_zero_trust_access_application.cf_app_ssh_browser.id
  zone_id = var.cloudflare_zone_id
}
