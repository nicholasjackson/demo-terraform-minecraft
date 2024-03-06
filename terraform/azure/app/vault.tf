resource "vault_database_secrets_mount" "minecraft" {
  depends_on = [azurerm_postgresql_firewall_rule.minecraft]

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

resource "vault_database_secret_backend_role" "reader" {
  name    = "reader"
  backend = vault_database_secrets_mount.minecraft.path
  db_name = vault_database_secrets_mount.minecraft.postgresql[0].name
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
    "GRANT SELECT ON counter TO \"{{name}}\";",
  ]
}

resource "vault_database_secret_backend_role" "writer" {
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