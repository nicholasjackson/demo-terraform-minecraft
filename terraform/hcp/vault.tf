resource "hcp_vault_cluster" "vault" {
  hvn_id          = hcp_hvn.hvn.hvn_id
  cluster_id      = "vault-cluster"
  tier            = "dev"
  public_endpoint = true
}

# This admin token expires, we can not use it as a long
# lived solution for terraform
resource "hcp_vault_cluster_admin_token" "admin" {
  cluster_id = hcp_vault_cluster.vault.cluster_id
}

# Generate an admin token for Terraform, this should really
# setup OIDC auth and use that instead
data "terracurl_request" "admin_token" {
  name   = "admin_token"
  url    = "${hcp_vault_cluster.vault.vault_public_endpoint_url}/v1/auth/token/create-orphan"
  method = "POST"

  response_codes = [
    200
  ]

  headers = {
    X-Vault-Token     = hcp_vault_cluster_admin_token.admin.token
    X-Vault-Namespace = "admin"
  }

  request_body = jsonencode({
    ttl       = "768h"
    renewable = false
  })

  max_retry      = 1
  retry_interval = 10
}
