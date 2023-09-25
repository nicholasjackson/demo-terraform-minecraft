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
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

resource "helm_release" "vault_controller" {
  name       = "vault-controller"

  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault-secrets-operator"

  set {
    name = "defaultVaultConnection.enabled"
    value = "true"
  }
  
  set {
    name = "defaultVaultConnection.address"
    value = data.terraform_remote_state.hcp.outputs.vault_public_addr
  }
}