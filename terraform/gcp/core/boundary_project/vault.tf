//// create a renewable token for the vault credential store
resource "vault_policy" "token" {
  name = var.scope_name

  policy = <<-EOT
  path "auth/token/lookup-self" {
    capabilities = ["read"]
  }
  
  path "auth/token/renew-self" {
    capabilities = ["update"]
  }
  
  path "auth/token/revoke-self" {
    capabilities = ["update"]
  }
  
  path "sys/leases/renew" {
    capabilities = ["update"]
  }
  
  path "sys/leases/revoke" {
    capabilities = ["update"]
  }
  
  path "sys/capabilities-self" {
    capabilities = ["update"]
  }
  EOT
}

resource "vault_token" "boundary" {
  policies = [replace(var.scope_name,"-","_"), vault_policy.token.name]

  renewable = true
  ttl       = "24h"

  renew_min_lease = 43200
  renew_increment = 86400
  no_parent       = true
  period          = "30m"

  metadata = {
    "purpose" = "boundary-credential-store"
  }
}

resource "boundary_credential_store_vault" "vault" {
  name        = var.scope_name
  description = "HCP Credential Store"
  address     = var.vault_addr
  token       = vault_token.boundary.client_token
  scope_id    = boundary_scope.project.id
  namespace   = "admin"
}
