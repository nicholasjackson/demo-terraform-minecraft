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
      name = "core-infrastructure-azure"
    }
  }

  required_providers {
    boundary = {
      source  = "hashicorp/boundary"
      version = "1.1.9"
    }

    vault = {
      source  = "hashicorp/vault"
      version = "3.20.0"
    }

    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.79.0"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  features {}
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

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.cluster.kube_config.0.host
  username               = azurerm_kubernetes_cluster.cluster.kube_config.0.username
  password               = azurerm_kubernetes_cluster.cluster.kube_config.0.password
  client_certificate     = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.cluster.kube_config.0.host
    username               = azurerm_kubernetes_cluster.cluster.kube_config.0.username
    password               = azurerm_kubernetes_cluster.cluster.kube_config.0.password
    client_certificate     = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)
  }
}

resource "azurerm_resource_group" "example" {
  name     = var.project
  location = var.location
}