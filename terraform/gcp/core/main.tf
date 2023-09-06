variable "project" {
  default = ""
}

variable "location" {
  default = ""
}

variable "cluster" {
  default = ""
}

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
      source = "hashicorp/google"
      version = "4.79.0"
    }
  }
}

provider "google" {
  project     = var.project
  region      = var.location
}

resource "google_service_account" "cluster" {
  account_id   = "gke-clusterfoaccount"
  display_name = "GKE Cluster Account"
}

resource "google_container_cluster" "primary" {
  name     = var.cluster
  location = var.location

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-node-pool"
  location   = var.location
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-standard-2"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.cluster.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}