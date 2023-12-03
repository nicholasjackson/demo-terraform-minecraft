resource "random_password" "root_password" {
  length  = 16
  special = false
}

resource "random_string" "bucket_suffix" {
  length  = 16
  special = false
  upper   = false
}

resource "azurerm_postgresql_server" "minecraft" {
  name                = "postgresql-server-mc"
  location            = var.location
  resource_group_name = var.project

  sku_name = "B_Gen5_2"

  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  public_network_access_enabled = true

  administrator_login          = "psqladmin"
  administrator_login_password = random_password.root_password.result
  version                      = "9.5"
  ssl_minimal_tls_version_enforced = "TLSEnforcementDisabled"
  ssl_enforcement_enabled      = false
}

resource "azurerm_postgresql_firewall_rule" "minecraft" {
  name                = "all"
  resource_group_name = var.project
  server_name         = azurerm_postgresql_server.minecraft.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

resource "azurerm_postgresql_database" "minecraft" {
  name                = var.environment
  resource_group_name = var.project
  server_name         = azurerm_postgresql_server.minecraft.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

