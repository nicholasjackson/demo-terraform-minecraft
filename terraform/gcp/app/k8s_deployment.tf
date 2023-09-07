resource "kubernetes_config_map" "config" {
  metadata {
    name = "minecraft-config-${var.environment}"
  }

  data = local.config_files
}

data "vault_generic_secret" "sql_writer" {
  path = "${vault_database_secrets_mount.minecraft.path}/creds/importer"
}

resource "kubernetes_secret" "db_writer" {
  metadata {
    name = "minecraft-db-${var.environment}"
  }

  data = {
    db_host     = "${google_sql_database_instance.instance.public_ip_address}:5432"
    db_username = data.vault_generic_secret.sql_writer.data.username
    db_password = data.vault_generic_secret.sql_writer.data.password
    db_database = google_sql_database.minecraft.name
  }
}

resource "kubernetes_deployment" "minecraft" {
  metadata {
    name = "minecraft-${var.environment}"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "minecraft-${var.environment}"
      }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app = "minecraft-${var.environment}"
        }
      }

      spec {
        container {
          image = "hashicraft/minecraft:v1.20.1-fabric"
          name  = "minecraft"

          resources {
            limits = {
              cpu    = "1"
              memory = "2048Mi"
            }
            requests = {
              cpu    = "1"
              memory = "2048Mi"
            }
          }

          env {
            name  = "WORLD_CHECKSUM"
            value = file("./checksum.txt")
          }

          env {
            name  = "MODS_BACKUP"
            value = "https://github.com/nicholasjackson/demo-terraform-minecraft/releases/download/mods/mods.tar.gz"
          }

          env {
            name  = "WORLD_BACKUP"
            value = "https://github.com/nicholasjackson/demo-terraform-minecraft/releases/download/${var.environment}/world.tar.gz"
          }

          env {
            name  = "VAULT_ADDR"
            value = data.terraform_remote_state.hcp.outputs.vault_public_addr
          }

          env {
            name  = "VAULT_NAMESPACE"
            value = "admin"
          }

          env {
            name  = "HASHICRAFT_env"
            value = var.environment
          }

          env {
            name  = "SPAWN_ANIMALS"
            value = "true"
          }

          env {
            name  = "SPAWN_NPCS"
            value = "true"
          }
          
          env {
            name  = "MICROSERVICES_db_host"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_writer.metadata.0.name
                key  = "db_host"
              }
            }
          }
          
          env {
            name  = "MICROSERVICES_db_username"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_writer.metadata.0.name
                key  = "db_username"
              }
            }
          }
          
          env {
            name  = "MICROSERVICES_db_password"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_writer.metadata.0.name
                key  = "db_password"
              }
            }
          }
          
          env {
            name  = "MICROSERVICES_db_database"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_writer.metadata.0.name
                key  = "db_database"
              }
            }
          }

          dynamic "volume_mount" {
            for_each = local.config_files

            content {
              name = "config"

              mount_path = "/minecraft/config/${replace(volume_mount.key, "_", "/")}"
              sub_path   = volume_mount.key
              read_only  = false
            }
          }
        }


        volume {
          name = "config"

          config_map {
            default_mode = "0666"
            name         = kubernetes_config_map.config.metadata.0.name

            dynamic "items" {
              for_each = local.config_files

              content {
                key  = items.key
                path = items.key
              }
            }

          }
        }
      }
    }
  }
}
