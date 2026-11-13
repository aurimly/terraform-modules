locals {
  routes = merge([
    for table_key, table in var.route_tables : {
      for route_key, route in table.routes : "${table_key}.${route_key}" => merge(route, {
        table_key = table_key
      })
    }
  ]...)
}

resource "azurerm_route_table" "route_table" {
  for_each = var.route_tables

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  bgp_route_propagation_enabled = each.value.bgp_route_propagation_enabled
  tags                          = each.value.tags
}

resource "azurerm_route" "route" {
  for_each = local.routes

  name                   = each.value.name
  resource_group_name    = azurerm_route_table.route_table[each.value.table_key].resource_group_name
  route_table_name       = azurerm_route_table.route_table[each.value.table_key].name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_in_ip_address
}
