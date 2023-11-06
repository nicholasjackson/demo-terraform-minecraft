// create a renewable token for the vault credential store
//resource "vault_token" "boundary" {
//  policies  = ["admin"]
//
//  no_parent = true
//  renewable = true
//  period    = "30m"
//  ttl       = "24h"
//
//  renew_min_lease = 43200
//  renew_increment = 86400
//
//  metadata = {
//    "purpose" = "boundary-credential-store"
//  }
//
//  namespace = var.vault_namespace
//}

resource "vault_approle_auth_backend_login" "login" {
  backend   = var.vault_approle_path
  role_id   = var.vault_approle_id
  secret_id = var.vault_approle_secret_id

  namespace = "${var.vault_namespace}"
}

resource "boundary_credential_store_vault" "vault" {
  name        = var.scope_name
  description = "HCP Credential Store"

  address  = var.vault_addr
  token    = vault_approle_auth_backend_login.login.client_token
  scope_id = boundary_scope.project.id

  namespace = "admin/${var.vault_namespace}"
}
