resource "random_password" "root_password" {
  length  = 16
  special = false
}

resource "random_string" "bucket_suffix" {
  length  = 16
  special = false
  upper   = false
}

resource "azurerm_postgresql_server" "example" {
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

resource "azurerm_postgresql_firewall_rule" "example" {
  name                = "all"
  resource_group_name = var.project
  server_name         = azurerm_postgresql_server.example.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

resource "azurerm_postgresql_database" "example" {
  name                = var.environment
  resource_group_name = var.project
  server_name         = azurerm_postgresql_server.example.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

resource "vault_database_secrets_mount" "minecraft" {
  depends_on = [ azurerm_postgresql_firewall_rule.example ]

  path = "database/minecraft_${var.environment}"

  postgresql {
    name              = "minecraft"
    username          = "${azurerm_postgresql_server.example.administrator_login}@${azurerm_postgresql_server.example.name}"
    password          = random_password.root_password.result
    connection_url    = "postgresql://{{username}}:{{password}}@${azurerm_postgresql_server.example.fqdn}:5432/${azurerm_postgresql_database.example.name}"
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
    "GRANT ${azurerm_postgresql_server.example.administrator_login} TO \"{{name}}\";"
  ]

  default_ttl = "100"
  max_ttl     = "100"
}

data "vault_generic_secret" "sql_creator" {
  path = "${vault_database_secrets_mount.minecraft.path}/creds/importer"
}

# import the data
resource "kubernetes_config_map" "sql_import" {
  metadata {
    name = "minecraft-db-${var.environment}"
  }

  data = {
    "import.sql" = <<-EOF
    CREATE TABLE IF NOT EXISTS counter (
      count INT NOT NULL
    );

    ALTER TABLE public.counter OWNER TO ${azurerm_postgresql_server.example.administrator_login};
    
    INSERT INTO counter (count) VALUES (0);
    EOF
  }
}

resource "kubernetes_job" "sql_import" {
  // we only want this to be created or destroyed
  // if we need to update we can taint the resource
  lifecycle {
    ignore_changes = all
  }

  metadata {
    annotations = {}
    name        = "minecraft-db-import-${var.environment}"
  }

  spec {
    active_deadline_seconds = 60
    manual_selector         = false

    template {
      metadata {
        annotations = {}
        labels      = {}
      }

      spec {
        active_deadline_seconds = 60
        node_selector           = {}
        scheduler_name          = "default-scheduler"

        container {
          name    = "postgres"
          image   = "postgres:15.4"
          command = ["bin/sh", "-c", "psql -a -f /sql/import.sql"]
          args    = []

          volume_mount {
            name       = "sql"
            mount_path = "/sql"
          }

          env {
            name  = "PGHOST"
            value = azurerm_postgresql_server.example.fqdn
          }

          env {
            name  = "PGDATABASE"
            value = azurerm_postgresql_database.example.name
          }

          env {
            name  = "PGPASSWORD"
            value = data.vault_generic_secret.sql_creator.data.password
          }

          env {
            name  = "PGUSER"
            value = "${data.vault_generic_secret.sql_creator.data.username}@${azurerm_postgresql_server.example.name}"
          }

          resources {
            limits = {
              cpu    = "1"
              memory = "512Mi"
            }

            requests = {
              cpu    = "1"
              memory = "512Mi"
            }
          }
        }

        volume {
          name = "sql"

          config_map {
            name     = kubernetes_config_map.sql_import.metadata.0.name
            optional = false
          }
        }

        restart_policy = "Never"
      }
    }

    backoff_limit = 4

  }

  wait_for_completion = true
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

  address             = azurerm_postgresql_server.example.fqdn
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
