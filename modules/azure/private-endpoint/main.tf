locals {
  virtual_network_links = {
    for link in flatten([
      for zone_key, zone in var.private_dns_zones : [
        for link_key, link in zone.virtual_network_links : {
          key                  = "${zone_key}.${link_key}"
          zone_key             = zone_key
          name                 = link.name
          virtual_network_id   = link.virtual_network_id
          registration_enabled = link.registration_enabled
          resolution_policy    = link.resolution_policy
          tags                 = link.tags
        }
      ]
    ]) : link.key => link
  }
}

resource "azurerm_private_endpoint" "endpoint" {
  for_each = var.private_endpoints

  name                          = each.value.name
  location                      = each.value.location
  resource_group_name           = each.value.resource_group_name
  subnet_id                     = each.value.subnet_id
  custom_network_interface_name = each.value.custom_network_interface_name
  edge_zone                     = each.value.edge_zone

  private_service_connection {
    name                              = each.value.private_service_connection.name
    is_manual_connection              = each.value.private_service_connection.is_manual_connection
    private_connection_resource_id    = each.value.private_service_connection.private_connection_resource_id
    private_connection_resource_alias = each.value.private_service_connection.private_connection_resource_alias
    subresource_names                 = each.value.private_service_connection.subresource_names
    request_message                   = each.value.private_service_connection.request_message
  }

  dynamic "private_dns_zone_group" {
    for_each = each.value.private_dns_zone_group != null ? [each.value.private_dns_zone_group] : []

    content {
      name                 = private_dns_zone_group.value.name
      private_dns_zone_ids = private_dns_zone_group.value.private_dns_zone_ids
    }
  }

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      subresource_name   = ip_configuration.value.subresource_name
      member_name        = ip_configuration.value.member_name
    }
  }

  tags = each.value.tags
}

resource "azurerm_private_dns_zone" "private_dns_zone" {
  for_each = var.private_dns_zones

  name                = each.value.name
  resource_group_name = each.value.resource_group_name

  dynamic "soa_record" {
    for_each = each.value.soa_record != null ? [each.value.soa_record] : []

    content {
      email        = soa_record.value.email
      expire_time  = soa_record.value.expire_time
      minimum_ttl  = soa_record.value.minimum_ttl
      refresh_time = soa_record.value.refresh_time
      retry_time   = soa_record.value.retry_time
      ttl          = soa_record.value.ttl
    }
  }

  tags = each.value.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "link" {
  for_each = local.virtual_network_links

  name                 = each.value.name
  private_dns_zone_id  = azurerm_private_dns_zone.private_dns_zone[each.value.zone_key].id
  virtual_network_id   = each.value.virtual_network_id
  registration_enabled = each.value.registration_enabled
  resolution_policy    = each.value.resolution_policy
  tags                 = each.value.tags
}
