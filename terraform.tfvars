# Terraform Variables for AKS Deployment
# Generated: 2025-12-20

# Resource Group Configuration
resource_group_location    = "koreacentral"
resource_group_name_prefix = "rg"

# AKS Cluster Configuration
node_count = 3
username   = "azureadmin"

# MySQL Configuration
mysql_admin_username = "mysqladmin"
mysql_admin_password = "AksDeployment@2025!SecurePass123"
