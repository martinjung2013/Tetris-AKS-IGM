# Azure Cosmos DB Account (Keyless authentication using RBAC with Private Link for Java SDK)
resource "azurerm_cosmosdb_account" "main" {
  name                = "cosmos-${random_pet.rg_name.id}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  # Enable automatic failover
  automatic_failover_enabled = true

  # Consistency policy optimized for Java SDK
  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  # Geo-replication
  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }

  # Enable System Assigned Managed Identity (for keyless)
  identity {
    type = "SystemAssigned"
  }

  # Network configuration for Private Link
  public_network_access_enabled     = false
  is_virtual_network_filter_enabled = false

  # Enable private endpoint network policies
  network_acl_bypass_for_azure_services = false
  network_acl_bypass_ids                = []

  # Disable key-based metadata write access (enforce RBAC/keyless)
  local_authentication_disabled = true

  # Java SDK compatible settings
  analytical_storage_enabled = false

  tags = {
    environment = "production"
    sdk         = "java-private-mode"
  }
}

# Cosmos DB SQL Database
resource "azurerm_cosmosdb_sql_database" "main" {
  name                = "appdb"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.main.name
  throughput          = 400
}

# Cosmos DB SQL Container
resource "azurerm_cosmosdb_sql_container" "main" {
  name                  = "items"
  resource_group_name   = azurerm_resource_group.rg.name
  account_name          = azurerm_cosmosdb_account.main.name
  database_name         = azurerm_cosmosdb_sql_database.main.name
  partition_key_paths   = ["/id"]
  partition_key_version = 1
  throughput            = 400

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    excluded_path {
      path = "/\"_etag\"/?"
    }
  }
}

# Private Endpoint for Cosmos DB (Java SDK Gateway Mode compatible)
resource "azurerm_private_endpoint" "cosmosdb" {
  name                = "cosmosdb-private-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "cosmosdb-private-connection"
    private_connection_resource_id = azurerm_cosmosdb_account.main.id
    is_manual_connection           = false
    subresource_names              = ["Sql"]
  }

  private_dns_zone_group {
    name                 = "cosmosdb-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.cosmosdb.id]
  }

  tags = {
    environment = "production"
    purpose     = "java-sdk-private-mode"
  }
}

# Additional Private Endpoint for AKS Subnet (Java SDK Direct Mode)
resource "azurerm_private_endpoint" "cosmosdb_aks" {
  name                = "cosmosdb-aks-private-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.aks.id

  private_service_connection {
    name                           = "cosmosdb-aks-private-connection"
    private_connection_resource_id = azurerm_cosmosdb_account.main.id
    is_manual_connection           = false
    subresource_names              = ["Sql"]
  }

  private_dns_zone_group {
    name                 = "cosmosdb-aks-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.cosmosdb.id]
  }

  tags = {
    environment = "production"
    purpose     = "aks-java-sdk-direct-mode"
  }
}

# Private DNS Zone for Cosmos DB
resource "azurerm_private_dns_zone" "cosmosdb" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

# Private DNS Zone VNet Link for Cosmos DB
resource "azurerm_private_dns_zone_virtual_network_link" "cosmosdb" {
  name                  = "cosmosdb-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.cosmosdb.name
  resource_group_name   = azurerm_resource_group.rg.name
  virtual_network_id    = azurerm_virtual_network.main.id
}
