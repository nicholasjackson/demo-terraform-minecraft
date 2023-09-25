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

provider "vault" {
  address = var.vault_addr
  skip_child_token = true

  auth_login {
    path = "auth/${var.vault_approle_path}/login"
    namespace = "admin/${var.vault_namespace}"
    parameters = {
      role_id = var.vault_approle_id
      secret_id = var.vault_approle_secret_id
    }
  }
}

provider "boundary" {
  addr                   = var.boundary_addr
  auth_method_login_name = var.boundary_user
  auth_method_password   = var.boundary_password
}

provider "kubernetes" {
  host  = "https://${data.google_container_cluster.my_cluster.endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate,
  )
}