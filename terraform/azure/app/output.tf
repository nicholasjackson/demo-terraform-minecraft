output "minecraft_ip" {
  value = kubernetes_service.minecraft.status.0.load_balancer.0.ingress.0.ip
}

output "microservice_ip" {
  value = kubernetes_service.microservice.status.0.load_balancer.0.ingress.0.ip
}

output "minecraft_url" {
  value = "http://${cloudflare_record.minecraft.hostname}"
}