# Azure Database for MySQL Flexible Server - Master (Keyless authentication)
resource "azurerm_mysql_flexible_server" "main" {
  name                   = "mysql-master-${random_pet.rg_name.id}"
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  administrator_login    = var.mysql_admin_username
  administrator_password = var.mysql_admin_password

  sku_name = "GP_Standard_D2ds_v4"
  version  = "8.0.21"

  backup_retention_days        = 7
  geo_redundant_backup_enabled = true

  delegated_subnet_id = azurerm_subnet.database.id
  private_dns_zone_id = azurerm_private_dns_zone.mysql.id

  # Availability Zone
  zone = "1"

  # High Availability for Master
  high_availability {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "2"
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.mysql
  ]

  tags = {
    environment = "production"
    role        = "master"
  }
}

# MySQL Read Replica 1
resource "azurerm_mysql_flexible_server" "replica1" {
  name                = "mysql-replica1-${random_pet.rg_name.id}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  create_mode      = "Replica"
  source_server_id = azurerm_mysql_flexible_server.main.id

  delegated_subnet_id = azurerm_subnet.database.id
  private_dns_zone_id = azurerm_private_dns_zone.mysql.id

  depends_on = [
    azurerm_mysql_flexible_server.main
  ]

  tags = {
    environment = "production"
    role        = "read-replica"
  }
}

# MySQL Read Replica 2
resource "azurerm_mysql_flexible_server" "replica2" {
  name                = "mysql-replica2-${random_pet.rg_name.id}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  create_mode      = "Replica"
  source_server_id = azurerm_mysql_flexible_server.main.id

  delegated_subnet_id = azurerm_subnet.database.id
  private_dns_zone_id = azurerm_private_dns_zone.mysql.id

  depends_on = [
    azurerm_mysql_flexible_server.main
  ]

  tags = {
    environment = "production"
    role        = "read-replica"
  }
}

# Private DNS Zone for MySQL
# Note: For private DNS zone integration, Azure generates the DNS records automatically
# The zone name should not include the server name
resource "azurerm_private_dns_zone" "mysql" {
  name                = "private.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

# Private DNS Zone VNet Link for MySQL
resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  name                  = "mysql-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  resource_group_name   = azurerm_resource_group.rg.name
  virtual_network_id    = azurerm_virtual_network.main.id
}

# MySQL Firewall Rule - Allow Azure Services
resource "azurerm_mysql_flexible_server_firewall_rule" "azure_services" {
  name                = "AllowAzureServices"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.main.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# MySQL Database
resource "azurerm_mysql_flexible_database" "main" {
  name                = "appdb"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.main.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# N8N Database
resource "azurerm_mysql_flexible_database" "n8n" {
  name                = "n8n"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.main.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# Get current Azure client config
data "azurerm_client_config" "current" {}
