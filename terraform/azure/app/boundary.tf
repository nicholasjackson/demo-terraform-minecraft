resource "boundary_credential_library_vault" "db" {
  name                = "${var.environment}-db-credentials"
  description         = "Database credentials for ${var.environment} environment"
  credential_store_id = var.boundary_credential_store_id
  path                = "${vault_database_secrets_mount.minecraft.path}/creds/reader"
  http_method         = "GET"
  credential_type     = "username_password"
}

resource "boundary_target" "db" {
  name        = "${var.environment}-db"
  description = "Database for ${var.environment} environment"
  scope_id    = var.boundary_scope_id

  type = "tcp"

  address             = azurerm_postgresql_server.minecraft.fqdn
  default_port        = 5432
  default_client_port = 5432

  brokered_credential_source_ids = [
    boundary_credential_library_vault.db.id
  ]
}

locals {
  boundary_user_accounts = jsondecode(var.boundary_user_accounts)
}

resource "boundary_role" "db_users" {
  name        = "DB Access"
  description = "Access to the database"
  scope_id    = var.boundary_scope_id

  principal_ids = [for user, details in local.boundary_user_accounts : details.id]
  grant_strings = ["id=*;type=*;actions=*"]
}