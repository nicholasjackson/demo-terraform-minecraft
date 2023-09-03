data "google_client_config" "provider" {}

data "google_container_cluster" "my_cluster" {
  name     = var.cluster
  location = var.location
}

provider "kubernetes" {
  host  = "https://${data.google_container_cluster.my_cluster.endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate,
  )
}

resource "google_compute_address" "minecraft" {
  name   = "minecraft-${var.environment}"
  region = var.location
}

resource "kubernetes_service" "minecraft" {
  metadata {
    name = "minecraft-${var.environment}"
  }

  spec {
    selector = {
      app = "minecraft-${var.environment}"
    }

    session_affinity = "ClientIP"
    port {
      protocol    = "TCP"
      port        = 25565
      target_port = 25565
    }
    type             = "LoadBalancer"
    load_balancer_ip = google_compute_address.minecraft.address
  }
}

resource "kubernetes_service" "bluemap" {
  count = var.environment == "prod" ? 0 : 1

  metadata {
    name = "bluemap-${var.environment}"
  }

  spec {
    selector = {
      app = "minecraft-${var.environment}"
    }

    session_affinity = "ClientIP"
    port {
      protocol    = "TCP"
      port        = 80
      target_port = 8100
    }
    type             = "LoadBalancer"
    load_balancer_ip = google_compute_address.minecraft.address
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

          # WORLD_CHECKSUM will force the deployment to be recreated when the world file changes
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
            name  = "VAULT_TOKEN"
            value = data.terraform_remote_state.hcp.outputs.vault_admin_token
          }

          env {
            name  = "HASHICRAFT_env"
            value = variable.environment
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

resource "cloudflare_record" "minecraft" {
  zone_id = var.cloudflare_zone_id
  name    = "minecraft-${var.environment}"
  value   = google_compute_address.minecraft.address
  type    = "A"
  ttl     = 3600
  proxied = false
}

output "minecraft_ip" {
  value = google_compute_address.minecraft.address
}
