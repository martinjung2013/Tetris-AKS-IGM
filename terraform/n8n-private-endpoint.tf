# N8N Private Endpoint Terraform 구성
#
# 주의: 이 파일은 N8N Service가 먼저 배포되어야 합니다.
# Private Link Service는 Kubernetes Service에 의해 자동 생성됩니다.

# Private DNS Zone for N8N
resource "azurerm_private_dns_zone" "n8n" {
  name                = "n8n.internal"
  resource_group_name = var.resource_group_name

  tags = {
    environment = "production"
    service     = "n8n"
  }
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "n8n" {
  name                  = "n8n-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.n8n.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false

  tags = {
    environment = "production"
  }
}

# Data source to find the Private Link Service created by AKS
# 주의: 이것은 N8N Service가 배포된 후에만 작동합니다
data "azurerm_private_link_service" "n8n" {
  # Private Link Service는 Node Resource Group에 생성됩니다
  name                = "n8n-pls"
  resource_group_name = azurerm_kubernetes_cluster.k8s.node_resource_group

  # Service가 생성될 때까지 대기
  depends_on = [
    azurerm_kubernetes_cluster.k8s
  ]
}

# Private Endpoint for N8N
resource "azurerm_private_endpoint" "n8n" {
  name                = "n8n-private-endpoint"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "n8n-connection"
    private_connection_resource_id = data.azurerm_private_link_service.n8n.id
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "n8n-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.n8n.id]
  }

  tags = {
    environment = "production"
    service     = "n8n"
  }

  depends_on = [
    data.azurerm_private_link_service.n8n
  ]
}

# Output the Private Endpoint IP
output "n8n_private_endpoint_ip" {
  value       = azurerm_private_endpoint.n8n.private_service_connection[0].private_ip_address
  description = "N8N Private Endpoint IP Address"
  sensitive   = false
}

# Output the Private DNS Zone
output "n8n_private_dns_zone" {
  value       = azurerm_private_dns_zone.n8n.name
  description = "N8N Private DNS Zone name"
}

# Output the access URL
output "n8n_private_url" {
  value       = "http://n8n.${azurerm_private_dns_zone.n8n.name}"
  description = "N8N Private URL (accessible from within VNet)"
}
