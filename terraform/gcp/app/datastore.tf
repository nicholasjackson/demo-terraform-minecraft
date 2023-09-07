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
  metadata {
    name = "minecraft-db-import-${var.environment}"
  }

  spec {
    template {
      metadata {}

      spec {
        container {
          name    = "postgres"
          image   = "postgres:15.4"
          command = ["bin/sh", "-c", "psql -a -f /sql/import.sql"]

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
        }

        volume {
          name = "sql"

          config_map {
            name = kubernetes_config_map.sql_import.metadata.0.name
          }
        }

        restart_policy = "Never"
      }
    }

    backoff_limit = 4

  }

  wait_for_completion = false
}
