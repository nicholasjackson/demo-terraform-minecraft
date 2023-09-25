# Locals allow functions like file to be used, variables do not
# Add the config files to a map so we can create kube volume mounts
# The key is the path to mount the file with _ substituted for /
locals {
  config_files = {
    "banned-ips.json"             = "${file("${path.module}/config/banned-ips.json")}"
    "banned-players.json"         = "${file("${path.module}/config/banned-players.json")}"
    "bukkit.yml"                  = "${file("${path.module}/config/bukkit.yml")}"
    "ops.json"                    = "${file("${path.module}/config/ops.json")}"
    "usercache.json"              = "${file("${path.module}/config/usercache.json")}"
    "whitelist.json"              = "${file("${path.module}/config/whitelist.json")}"
    "bluemap_core.conf"           = "${file("${path.module}/config/core.conf")}"
    "bluemap_maps_overworld.conf" = "${file("${path.module}/config/overworld.conf")}"
    "bluemap_maps_nether.conf"    = "${file("${path.module}/config/nether.conf")}"
    "bluemap_maps_end.conf"       = "${file("${path.module}/config/end.conf")}"
  }
}

locals {
  deployment_env = {
    "WORLD_CHECKSUM"  = file("./checksum.txt") // checksum for the minecraft world, forces redeploy when tar changes
    "MODS_BACKUP"     = "https://github.com/nicholasjackson/demo-terraform-minecraft/releases/download/mods/mods.tar.gz" // location of mods to install
    "WORLD_BACKUP"    = "https://github.com/nicholasjackson/demo-terraform-minecraft/releases/download/${var.environment}/world.tar.gz" // location of the minecraft world
    "VAULT_ADDR"      = var.vault_addr // address of the vault server used by the Vault Lock Block
    "VAULT_NAMESPACE" = "admin/${var.environment}" // namespace to use for the Vault Lock Block
    "HASHICRAFT_env"  = var.environment // Vault namespace environment to use for the Vault Lock Block
    "SPAWN_ANIMALS"   = "true" // enable animals
    "SPAWN_NPCS"      = "true" // enable NPCs
  }

  secrets_env = {
    "MICROSERVICES_db_host" = {
      name = kubernetes_secret.db_writer.metadata.0.name
      key  = "db_host"
    }

    "MICROSERVICES_db_username" = {
      name = kubernetes_secret.db_writer.metadata.0.name
      key  = "db_username"
    }

    "MICROSERVICES_db_password" = {
      name = kubernetes_secret.db_writer.metadata.0.name
      key  = "db_password"
    }

    "MICROSERVICES_db_database" = {
      name = kubernetes_secret.db_writer.metadata.0.name
      key  = "db_database"
    }
  }

}

data "vault_generic_secret" "sql_writer" {
  path = "${vault_database_secrets_mount.minecraft.path}/creds/writer"
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

resource "kubernetes_config_map" "config" {
  metadata {
    name = "minecraft-config-${var.environment}"
  }

  data = local.config_files
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


          dynamic "env" {
            for_each = local.deployment_env

            content {
              name  = env.key
              value = env.value
            }
          }

          dynamic "env" {
            for_each = local.secrets_env

            content {
              name = env.key
              value_from {
                secret_key_ref {
                  name = env.value.name
                  key  = env.value.key
                }
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
