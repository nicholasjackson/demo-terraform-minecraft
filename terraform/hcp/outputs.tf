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

output "vault_public_addr" {
  value = hcp_vault_cluster.vault.vault_public_endpoint_url
}

output "vault_cluster_id" {
  value = hcp_vault_cluster.vault.cluster_id
}

output "vault_admin_token" {
  value     = jsondecode(data.terracurl_request.admin_token.response).auth.client_token
  sensitive = true
}