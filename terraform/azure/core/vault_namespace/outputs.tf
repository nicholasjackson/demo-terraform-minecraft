output "namespace" {
  value = vault_namespace.namespace.path
}

output "kv_path" {
  value = vault_mount.kvv2.path
}

output "pki_path" {
  value = vault_mount.pki.path
}

output "admin_policy" {
  value = vault_policy.admin.name
}

output "approle_path" {
  value = vault_auth_backend.approle.path
}

output "userpath_path" {
  value = vault_auth_backend.userpass.path
}

output "approle_id" {
  value = vault_approle_auth_backend_role.admin.role_id
}

output "approle_secret_id" {
  value = vault_approle_auth_backend_role_secret_id.admin.secret_id
}