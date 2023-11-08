resource "random_password" "root_password" {
  length  = 16
  special = false
}

resource "random_string" "bucket_suffix" {
  length  = 16
  special = false
  upper   = false
}

resource "azurerm_postgresql_server" "minecraft" {
  name                = "postgresql-server-1"
  location            = var.location
  resource_group_name = var.project

  sku_name = "B_Gen5_2"

  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  public_network_access_enabled = true

  administrator_login          = "psqladmin"
  administrator_login_password = random_password.root_password.result
  version                      = "9.5"
  ssl_minimal_tls_version_enforced = "TLSEnforcementDisabled"
  ssl_enforcement_enabled      = false
}

resource "azurerm_postgresql_firewall_rule" "minecraft" {
  name                = "all"
  resource_group_name = var.project
  server_name         = azurerm_postgresql_server.minecraft.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

resource "azurerm_postgresql_database" "minecraft" {
  name                = var.environment
  resource_group_name = var.project
  server_name         = azurerm_postgresql_server.minecraft.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

resource "vault_database_secrets_mount" "minecraft" {
  depends_on = [ azurerm_postgresql_firewall_rule.minecraft ]

  path = "database/minecraft_${var.environment}"

  postgresql {
    name              = "minecraft"
    username          = "${azurerm_postgresql_server.minecraft.administrator_login}@${azurerm_postgresql_server.minecraft.name}"
    password          = random_password.root_password.result
    connection_url    = "postgresql://{{username}}:{{password}}@${azurerm_postgresql_server.minecraft.fqdn}:5432/${azurerm_postgresql_database.minecraft.name}"
    verify_connection = true
    allowed_roles = [
      "reader",
      "writer",
      "importer"
    ]
  }
}

# Short lived user for importing data
resource "vault_database_secret_backend_role" "importer" {
  name    = "importer"
  backend = vault_database_secrets_mount.minecraft.path
  db_name = vault_database_secrets_mount.minecraft.postgresql[0].name
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
    "GRANT ${azurerm_postgresql_server.minecraft.administrator_login} TO \"{{name}}\";"
  ]

  default_ttl = "100"
  max_ttl     = "100"
}

// the following two roles can only be created after the counter table is generated
// from the sql import
resource "vault_database_secret_backend_role" "reader" {
  depends_on = [kubernetes_job.sql_import]

  name    = "reader"
  backend = vault_database_secrets_mount.minecraft.path
  db_name = vault_database_secrets_mount.minecraft.postgresql[0].name
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
    "GRANT SELECT ON counter TO \"{{name}}\";",
  ]
}

resource "vault_database_secret_backend_role" "writer" {
  depends_on = [kubernetes_job.sql_import]

  name    = "writer"
  backend = vault_database_secrets_mount.minecraft.path
  db_name = vault_database_secrets_mount.minecraft.postgresql[0].name
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
    "GRANT SELECT ON counter TO \"{{name}}\";",
    "GRANT INSERT ON counter TO \"{{name}}\";",
    "GRANT UPDATE ON counter TO \"{{name}}\";",
    "GRANT DELETE ON counter TO \"{{name}}\";",
  ]
}

# create a policy that allows the app to read the database credentials
resource "vault_policy" "db_secrets" {
  name = "db_secrets"

  policy = <<-EOT
  path "${vault_database_secrets_mount.minecraft.path}/creds/writer" {
    capabilities = ["read"]
  }
  EOT
}

# configure the role that the app will use to authenticate to vault
resource "vault_kubernetes_auth_backend_role" "dev" {
  backend                          = var.vault_kubernetes_path
  role_name                        = "minecraft"
  bound_service_account_namespaces = ["default"]
  bound_service_account_names      = [kubernetes_service_account.minecraft.metadata.0.name]
  token_ttl                        = 3600
  token_policies                   = ["default", vault_policy.db_secrets.name]
}