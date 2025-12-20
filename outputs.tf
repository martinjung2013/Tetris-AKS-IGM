output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "kubernetes_cluster_name" {
  value = azurerm_kubernetes_cluster.k8s.name
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.k8s.kube_config[0].client_certificate
  sensitive = true
}

output "client_key" {
  value     = azurerm_kubernetes_cluster.k8s.kube_config[0].client_key
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = azurerm_kubernetes_cluster.k8s.kube_config[0].cluster_ca_certificate
  sensitive = true
}

output "cluster_password" {
  value     = azurerm_kubernetes_cluster.k8s.kube_config[0].password
  sensitive = true
}

output "cluster_username" {
  value     = azurerm_kubernetes_cluster.k8s.kube_config[0].username
  sensitive = true
}

output "host" {
  value     = azurerm_kubernetes_cluster.k8s.kube_config[0].host
  sensitive = true
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.k8s.kube_config_raw
  sensitive = true
}

# Network Outputs
output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "aks_subnet_id" {
  value = azurerm_subnet.aks.id
}

output "appgw_public_ip" {
  value = azurerm_public_ip.appgw.ip_address
}

# Database Outputs - MySQL Master-Replica
output "mysql_master_fqdn" {
  value       = azurerm_mysql_flexible_server.main.fqdn
  sensitive   = true
  description = "MySQL Master server FQDN (Read/Write)"
}

output "mysql_replica1_fqdn" {
  value       = azurerm_mysql_flexible_server.replica1.fqdn
  sensitive   = true
  description = "MySQL Replica 1 server FQDN (Read-Only)"
}

output "mysql_replica2_fqdn" {
  value       = azurerm_mysql_flexible_server.replica2.fqdn
  sensitive   = true
  description = "MySQL Replica 2 server FQDN (Read-Only)"
}

output "cosmosdb_endpoint" {
  value       = azurerm_cosmosdb_account.main.endpoint
  sensitive   = true
  description = "Cosmos DB endpoint for Java SDK with Private Link"
}

output "redis_hostname" {
  value     = azurerm_redis_cache.main.hostname
  sensitive = true
}

# Managed Identity Outputs (for keyless authentication)
output "cosmosdb_identity_principal_id" {
  value       = azurerm_cosmosdb_account.main.identity[0].principal_id
  description = "Cosmos DB Managed Identity Principal ID for RBAC assignment"
}

output "redis_identity_principal_id" {
  value       = azurerm_redis_cache.main.identity[0].principal_id
  description = "Redis Managed Identity Principal ID for AAD auth"
}

# MySQL databases
output "mysql_n8n_database" {
  value       = azurerm_mysql_flexible_database.n8n.name
  description = "N8N MySQL Database name"
}