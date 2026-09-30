locals {
  zone_records = merge([
    for zone_key, zone in var.zones : {
      for record_key, record in zone.records : "${zone_key}.${record_key}" => {
        zone_key            = zone_key
        record_key          = record_key
        private             = zone.private_dns_zone_id != null
        zone_name           = zone.zone_name
        resource_group_name = zone.resource_group_name
        private_dns_zone_id = zone.private_dns_zone_id
        name                = record.name
        type                = record.type
        ttl                 = record.ttl
        records             = record.records
        record              = record.record
        target_resource_id  = record.target_resource_id
        mx                  = record.mx
        srv                 = record.srv
        txt                 = record.txt
        caa                 = record.caa
        tags                = record.tags
      }
    }
  ]...)

  public_records  = { for key, record in local.zone_records : key => record if !record.private }
  private_records = { for key, record in local.zone_records : key => record if record.private }

  a_records     = { for key, record in local.public_records : key => record if record.type == "A" }
  aaaa_records  = { for key, record in local.public_records : key => record if record.type == "AAAA" }
  caa_records   = { for key, record in local.public_records : key => record if record.type == "CAA" }
  cname_records = { for key, record in local.public_records : key => record if record.type == "CNAME" }
  mx_records    = { for key, record in local.public_records : key => record if record.type == "MX" }
  ns_records    = { for key, record in local.public_records : key => record if record.type == "NS" }
  ptr_records   = { for key, record in local.public_records : key => record if record.type == "PTR" }
  srv_records   = { for key, record in local.public_records : key => record if record.type == "SRV" }
  txt_records   = { for key, record in local.public_records : key => record if record.type == "TXT" }

  private_a_records     = { for key, record in local.private_records : key => record if record.type == "A" }
  private_aaaa_records  = { for key, record in local.private_records : key => record if record.type == "AAAA" }
  private_cname_records = { for key, record in local.private_records : key => record if record.type == "CNAME" }
  private_mx_records    = { for key, record in local.private_records : key => record if record.type == "MX" }
  private_ptr_records   = { for key, record in local.private_records : key => record if record.type == "PTR" }
  private_srv_records   = { for key, record in local.private_records : key => record if record.type == "SRV" }
  private_txt_records   = { for key, record in local.private_records : key => record if record.type == "TXT" }

  cname_alias_records = { for key, record in local.cname_records : key => record if record.target_resource_id != null }
  a_alias_records     = { for key, record in local.a_records : key => record if record.target_resource_id != null }
  aaaa_alias_records  = { for key, record in local.aaaa_records : key => record if record.target_resource_id != null }
}

resource "azurerm_dns_a_record" "a" {
  for_each = { for key, record in local.a_records : key => record if record.target_resource_id == null }

  name                = each.value.name
  zone_name           = each.value.zone_name
  resource_group_name = each.value.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records
  tags                = each.value.tags
}

resource "azurerm_dns_a_record" "a_alias" {
  for_each = local.a_alias_records

  name                = each.value.name
  zone_name           = each.value.zone_name
  resource_group_name = each.value.resource_group_name
  ttl                 = each.value.ttl
  target_resource_id  = each.value.target_resource_id
  tags                = each.value.tags
}

resource "azurerm_dns_aaaa_record" "aaaa" {
  for_each = { for key, record in local.aaaa_records : key => record if record.target_resource_id == null }

  name                = each.value.name
  zone_name           = each.value.zone_name
  resource_group_name = each.value.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records
  tags                = each.value.tags
}

resource "azurerm_dns_aaaa_record" "aaaa_alias" {
  for_each = local.aaaa_alias_records

  name                = each.value.name
  zone_name           = each.value.zone_name
  resource_group_name = each.value.resource_group_name
  ttl                 = each.value.ttl
  target_resource_id  = each.value.target_resource_id
  tags                = each.value.tags
}

resource "azurerm_dns_caa_record" "caa" {
  for_each = local.caa_records

  name                = each.value.name
  zone_name           = each.value.zone_name
  resource_group_name = each.value.resource_group_name
  ttl                 = each.value.ttl
  tags                = each.value.tags

  dynamic "record" {
    for_each = each.value.caa
    content {
      flags = record.value.flags
      tag   = record.value.tag
      value = record.value.value
    }
  }
}

resource "azurerm_dns_cname_record" "cname" {
  for_each = { for key, record in local.cname_records : key => record if record.target_resource_id == null }

  name                = each.value.name
  zone_name           = each.value.zone_name
  resource_group_name = each.value.resource_group_name
  ttl                 = each.value.ttl
  record              = each.value.record
  tags                = each.value.tags
}

