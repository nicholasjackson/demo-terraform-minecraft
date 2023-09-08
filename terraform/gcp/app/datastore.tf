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



///data "vault_generic_secret" "sql_creator" {
///  path = "${vault_database_secrets_mount.minecraft.path}/creds/importer"
///}
///
///# import the data
///resource "kubernetes_config_map" "sql_import" {
///  metadata {
///    name = "minecraft-db-${var.environment}"
///  }
///
///  data = {
///    "import.sql" = <<-EOF
///    CREATE TABLE IF NOT EXISTS counter (
///      count INT NOT NULL
///    );
///
///    ALTER TABLE public.counter OWNER TO postgres;
///    
///    INSERT INTO counter (count) VALUES (0);
///    EOF
///  }
///}
///
///resource "kubernetes_job" "sql_import" {
///  metadata {
///    name = "minecraft-db-import-${var.environment}"
///  }
///
///  spec {
///    template {
///      metadata {}
///
///      spec {
///        container {
///          name    = "postgres"
///          image   = "postgres:15.4"
///          command = ["bin/sh", "-c", "psql -a -f /sql/import.sql"]
///
///          volume_mount {
///            name       = "sql"
///            mount_path = "/sql"
///          }
///
///          env {
///            name  = "PGHOST"
///            value = google_sql_database_instance.instance.public_ip_address
///          }
///
///          env {
///            name  = "PGDATABASE"
///            value = google_sql_database.minecraft.name
///          }
///
///          env {
///            name  = "PGPASSWORD"
///            value = data.vault_generic_secret.sql_creator.data.password
///          }
///
///          env {
///            name  = "PGUSER"
///            value = data.vault_generic_secret.sql_creator.data.username
///          }
///        }
///
///        volume {
///          name = "sql"
///
///          config_map {
///            name = kubernetes_config_map.sql_import.metadata.0.name
///          }
///        }
///
///        restart_policy = "Never"
///      }
///    }
///
///    backoff_limit = 4
///
///  }
///
///  wait_for_completion = false
///}