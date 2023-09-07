
# Create a KV Version 2 secret engine mount for the environment

resource "vault_kv_secret_v2" "admin_key" {
  mount               = var.vault_kv_path
  name                = "admin"
  cas                 = 1
  delete_all_versions = true
  data_json = jsonencode(
    {
      key = var.lock_keys.admin,
    }
  )
}

resource "vault_kv_secret_v2" "vault_key" {
  mount               = var.vault_kv_path
  name                = "vault"
  cas                 = 1
  delete_all_versions = true
  data_json = jsonencode(
    {
      key = var.lock_keys.vault,
    }
  )
}

# Define the policy that allows the admin user to read the admin key
resource "vault_policy" "admin" {
  name = "${var.environment}-admin"

  policy = <<-EOT
  path "${vault_kv_secret_v2.admin_key.path}" {
    capabilities = ["read"]
  }
  EOT
}

resource "vault_policy" "vault" {
  name = "${var.environment}-vault"

  policy = <<-EOT
  path "${vault_kv_secret_v2.vault_key.path}" {
    capabilities = ["read"]
  }
  EOT
}

# Create user accounts for Admins
resource "vault_generic_endpoint" "admin_users" {
  lifecycle {
    ignore_changes = [ data_json ]
  }

  for_each = var.minecraft_admins

  path = "auth/${var.vault_userpath_path}/users/${each.key}"

  data_json = <<-EOT
  {
    "policies": ["${vault_policy.admin.name}","${vault_policy.vault.name}"],
    "password": "${each.value}"
  }
  EOT
}