resource "azurerm_dns_cname_record" "cname_alias" {
  for_each = local.cname_alias_records

  name                = each.value.name
  zone_name           = each.value.zone_name
  resource_group_name = each.value.resource_group_name
  ttl                 = each.value.ttl
  target_resource_id  = each.value.target_resource_id
  tags                = each.value.tags
}

resource "azurerm_dns_mx_record" "mx" {
  for_each = local.mx_records

  name                = each.value.name
  zone_name           = each.value.zone_name
  resource_group_name = each.value.resource_group_name
  ttl                 = each.value.ttl
  tags                = each.value.tags

  dynamic "record" {
    for_each = each.value.mx
    content {
      preference = record.value.preference
      exchange   = record.value.exchange
    }
  }
}

resource "azurerm_dns_ns_record" "ns" {
  for_each = local.ns_records

  name                = each.value.name
  zone_name           = each.value.zone_name
  resource_group_name = each.value.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records
  tags                = each.value.tags
}

resource "azurerm_dns_ptr_record" "ptr" {
  for_each = local.ptr_records

  name                = each.value.name
  zone_name           = each.value.zone_name
  resource_group_name = each.value.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records
  tags                = each.value.tags
}

resource "azurerm_dns_srv_record" "srv" {
  for_each = local.srv_records

  name                = each.value.name
  zone_name           = each.value.zone_name
  resource_group_name = each.value.resource_group_name
  ttl                 = each.value.ttl
  tags                = each.value.tags

  dynamic "record" {
    for_each = each.value.srv
    content {
      priority = record.value.priority
      weight   = record.value.weight
      port     = record.value.port
      target   = record.value.target
    }
  }
}

resource "azurerm_dns_txt_record" "txt" {
  for_each = local.txt_records

  name                = each.value.name
  zone_name           = each.value.zone_name
  resource_group_name = each.value.resource_group_name
  ttl                 = each.value.ttl
  tags                = each.value.tags

  dynamic "record" {
    for_each = each.value.txt
    content {
      value = record.value
    }
  }
}

resource "azurerm_private_dns_a_record" "private_a" {
  for_each = local.private_a_records

  name                = each.value.name
  private_dns_zone_id = each.value.private_dns_zone_id
  ttl                 = each.value.ttl
  records             = each.value.records
  tags                = each.value.tags
}

resource "azurerm_private_dns_aaaa_record" "private_aaaa" {
  for_each = local.private_aaaa_records

  name                = each.value.name
  private_dns_zone_id = each.value.private_dns_zone_id
  ttl                 = each.value.ttl
  records             = each.value.records
  tags                = each.value.tags
}

resource "azurerm_private_dns_cname_record" "private_cname" {
  for_each = local.private_cname_records

  name                = each.value.name
  private_dns_zone_id = each.value.private_dns_zone_id
  ttl                 = each.value.ttl
  record              = each.value.record
  tags                = each.value.tags
}

resource "azurerm_private_dns_mx_record" "private_mx" {
  for_each = local.private_mx_records

  name                = each.value.name
  private_dns_zone_id = each.value.private_dns_zone_id
  ttl                 = each.value.ttl
  tags                = each.value.tags

  dynamic "record" {
    for_each = each.value.mx
    content {
      preference = record.value.preference
      exchange   = record.value.exchange
    }
  }
}

resource "azurerm_private_dns_ptr_record" "private_ptr" {
  for_each = local.private_ptr_records

  name                = each.value.name
  private_dns_zone_id = each.value.private_dns_zone_id
  ttl                 = each.value.ttl
  records             = each.value.records
  tags                = each.value.tags
}

resource "azurerm_private_dns_srv_record" "private_srv" {
  for_each = local.private_srv_records

  name                = each.value.name
  private_dns_zone_id = each.value.private_dns_zone_id
  ttl                 = each.value.ttl
  tags                = each.value.tags

  dynamic "record" {
    for_each = each.value.srv
    content {
      priority = record.value.priority
      weight   = record.value.weight
      port     = record.value.port
      target   = record.value.target
    }
  }
}

resource "azurerm_private_dns_txt_record" "private_txt" {
  for_each = local.private_txt_records

  name                = each.value.name
  private_dns_zone_id = each.value.private_dns_zone_id
  ttl                 = each.value.ttl
  tags                = each.value.tags

  dynamic "record" {
    for_each = each.value.txt
    content {
      value = record.value
    }
  }
}
