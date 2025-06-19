#==========================================================
# Local Variables
#==========================================================
locals {
  dns_records = {
    web = {
      subdomain = var.cf_subdomain_web
      tunnel_id = cloudflare_zero_trust_tunnel_cloudflared.tunnels["gcp_infrastructure"].id
    }
    web_sensitive = {
      subdomain = var.cf_subdomain_web_sensitive
      tunnel_id = cloudflare_zero_trust_tunnel_cloudflared.tunnels["gcp_infrastructure"].id
    }
    ssh = {
      subdomain = var.cf_subdomain_ssh
      tunnel_id = cloudflare_zero_trust_tunnel_cloudflared.tunnels["aws_browser_rendering"].id
    }
    vnc = {
      subdomain = var.cf_subdomain_vnc
      tunnel_id = cloudflare_zero_trust_tunnel_cloudflared.tunnels["aws_browser_rendering"].id
    }
  }
}

#==========================================================
# DNS Records
#==========================================================
resource "cloudflare_dns_record" "tunnel_dns" {
  for_each = local.dns_records

  name     = each.value.subdomain
  content  = "${each.value.tunnel_id}.cfargotunnel.com"
  proxied  = true
  ttl      = 1
  type     = "CNAME"
  zone_id  = var.cloudflare_zone_id
  settings = {}
}
