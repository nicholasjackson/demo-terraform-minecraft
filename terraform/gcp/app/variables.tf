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

variable "minecraft_admins" {
  default = {
    SheriffJackson = "642bf65a-0f3a-4c23-ac62-fefcb5fc420d"
  }
}

variable "lock_keys" {
  default = {
    admin = "myadminkey"
    vault = "myvaultkey"
  }
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