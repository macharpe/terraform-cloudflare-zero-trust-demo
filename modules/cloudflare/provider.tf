terraform {
  required_version = ">= 1.12.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.10.0"
    }

    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }

    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
