resource "hcp_vault_cluster" "vault" {
  hvn_id     = hcp_hvn.hvn.hvn_id
  cluster_id = "vault-cluster"
  tier       = "dev"
  public_endpoint = true
}


output "vault_public_addr" {
  value = hcp_vault_cluster.vault.vault_public_endpoint_url
}

output "vault_cluster_id" {
  value = hcp_vault_cluster.vault.cluster_id
}