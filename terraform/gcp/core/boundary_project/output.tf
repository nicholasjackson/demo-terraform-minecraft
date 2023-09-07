output "scope_id" {
  value = boundary_scope.project.id
}

output "credential_store_id" {
  value = boundary_credential_store_vault.vault.id
}

output "vault_secrets_policy" {
  value = replace(var.scope_name,"-","_")
}