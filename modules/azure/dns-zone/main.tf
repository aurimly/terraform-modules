locals {
  virtual_network_links = merge([
    for zone_key, zone in var.zones : {
      for link_key, link in zone.virtual_network_links : "${zone_key}.${link_key}" => {
        zone_key             = zone_key
        link_key             = link_key
        private_dns_zone_id  = azurerm_private_dns_zone.zone[zone_key].id
        name                 = link.name
        virtual_network_id   = link.virtual_network_id
        registration_enabled = link.registration_enabled
        tags                 = link.tags
      }
    } if zone.private
  ]...)
}

resource "azurerm_dns_zone" "zone" {
  for_each = { for key, zone in var.zones : key => zone if !zone.private }

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

resource "azurerm_private_dns_zone" "zone" {
  for_each = { for key, zone in var.zones : key => zone if zone.private }

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
  private_dns_zone_id  = azurerm_private_dns_zone.zone[each.value.zone_key].id
  virtual_network_id   = each.value.virtual_network_id
  registration_enabled = each.value.registration_enabled
  tags                 = each.value.tags
}
