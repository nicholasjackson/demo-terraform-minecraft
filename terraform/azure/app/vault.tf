resource "vault_pki_secret_backend_role" "app" {
  backend          = var.vault_pki_path
  name             = "app_role"
  ttl              = 2592000 // 30 days
  allow_ip_sans    = true
  key_type         = "rsa"
  key_bits         = 4096
  allow_subdomains = true
  allowed_domains  = ["${var.environment}.minecraft.internal"]
}

resource "vault_pki_secret_backend_cert" "app" {
  backend     = var.vault_pki_path
  name        = vault_pki_secret_backend_role.app.name
  common_name = "app.${var.environment}.minecraft.internal"
  ttl         = "168h" // 7 days
}

resource "kubernetes_secret" "pki_certs" {
  metadata {
    name = "minecraft-pki-${var.environment}"
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.key" = vault_pki_secret_backend_cert.app.private_key
    "tls.crt" = vault_pki_secret_backend_cert.app.certificate
  }
}

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
  //depends_on = [kubernetes_job.sql_import]

  name    = "reader"
  backend = vault_database_secrets_mount.minecraft.path
  db_name = vault_database_secrets_mount.minecraft.postgresql[0].name
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
    "GRANT SELECT ON counter TO \"{{name}}\";",
  ]
}

resource "vault_database_secret_backend_role" "writer" {
  //depends_on = [kubernetes_job.sql_import]

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

data "vault_generic_secret" "db_creds" {
  path = "${vault_database_secrets_mount.minecraft.path}/creds/writer"
}

resource "kubernetes_secret" "db_writer" {
  metadata {
    name = "minecraft-db-${var.environment}"
  }

  data = {
    username = data.vault_generic_secret.db_creds.data.username
    password = data.vault_generic_secret.db_creds.data.password
  }
}