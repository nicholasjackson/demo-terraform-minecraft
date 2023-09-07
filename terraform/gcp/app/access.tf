# policy to allow the Vault boundary integration to read our secrets
resource "vault_policy" "credential_store_access" {
  name = var.boundary_credential_store_policy

  policy = <<-EOT
  path "${vault_database_secrets_mount.minecraft.path}/creds/reader" {
    capabilities = ["read", "create"]
  }
  EOT
}

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

  address      = google_sql_database_instance.instance.public_ip_address
  default_port = 5432
  default_client_port = 5432
  
  brokered_credential_source_ids = [
    boundary_credential_library_vault.db.id
  ]
}

resource "boundary_role" "db_users" {
  name        = "DB Access"
  description = "Access to the database"
  scope_id    = var.boundary_scope_id

  principal_ids = ["u_DaDHlIhmnc"]
  grant_strings = ["id=*;type=*;actions=*"]
}