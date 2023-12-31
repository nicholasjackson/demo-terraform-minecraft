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

resource "kubernetes_service" "microservice" {
  metadata {
    name = "service-${var.environment}"
  }

  spec {
    selector = {
      app = "minecraft-${var.environment}"
    }

    session_affinity = "ClientIP"
    port {
      protocol    = "TCP"
      port        = 8081
      target_port = 8081
    }

    type             = "LoadBalancer"
    load_balancer_ip = google_compute_address.minecraft.address
  }
}

resource "kubernetes_service" "prismarine" {
  count = var.environment == "prod" ? 0 : 1

  metadata {
    name = "prismarine-${var.environment}"
  }

  spec {
    selector = {
      app = "minecraft-${var.environment}"
    }

    session_affinity = "ClientIP"
    port {
      protocol    = "TCP"
      port        = 80
      target_port = 8080
    }
    type             = "LoadBalancer"
    load_balancer_ip = google_compute_address.minecraft.address
  }
}

resource "cloudflare_record" "minecraft" {
  zone_id = var.cloudflare_zone_id
  name    = "minecraft-${var.environment}"
  value   = google_compute_address.minecraft.address
  type    = "A"
  ttl     = 360
  proxied = false
}