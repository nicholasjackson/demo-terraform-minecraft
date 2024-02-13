# Create a namespace for every environment
resource "vault_namespace" "namespace" {
  path = var.environment
}

resource "vault_mount" "kvv2" {
  path        = "secrets"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"

  namespace = vault_namespace.namespace.path
}

resource "vault_mount" "pki" {
  path        = "pki"
  type        = "pki"
  description = "PKI mount for application"

  default_lease_ttl_seconds = 86400
  max_lease_ttl_seconds     = 31536000
  
  namespace = vault_namespace.namespace.path
}

resource "vault_pki_secret_backend_root_cert" "ca" {
  backend               = vault_mount.pki.path
  type                  = "internal"
  common_name           = "${var.environment}.minecraft.internal"
  ttl                   = "31536000"
  format                = "pem"
  private_key_format    = "der"
  key_type              = "rsa"
  key_bits              = 4096
  exclude_cn_from_sans  = true
  ou                    = "Development"
  organization          = "HashiCraft"
  
  namespace = vault_namespace.namespace.path
}


resource "vault_policy" "admin" {
  name = "admin"

  namespace = vault_namespace.namespace.path

  policy = <<-EOT
  # Self token capabilities
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

  # Allow access to the KV
  path "${vault_mount.kvv2.path}/*" {
    capabilities = ["read", "list", "create", "update", "delete"]
  }
  
  path "${vault_mount.pki.path}/*" {
    capabilities = ["read", "list", "create", "update", "delete"]
  }

  # Allow access to discover existing mounts 
  path "sys/mounts" {
    capabilities = ["read"]
  }

  # Allow access to add users to userpath
  path "auth/*" {
    capabilities = ["read", "list", "create", "update", "delete"]
  }
 
  # Allow creating JWT auth endpoints
  path "sys/auth/jwt/*" {
    capabilities = ["read", "list", "create", "update", "delete", "sudo"]
  }

  # Allow access to create policy
  path "sys/policies/acl/*" {
    capabilities = ["read", "list", "create", "update", "delete"]
  }
  
  # Allow access to use the kubernetes secrets engine
  path "sys/mounts/kubernetes/*" {
    capabilities = ["read", "list", "create", "update", "delete"]
  }
  
  path "kubernetes/*" {
    capabilities = ["read", "list", "create", "update", "delete"]
  }
  
  # Allow access to create db secrets engines
  path "sys/mounts/database/*" {
    capabilities = ["read", "list", "create", "update", "delete"]
  }
  
  path "database/*" {
    capabilities = ["read", "list", "create", "update", "delete"]
  }
  EOT
}

resource "vault_auth_backend" "approle" {
  type      = "approle"
  namespace = vault_namespace.namespace.path
}

resource "vault_auth_backend" "userpass" {
  type      = "userpass"
  namespace = vault_namespace.namespace.path
}

resource "vault_approle_auth_backend_role" "admin" {
  backend        = vault_auth_backend.approle.path
  role_name      = "admin-role"
  token_policies = ["default", vault_policy.admin.name]
  token_period   = 1800
  token_ttl      = 0
  token_max_ttl  = 0

  namespace = vault_namespace.namespace.path
}

resource "vault_approle_auth_backend_role_secret_id" "admin" {
  backend   = vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.admin.role_name

  namespace = vault_namespace.namespace.path
}

resource "random_password" "userpass_passwords" {
  count = length(var.userpass_usernames)

  length  = 16
  special = true
}

resource "vault_generic_endpoint" "userpass_users" {
  depends_on = [vault_auth_backend.userpass]

  count = length(var.userpass_usernames)

  namespace = vault_namespace.namespace.path
  path      = "auth/userpass/users/${var.userpass_usernames[count.index]}"

  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["default", "${vault_policy.admin.name}"],
  "password": "${random_password.userpass_passwords[count.index].result}"
}
EOT
}

