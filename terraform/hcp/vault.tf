resource "hcp_vault_cluster" "vault" {
  hvn_id     = hcp_hvn.hvn.hvn_id
  cluster_id = "vault-cluster"
  tier       = "dev"
  public_endpoint = true
}

resource "hcp_vault_cluster_admin_token" "admin" {
  cluster_id = hcp_vault_cluster.vault.cluster_id
}

output "vault_public_addr" {
  value = hcp_vault_cluster.vault.vault_public_endpoint_url
}

output "vault_admin_token" {
  value = hcp_vault_cluster_admin_token.admin.token
  sensitive = true
}