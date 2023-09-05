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
