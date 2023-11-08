terraform {
  cloud {
    organization = "HashiCraft"

    workspaces {
      name = "app-azure-dev"
    }
  }

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.79.0"
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

provider "azurerm" {
  skip_provider_registration = true # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  features {}
}

data "azurerm_kubernetes_cluster" "cluster" {
  name     = var.cluster
  resource_group_name = var.project
}

locals {
  vault_namespace = "admin/${var.environment}"
}

provider "vault" {
  address = var.vault_addr
  skip_child_token = true

  auth_login {
    path = "auth/${var.vault_approle_path}/login"
    namespace = local.vault_namespace
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
  host                   = data.azurerm_kubernetes_cluster.cluster.kube_config.0.host
  username               = data.azurerm_kubernetes_cluster.cluster.kube_config.0.username
  password               = data.azurerm_kubernetes_cluster.cluster.kube_config.0.password
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)
}