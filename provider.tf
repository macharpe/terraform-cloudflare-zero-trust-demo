terraform {
  required_version = ">= 1.12.0"

  backend "local" {
    path = "tfstate/terraform.tfstate"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.5.0"
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
      version = "~> 5.0"
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
  api_key = var.cloudflare_api_key
  email   = var.cloudflare_email
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
