# Locals allow functions like file to be used, variables do not
# Add the config files to a map so we can create kube volume mounts
# The key is the path to mount the file with _ substituted for /
locals {
  config_files = {
    "banned-ips.json"     = "${file("${path.module}/config/banned-ips.json")}"
    "banned-players.json" = "${file("${path.module}/config/banned-players.json")}"
    "bukkit.yml"          = "${file("${path.module}/config/bukkit.yml")}"
    "ops.json"            = "${file("${path.module}/config/ops.json")}"
    "usercache.json"      = "${file("${path.module}/config/usercache.json")}"
    "whitelist.json"      = "${file("${path.module}/config/whitelist.json")}"
    //"databases.json"      = "${file("${path.module}/config/databases.json")}"
    "webservers.json" = "${file("${path.module}/config/webservers.json")}"
  }
}

locals {
  deployment_env = {
    "WORLD_CHECKSUM"  = file("./checksum.txt")                                                                                          // checksum for the minecraft world, forces redeploy when tar changes
    "MODS_BACKUP"     = "https://github.com/nicholasjackson/demo-terraform-minecraft/releases/download/mods/mods.tar.gz"                // location of mods to install
    "WORLD_BACKUP"    = "https://github.com/nicholasjackson/demo-terraform-minecraft/releases/download/${var.environment}/world.tar.gz" // location of the minecraft world
    "VAULT_ADDR"      = var.vault_addr                                                                                                  // address of the vault server used by the Vault Lock Block
    "VAULT_NAMESPACE" = "admin/${var.environment}"                                                                                      // namespace to use for the Vault Lock Block
    "HASHICRAFT_env"  = var.environment                                                                                                 // Vault namespace environment to use for the Vault Lock Block
    "SPAWN_ANIMALS"   = "true"                                                                                                          // enable animals
    "SPAWN_NPCS"      = "true"                                                                                                          // enable NPCs
    "ONLINE_MODE"     = "false"                                                                                                         // disable online mode
    "DB_HOSTNAME"     = azurerm_postgresql_server.minecraft.name                                                                        // hostname of the database server
    "DB_SERVER"       = "${azurerm_postgresql_server.minecraft.fqdn}:5432"                                                              // server and port of the database server
    "DB_DATABASE"     = azurerm_postgresql_database.minecraft.name                                                                      // name of the database
  }
}

resource "kubernetes_config_map" "config" {
  metadata {
    name = "minecraft-config-${var.environment}"
  }

  data = local.config_files
}


# create a service account for the app, this allows the vault operator to authenticate
# the app to vault and retrieve the secrets
resource "kubernetes_service_account" "minecraft" {
  metadata {
    name = "minecraft-${var.environment}"
  }
}

# kubernetes does not automatically create service account tokens
# https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.24.md#urgent-upgrade-notes
resource "kubernetes_secret" "minecraft-token" {
  metadata {
    name = "${kubernetes_service_account.minecraft.metadata.0.name}-token"
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.minecraft.metadata.0.name
    }
  }

  type = "kubernetes.io/service-account-token"
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
        service_account_name = kubernetes_service_account.minecraft.metadata.0.name

        container {
          image = "hashicraft/minecraftservice:v0.0.3"
          name  = "minecraft"

          resources {
            limits = {
              cpu    = "1"
              memory = "4096Mi"
            }
            requests = {
              cpu    = "1"
              memory = "4096Mi"
            }
          }

          dynamic "env" {
            for_each = local.deployment_env

            content {
              name  = env.key
              value = env.value
            }
          }

          // mounting secrets as environment variables means they are not updated
          // when the secret changes
          //dynamic "env" {
          //  for_each = local.secrets_env

          //  content {
          //    name = env.key
          //    value_from {
          //      secret_key_ref {
          //        name = env.value.name
          //        key  = env.value.key
          //      }
          //    }
          //  }
          //}

          dynamic "volume_mount" {
            for_each = local.config_files

            content {
              name = "config"

              mount_path = "/minecraft/config/${replace(volume_mount.key, "_", "/")}"
              sub_path   = volume_mount.key
              read_only  = false
            }
          }

          volume_mount {
            name       = kubernetes_secret.db_writer.metadata.0.name
            mount_path = "/etc/db_secrets"
            read_only  = true
          }

          volume_mount {
            name       = kubernetes_secret.pki_certs.metadata.0.name
            mount_path = "/etc/tls"
            read_only  = true
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

        volume {
          name = kubernetes_secret.pki_certs.metadata.0.name
          secret {
            secret_name = kubernetes_secret.db_writer.metadata.0.name
          }
        }
        
        volume {
          name = kubernetes_secret.db_writer.metadata.0.name
          secret {
            secret_name = kubernetes_secret.db_writer.metadata.0.name
          }
        }

      }
    }
  }
}
