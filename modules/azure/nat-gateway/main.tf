locals {
  public_ip_associations = {
    for association in flatten([
      for gateway_key, gateway in var.nat_gateways : [
        for index, public_ip_address_id in gateway.public_ip_address_ids : {
          key                  = "${gateway_key}.pip${index}"
          gateway_key          = gateway_key
          public_ip_address_id = public_ip_address_id
        }
      ]
    ]) : association.key => association
  }

  public_ip_prefix_associations = {
    for association in flatten([
      for gateway_key, gateway in var.nat_gateways : [
        for index, public_ip_prefix_id in gateway.public_ip_prefix_ids : {
          key                 = "${gateway_key}.prefix${index}"
          gateway_key         = gateway_key
          public_ip_prefix_id = public_ip_prefix_id
        }
      ]
    ]) : association.key => association
  }
}

resource "azurerm_nat_gateway" "nat_gateway" {
  for_each = var.nat_gateways

  name                    = each.value.name
  resource_group_name     = each.value.resource_group_name
  location                = each.value.location
  sku_name                = each.value.sku_name
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
  zones                   = each.value.zones
  tags                    = each.value.tags
}

resource "azurerm_nat_gateway_public_ip_association" "public_ip" {
  for_each = local.public_ip_associations

  nat_gateway_id       = azurerm_nat_gateway.nat_gateway[each.value.gateway_key].id
  public_ip_address_id = each.value.public_ip_address_id
}

resource "azurerm_nat_gateway_public_ip_prefix_association" "public_ip_prefix" {
  for_each = local.public_ip_prefix_associations

  nat_gateway_id      = azurerm_nat_gateway.nat_gateway[each.value.gateway_key].id
  public_ip_prefix_id = each.value.public_ip_prefix_id
}
