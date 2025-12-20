variable "resource_group_location" {
  type        = string
  default     = "koreacentral"
  description = "Location of the resource group."
}

variable "resource_group_name_prefix" {
  type        = string
  default     = "rg"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "node_count" {
  type        = number
  description = "The initial quantity of nodes for the node pool."
  default     = 3
}

variable "msi_id" {
  type        = string
  description = "The Managed Service Identity ID. Set this value if you're running this example using Managed Identity as the authentication method."
  default     = null
}

variable "username" {
  type        = string
  description = "The admin username for the new cluster."
  default     = "azureadmin"
}

# MySQL Variables
variable "mysql_admin_username" {
  type        = string
  description = "MySQL administrator username"
  default     = "mysqladmin"
}

variable "mysql_admin_password" {
  type        = string
  description = "MySQL administrator password"
  sensitive   = true
}