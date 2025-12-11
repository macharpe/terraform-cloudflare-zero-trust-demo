#==========================================================
# Load Balancing Demo - Public Load Balancer
#==========================================================
# This file creates the Cloudflare Load Balancer configuration
# for the LB demo, including:
# - Health check monitor
# - Origin pool with AWS (DC1) and GCP (On-Prem) origins
# - Public load balancer
#
# Prerequisites:
# - lb_demo_enabled = true
# - Tunnels must be healthy (tunnels-lb.tf)
# - VMs must be running with nginx (vm-lb-aws.tf, vm-lb-gcp.tf)
#
# To remove: Delete this file and run terraform apply
#==========================================================

#==========================================================
# Health Check Monitor
#==========================================================
resource "cloudflare_load_balancer_monitor" "lb_demo_health_check" {
  count = var.lb_demo_enabled ? 1 : 0

  account_id     = var.cloudflare_account_id
  type           = "http"
  method         = "GET"
  path           = "/health"
  expected_codes = "2xx"
  expected_body  = "healthy"
  timeout        = 5
  interval       = 60
  retries        = 2
  description    = "Health check for Swiss Insurance LB Demo origins"

  header = {
    Host = ["${var.lb_subdomain}.${var.cf_domain}"]
  }
}

#==========================================================
# Origin Pool
#==========================================================
resource "cloudflare_load_balancer_pool" "lb_demo_pool" {
  count = var.lb_demo_enabled ? 1 : 0

  account_id  = var.cloudflare_account_id
  name        = "swiss-insurance-origins"
  description = "Origin pool for Swiss Insurance LB Demo (AWS DC1 + GCP On-Prem)"
  enabled     = true
  monitor     = cloudflare_load_balancer_monitor.lb_demo_health_check[0].id

  minimum_origins = 1

  origins = [
    {
      name    = "aws-dc1"
      address = "${cloudflare_zero_trust_tunnel_cloudflared.lb_tunnels["lb_aws_dc1"].id}.cfargotunnel.com"
      enabled = true
      weight  = 1
      port    = var.lb_web_port
      header = {
        Host = ["${var.lb_subdomain}.${var.cf_domain}"]
      }
    },
    {
      name    = "gcp-onprem"
      address = "${cloudflare_zero_trust_tunnel_cloudflared.lb_tunnels["lb_gcp_onprem"].id}.cfargotunnel.com"
      enabled = true
      weight  = 1
      port    = var.lb_web_port
      header = {
        Host = ["${var.lb_subdomain}.${var.cf_domain}"]
      }
    },
    {
      name    = "azure-dr"
      address = "${cloudflare_zero_trust_tunnel_cloudflared.lb_tunnels["lb_azure_dr"].id}.cfargotunnel.com"
      enabled = true
      weight  = 1
      port    = var.lb_web_port
      header = {
        Host = ["${var.lb_subdomain}.${var.cf_domain}"]
      }
    }
  ]

  # Health check regions - multiple regions for better coverage
  check_regions = ["WEU", "ENAM", "SEAS"]
}

#==========================================================
# Load Balancer
#==========================================================
resource "cloudflare_load_balancer" "lb_demo" {
  count = var.lb_demo_enabled ? 1 : 0

  zone_id     = var.cloudflare_zone_id
  name        = "${var.lb_subdomain}.${var.cf_domain}"
  description = "Swiss Insurance Load Balancer Demo"

  # Primary pool
  default_pools = [cloudflare_load_balancer_pool.lb_demo_pool[0].id]

  # Fallback pool (same as default for this demo)
  fallback_pool = cloudflare_load_balancer_pool.lb_demo_pool[0].id

  # Enable Cloudflare proxy for security and performance
  proxied = true

  # Session affinity - none for round-robin demo
  session_affinity = "none"

  # Steering policy - random for demo purposes
  # Options: "off", "geo", "random", "dynamic_latency", "proximity", "least_outstanding_requests", "least_connections"
  steering_policy = "random"

  # TTL for DNS - 1 second (minimum) for most frequent origin switching on refresh
  ttl = 1
}

#==========================================================
# Outputs
#==========================================================
output "lb_demo_hostname" {
  description = "Public hostname for the Load Balancer demo"
  value       = var.lb_demo_enabled ? "${var.lb_subdomain}.${var.cf_domain}" : null
}

output "lb_demo_pool_id" {
  description = "ID of the Load Balancer pool"
  value       = var.lb_demo_enabled ? cloudflare_load_balancer_pool.lb_demo_pool[0].id : null
}

output "lb_demo_monitor_id" {
  description = "ID of the Load Balancer health monitor"
  value       = var.lb_demo_enabled ? cloudflare_load_balancer_monitor.lb_demo_health_check[0].id : null
}
