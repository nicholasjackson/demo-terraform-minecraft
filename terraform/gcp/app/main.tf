variable "project" {
  default = ""
}

variable "location" {
  default = ""
}

variable "cluster" {
  default = ""
}

variable "environment" {
  default = ""
}

variable "cloudflare_zone_id" {
  default = ""
}

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

terraform {
  cloud {
    organization = "HashiCraft"

    workspaces {
      name = "app-dev"
    }
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.79.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.23.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.location
}

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
