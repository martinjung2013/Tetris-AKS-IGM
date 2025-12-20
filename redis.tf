# Azure Cache for Redis (with Managed Identity for keyless authentication)
resource "azurerm_redis_cache" "main" {
  name                 = "redis-${random_pet.rg_name.id}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  capacity             = 1
  family               = "C"
  sku_name             = "Standard"
  non_ssl_port_enabled = false
  minimum_tls_version  = "1.2"

  # Enable System Assigned Managed Identity for keyless authentication
  identity {
    type = "SystemAssigned"
  }

  # Redis configuration
  redis_configuration {
    # RDB persistence removed - only available in Premium SKU
    # Standard SKU provides default persistence
  }

  # Public network access disabled for security
  public_network_access_enabled = false

  tags = {
    environment = "production"
  }
}

# Private Endpoint for Redis
resource "azurerm_private_endpoint" "redis" {
  name                = "redis-private-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "redis-private-connection"
    private_connection_resource_id = azurerm_redis_cache.main.id
    is_manual_connection           = false
    subresource_names              = ["redisCache"]
  }

  private_dns_zone_group {
    name                 = "redis-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.redis.id]
  }
}

# Private DNS Zone for Redis
resource "azurerm_private_dns_zone" "redis" {
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

# Private DNS Zone VNet Link for Redis
resource "azurerm_private_dns_zone_virtual_network_link" "redis" {
  name                  = "redis-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.redis.name
  resource_group_name   = azurerm_resource_group.rg.name
  virtual_network_id    = azurerm_virtual_network.main.id
}
