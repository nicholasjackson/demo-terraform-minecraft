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
    "WORLD_CHECKSUM"  = file("./checksum.txt")
    "MODS_BACKUP"     = "https://github.com/nicholasjackson/demo-terraform-minecraft/releases/download/mods/mods.tar.gz"
    "WORLD_BACKUP"    = "https://github.com/nicholasjackson/demo-terraform-minecraft/releases/download/${var.environment}/world.tar.gz"
    "VAULT_ADDR"      = data.terraform_remote_state.hcp.outputs.vault_public_addr
    "VAULT_NAMESPACE" = "admin/${var.environment}"
    "HASHICRAFT_env"  = var.environment
    "SPAWN_ANIMALS"   = "true"
    "SPAWN_NPCS"      = "true"
  }

}