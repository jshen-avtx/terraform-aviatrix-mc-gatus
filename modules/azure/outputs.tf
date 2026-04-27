output "azure_dashboard_public_ip" {
  description = "Public IP address of the dashboard instance"
  value       = var.dashboard ? module.dashboard[0].public_ips.network_interface_1-ip_configuration_1.ip_address : null
}

output "azure_local_user_password" {
  description = "The generated random local_user_password"
  value       = var.local_user_password != null ? null : random_password.password[0].result
  sensitive   = true
}

output "azure_vnet" {
  description = "The Azure VNet resource ID and name"
  value = {
    resource_id = module.vnet.resource_id
    name        = module.vnet.name
  }
}

output "azure_gateway_subnet" {
  description = "The Azure gateway subnet ID and address prefixes"
  value = {
    id               = azurerm_subnet.public_gateway.id
    address_prefixes = azurerm_subnet.public_gateway.address_prefixes
  }
}
