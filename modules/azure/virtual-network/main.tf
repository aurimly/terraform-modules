resource "azurerm_virtual_network" "virtual_network" {
  for_each = var.virtual_networks

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  address_space       = each.value.address_space
  dns_servers         = each.value.dns_servers
  bgp_community       = each.value.bgp_community
  edge_zone           = each.value.edge_zone

  flow_timeout_in_minutes        = each.value.flow_timeout_in_minutes
  private_endpoint_vnet_policies = each.value.private_endpoint_vnet_policies
  tags                           = each.value.tags

  dynamic "ddos_protection_plan" {
    for_each = each.value.ddos_protection_plan_id != null ? [1] : []

    content {
      id     = each.value.ddos_protection_plan_id
      enable = each.value.enable_ddos_protection_plan
    }
  }

  dynamic "encryption" {
    for_each = each.value.encryption_enforcement != null ? [1] : []

    content {
      enforcement = each.value.encryption_enforcement
    }
  }
}
