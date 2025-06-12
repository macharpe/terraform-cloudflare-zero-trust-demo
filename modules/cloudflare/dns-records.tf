# DNS Record creation web.macharpe.com
resource "cloudflare_dns_record" "tunnel_dns_web" {
  name     = var.cf_subdomain_web
  content  = "${cloudflare_zero_trust_tunnel_cloudflared.gcp_cloudflared_tunnel.id}.cfargotunnel.com"
  proxied  = true
  ttl      = 1
  type     = "CNAME"
  zone_id  = var.cloudflare_zone_id
  settings = {}
}


# DNS Record creation web-sensitive.macharpe.com
resource "cloudflare_dns_record" "tunnel_dns_web_sensitive" {
  name     = var.cf_subdomain_web_sensitive
  content  = "${cloudflare_zero_trust_tunnel_cloudflared.gcp_cloudflared_tunnel.id}.cfargotunnel.com"
  proxied  = true
  ttl      = 1
  type     = "CNAME"
  zone_id  = var.cloudflare_zone_id
  settings = {}
}


# DNS Record creation ssh-database.macharpe.com
resource "cloudflare_dns_record" "tunnel_dns_ssh" {
  name     = var.cf_subdomain_ssh
  content  = "${cloudflare_zero_trust_tunnel_cloudflared.aws_cloudflared_tunnel.id}.cfargotunnel.com"
  proxied  = true
  ttl      = 1
  type     = "CNAME"
  zone_id  = var.cloudflare_zone_id
  settings = {}
}


# DNS Record creation vnc.macharpe.com
resource "cloudflare_dns_record" "tunnel_dns_vnc" {
  name     = var.cf_subdomain_vnc
  content  = "${cloudflare_zero_trust_tunnel_cloudflared.aws_cloudflared_tunnel.id}.cfargotunnel.com"
  proxied  = true
  ttl      = 1
  type     = "CNAME"
  zone_id  = var.cloudflare_zone_id
  settings = {}
}
