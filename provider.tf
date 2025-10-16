terraform {
  required_version = ">= 1.12.0"

  #  backend "local" {
  #   path = "tfstate/terraform.tfstate"
  # }

  backend "s3" {
    # Backend configuration is provided via backend.conf (gitignored for security)
    # Run: terraform init -backend-config=backend.conf
    # See backend.conf.example for template
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.10.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.4"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }

    external = {
      source = "hashicorp/external"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }

    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region

  default_labels = {
    environment = "dev"
    service     = "cloudflare-zero-trust-demo"
    owner       = "macharpe"
  }
}

provider "tls" {
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "azuread" {
}

provider "azurerm" {
  subscription_id = var.azure_subscription_id # Terraform local
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "dev"
      Service     = "cloudflare-zero-trust-demo"
      Owner       = "macharpe"
    }
  }
}

provider "http" {
}

provider "random" {}
