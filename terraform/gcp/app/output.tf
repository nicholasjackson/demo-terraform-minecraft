output "minecraft_ip" {
  value = google_compute_address.minecraft.address
}

output "minecraft_url" {
  value = "http://${cloudflare_record.minecraft.hostname}"
}