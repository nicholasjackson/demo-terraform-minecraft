terraform {
  cloud {
    organization = "HashiCraft"

    workspaces {
      name = "app-dev"
    }
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.79.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.23.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    
    vault = {
      source = "hashicorp/vault"
      version = "3.20.0"
    }
    
    boundary = {
      source  = "hashicorp/boundary"
      version = "1.1.9"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.location
}

data "google_client_config" "provider" {}

data "google_container_cluster" "my_cluster" {
  name     = var.cluster
  location = var.location
}

# Fetch the Vault address and token from the HCP workspace remote state
data "terraform_remote_state" "hcp" {
  backend = "remote"

  config = {
    organization = "HashiCraft"
    workspaces = {
      name = "HCP"
    }
  }
}

provider "vault" {
  # Configuration options
  address = data.terraform_remote_state.hcp.outputs.vault_public_addr
  token   = data.terraform_remote_state.hcp.outputs.vault_admin_token
}

provider "boundary" {
  addr                   = data.terraform_remote_state.hcp.outputs.boundary_cluster_url
  auth_method_login_name = data.terraform_remote_state.hcp.outputs.boundary_cluster_user
  auth_method_password   = data.terraform_remote_state.hcp.outputs.boundary_cluster_password
}

provider "kubernetes" {
  host  = "https://${data.google_container_cluster.my_cluster.endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate,
  )
}








