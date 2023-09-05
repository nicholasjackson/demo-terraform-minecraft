# Fetch the Vault address and token from the HCP workspace remote state
data "terraform_remote_state" "hcp" {
  backend = "remote"

  config = {
    organization = "HashiCraft"
    workspaces = {
      name = "HCP"
    }
  }
}

provider "vault" {
  # Configuration options
  address = data.terraform_remote_state.hcp.outputs.vault_public_addr
  token   = data.terraform_remote_state.hcp.outputs.vault_admin_token
}

# Create a KV Version 2 secret engine mount for the environment
resource "vault_mount" "kvv2" {
  path        = "secrets_${var.environment}"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
}

resource "vault_kv_secret_v2" "admin_key" {
  mount               = vault_mount.kvv2.path
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
  mount               = vault_mount.kvv2.path
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

resource "vault_auth_backend" "userpass" {
  path = "userpass_${var.environment}"
  type = "userpass"
}

# Create user accounts for Admins
resource "vault_generic_endpoint" "admin_users" {
  lifecycle {
    ignore_changes = [ data_json ]
  }

  for_each = var.minecraft_admins

  path = "auth/${vault_auth_backend.userpass.path}/users/${each.key}"

  data_json = <<-EOT
  {
    "policies": ["${vault_policy.admin.name}","${vault_policy.vault.name}"],
    "password": "${each.value}"
  }
  EOT
}
