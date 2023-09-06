resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "hcp_boundary_cluster" "boundary" {
  cluster_id = "boundary-cluster"
  username   = "admin"
  password   = random_password.password.result
  tier = "Standard"

  maintenance_window_config {
    day          = "TUESDAY"
    start        = 2
    end          = 12
    upgrade_type = "SCHEDULED"
  }
}

output "boundary_cluster_id" {
  value = hcp_boundary_cluster.boundary.id
}

output "boundary_cluster_user" {
  value = hcp_boundary_cluster.boundary.username
}

output "boundary_cluster_password" {
  sensitive = true
  value = hcp_boundary_cluster.boundary.password
}

output "boundary_cluster_url" {
  value = hcp_boundary_cluster.boundary.cluster_url
}