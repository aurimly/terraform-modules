resource "azurerm_network_interface" "network_interface" {
  for_each = var.network_interfaces

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  dns_servers                    = each.value.dns_servers
  internal_dns_name_label        = each.value.internal_dns_name_label
  accelerated_networking_enabled = each.value.accelerated_networking_enabled
  ip_forwarding_enabled          = each.value.ip_forwarding_enabled

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name = ip_configuration.key

      subnet_id                     = ip_configuration.value.subnet_id
      private_ip_address_allocation = ip_configuration.value.private_ip_address_allocation
      private_ip_address            = ip_configuration.value.private_ip_address
      private_ip_address_version    = ip_configuration.value.private_ip_address_version
      public_ip_address_id          = ip_configuration.value.public_ip_address_id
      primary                       = ip_configuration.value.primary
    }
  }

  tags = each.value.tags
}
