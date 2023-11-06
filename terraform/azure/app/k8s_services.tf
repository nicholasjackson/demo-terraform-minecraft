resource "kubernetes_service" "minecraft" {
  metadata {
    name = "minecraft-${var.environment}"
  }

  spec {
    selector = {
      app = "minecraft-${var.environment}"
    }

    port {
      protocol    = "TCP"
      port        = 25565
      target_port = 25565
    }
    type = "LoadBalancer"
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

    port {
      protocol    = "TCP"
      port        = 8081
      target_port = 8081
    }

    type = "LoadBalancer"
  }
}

resource "cloudflare_record" "minecraft" {
  zone_id = var.cloudflare_zone_id
  name    = "minecraft-${var.environment}"
  value   = kubernetes_service.minecraft.status.0.load_balancer.0.ingress.0.ip
  type    = "A"
  ttl     = 360
  proxied = false
}
