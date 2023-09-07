output "boundary_users" {
  sensitive = true
  value = local.user_passwords
}

output "boundary_dev_details" {
  value = {
    credential_store_id = module.boundary_scope_dev.credential_store_id
    scope_id = module.boundary_scope_dev.scope_id
  }
}

output "vault_namespace_dev" {
  sensitive = true
  value = module.vault_namespace_dev
}

output "vault_namespace_test" {
  sensitive = true
  value = module.vault_namespace_test
}

output "vault_namespace_prod" {
  sensitive = true
  value = module.vault_namespace_test
}