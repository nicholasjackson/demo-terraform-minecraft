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

provider "kubernetes" {
  host  = "https://${data.google_container_cluster.my_cluster.endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate,
  )
}