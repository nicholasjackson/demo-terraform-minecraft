resource "random_password" "root_password" {
  length  = 16
  special = false
}

resource "random_string" "bucket_suffix" {
  length  = 16
  special = false
  upper   = false
}

resource "google_sql_database_instance" "instance" {
  name             = "minecraft-instance"
  region           = var.location
  database_version = "POSTGRES_15"

  root_password = random_password.root_password.result

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      authorized_networks {
        name  = "public"
        value = "0.0.0.0/0"
      }
    }
  }
}

resource "google_sql_database" "minecraft" {
  name            = "${var.environment}"
  instance        = google_sql_database_instance.instance.name
  deletion_policy = "ABANDON"
}

resource "vault_database_secrets_mount" "minecraft" {
  path = "database/minecraft_${var.environment}"

  postgresql {
    name              = "minecraft"
    username          = "postgres"
    password          = random_password.root_password.result
    connection_url    = "postgresql://{{username}}:{{password}}@${google_sql_database_instance.instance.public_ip_address}:5432/${google_sql_database.minecraft.name}"
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
    "GRANT postgres TO \"{{name}}\";"
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

    ALTER TABLE public.counter OWNER TO postgres;
    
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
    name = "minecraft-db-import-${var.environment}"
  }

  spec {
    active_deadline_seconds = 60
    manual_selector = false

    template {
      metadata {
        annotations = {}
        labels = {}
      }

      spec {
        active_deadline_seconds = 60
        node_selector =  {}
        scheduler_name = "default-scheduler"

        container {
          name    = "postgres"
          image   = "postgres:15.4"
          command = ["bin/sh", "-c", "psql -a -f /sql/import.sql"]
          args = []

          volume_mount {
            name       = "sql"
            mount_path = "/sql"
          }

          env {
            name  = "PGHOST"
            value = google_sql_database_instance.instance.public_ip_address
          }

          env {
            name  = "PGDATABASE"
            value = google_sql_database.minecraft.name
          }

          env {
            name  = "PGPASSWORD"
            value = data.vault_generic_secret.sql_creator.data.password
          }

          env {
            name  = "PGUSER"
            value = data.vault_generic_secret.sql_creator.data.username
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
            name = kubernetes_config_map.sql_import.metadata.0.name
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
  depends_on = [ kubernetes_job.sql_import ]

  name    = "reader"
  backend = vault_database_secrets_mount.minecraft.path
  db_name = vault_database_secrets_mount.minecraft.postgresql[0].name
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
    "GRANT SELECT ON counter TO \"{{name}}\";",
  ]
}

resource "vault_database_secret_backend_role" "writer" {
  depends_on = [ kubernetes_job.sql_import ]

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

  principal_ids = [for user, id in var.boundary_user_accounts : id]
  grant_strings = ["id=*;type=*;actions=*"]
}