
data "terraform_remote_state" "hcp" {
  backend = "remote"

  config = {
    organization = "HashiCraft"
    workspaces = {
      name = "HCP"
    }
  }
}

terraform {
  cloud {
    organization = "HashiCraft"

    workspaces {
      name = "core-infra"
    }
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.79.0"
    }

    boundary = {
      source  = "hashicorp/boundary"
      version = "1.1.9"
    }

    vault = {
      source  = "hashicorp/vault"
      version = "3.20.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.location
}

provider "boundary" {
  addr                   = data.terraform_remote_state.hcp.outputs.boundary_cluster_url
  auth_method_login_name = data.terraform_remote_state.hcp.outputs.boundary_cluster_user
  auth_method_password   = data.terraform_remote_state.hcp.outputs.boundary_cluster_password
}

provider "vault" {
  # Configuration options
  address = data.terraform_remote_state.hcp.outputs.vault_public_addr
  token   = data.terraform_remote_state.hcp.outputs.vault_admin_token
}
