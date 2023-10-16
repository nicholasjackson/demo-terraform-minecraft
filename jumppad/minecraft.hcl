resource "container" "minecraft" {
  image {
    name = "hashicraft/minecraftservice:v0.0.2"
  }

  network {
    id = resource.network.local.id
  }

  # Minecraft
  port {
    remote = 25565
    host   = 25565
    local  = 25565
  }

  # API Server
  port {
    remote = 9090
    host   = 9090
    local  = 9090
  }

  # Prismarine
  port {
    remote = 8080
    host   = 8080
    local  = 8080
  }

  # Microservice 
  port {
    remote = 8081
    host   = 8081
    local  = 8081
  }

  # Bluemap
  port {
    remote = 8100
    host   = 8100
    local  = 8100
  }

  environment = {
    MODS_BACKUP               = "https://github.com/nicholasjackson/demo-terraform-minecraft/releases/download/mods/mods.tar.gz"
    GAME_MODE                 = "creative"
    WHITELIST_ENABLED         = "false"
    ONLINE_MODE               = "false"
    RCON_ENABLED              = "true"
    RCON_PASSWORD             = "password"
    SPAWN_ANIMALS             = "true"
    SPAWN_NPCS                = "true"
    VAULT_ADDR                = "http://vault.container.jumppad.dev:8200"
    VAULT_TOKEN               = variable.vault_root_token
    HASHICRAFT_env            = "local"
    MICROSERVICES_db_host     = "postgres.container.jumppad.dev:5432"
    MICROSERVICES_db_password = "password"
    MICROSERVICES_db_database = "mydb"
  }

  # Mount the secrets that contain the db connection info
  volume {
    source      = "./db_env"
    destination = "/etc/db_secrets"
  }

  # Mount the local world and config files 
  volume {
    source      = "../world"
    destination = "/minecraft/world"
  }

  volume {
    source      = "../config/databases.json"
    destination = "/minecraft/config/databases.json"
  }

  volume {
    source      = "../config/webservers.json"
    destination = "/minecraft/config/webservers.json"
  }

  volume {
    source      = "../config/banned-ips.json"
    destination = "/minecraft/world/config/banned-ips.json"
  }

  volume {
    source      = "../config/banned-players.json"
    destination = "/minecraft/world/config/banned-players.json"
  }

  volume {
    source      = "../config/bukkit.yml"
    destination = "/minecraft/world/config/bukkit.yml"
  }

  volume {
    source      = "../config/ops.json"
    destination = "/minecraft/world/config/ops.json"
  }

  volume {
    source      = "../config/usercache.json"
    destination = "/minecraft/world/config/usercache.json"
  }

  volume {
    source      = "../config/whitelist.json"
    destination = "/minecraft/world/config/whitelist.json"
  }

  volume {
    source      = "../config/core.conf"
    destination = "/minecraft/world/config/bluemap/core.conf"
  }

  volume {
    source      = "../config/overworld.conf"
    destination = "/minecraft/world/config/bluemap/maps/overworld.conf"
  }

  volume {
    source      = "../config/end.conf"
    destination = "/minecraft/world/config/bluemap/maps/end.conf"
  }

  volume {
    source      = "../config/nether.conf"
    destination = "/minecraft/world/config/bluemap/maps/nether.conf"
  }
}