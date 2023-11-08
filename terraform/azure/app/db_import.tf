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

    ALTER TABLE public.counter OWNER TO ${azurerm_postgresql_server.minecraft.administrator_login};
    
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
            value = azurerm_postgresql_server.minecraft.fqdn
          }

          env {
            name  = "PGDATABASE"
            value = azurerm_postgresql_database.minecraft.name
          }

          env {
            name  = "PGPASSWORD"
            value = data.vault_generic_secret.sql_creator.data.password
          }

          env {
            name  = "PGUSER"
            value = "${data.vault_generic_secret.sql_creator.data.username}@${azurerm_postgresql_server.minecraft.name}"
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