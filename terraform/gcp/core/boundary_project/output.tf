output "scope_id" {
  value = boundary_scope.project.id
}

output "credential_store_id" {
  value = boundary_credential_store_vault.vault.id
}