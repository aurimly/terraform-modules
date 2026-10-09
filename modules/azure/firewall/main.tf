locals {
  rule_collection_groups = { for rcg_key, rcg in var.firewall_policy_rule_collection_groups : "${rcg.firewall_policy_key}.${rcg_key}" => merge(rcg, { policy_id = azurerm_firewall_policy.policy[rcg.firewall_policy_key].id }) }

  public_ip_ids = { for key, pip in azurerm_public_ip.pip : key => pip.id }
}

resource "azurerm_public_ip" "pip" {
  for_each = var.public_ips

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  allocation_method = "Static"
  sku               = "Standard"
  ip_version        = "IPv4"

  zones = each.value.availability_zone != null ? [each.value.availability_zone] : null

  tags = each.value.tags
}

resource "azurerm_firewall_policy" "policy" {
  for_each = var.firewall_policies

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  sku            = each.value.sku
  base_policy_id = each.value.base_policy_id

  threat_intelligence_mode = each.value.threat_intelligence_mode

  private_ip_ranges                 = each.value.private_ip_ranges
  auto_learn_private_ranges_enabled = each.value.auto_learn_private_ranges_enabled
  sql_redirect_allowed              = each.value.sql_redirect_allowed

  dynamic "dns" {
    for_each = each.value.dns != null ? [each.value.dns] : []

    content {
      proxy_enabled = dns.value.proxy_enabled
      servers       = dns.value.servers
    }
  }

  dynamic "threat_intelligence_allowlist" {
    for_each = each.value.threat_intelligence_allowlist != null ? [each.value.threat_intelligence_allowlist] : []

    content {
      ip_addresses = threat_intelligence_allowlist.value.ip_addresses
      fqdns        = threat_intelligence_allowlist.value.fqdns
    }
  }

  tags = each.value.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "rule_collection_group" {
  for_each = local.rule_collection_groups

  name               = each.value.name
  priority           = each.value.priority
  firewall_policy_id = each.value.policy_id

  dynamic "application_rule_collection" {
    for_each = each.value.application_rule_collections

    content {
      name     = application_rule_collection.value.name
      priority = application_rule_collection.value.priority
      action   = application_rule_collection.value.action

      dynamic "rule" {
        for_each = application_rule_collection.value.rules

        content {
          name        = rule.value.name
          description = rule.value.description

          dynamic "protocols" {
            for_each = rule.value.protocols

            content {
              type = protocols.value.type
              port = protocols.value.port
            }
          }

          source_addresses      = rule.value.source_addresses
          source_ip_groups      = rule.value.source_ip_groups
          destination_addresses = rule.value.destination_addresses
          destination_fqdns     = rule.value.destination_fqdns
          destination_fqdn_tags = rule.value.destination_fqdn_tags
          destination_urls      = rule.value.destination_urls
          web_categories        = rule.value.web_categories
          terminate_tls         = rule.value.terminate_tls

          dynamic "http_headers" {
            for_each = rule.value.http_headers

            content {
              name  = http_headers.value.name
              value = http_headers.value.value
            }
          }
        }
      }
    }
  }

  dynamic "nat_rule_collection" {
    for_each = each.value.nat_rule_collections

    content {
      name     = nat_rule_collection.value.name
      priority = nat_rule_collection.value.priority
      action   = nat_rule_collection.value.action

      dynamic "rule" {
        for_each = nat_rule_collection.value.rules

        content {
          name        = rule.value.name
          description = rule.value.description

          protocols           = rule.value.protocols
          source_addresses    = rule.value.source_addresses
          source_ip_groups    = rule.value.source_ip_groups
          destination_address = rule.value.destination_address
          destination_ports   = rule.value.destination_ports
          translated_address  = rule.value.translated_address
          translated_fqdn     = rule.value.translated_fqdn
          translated_port     = rule.value.translated_port
        }
      }
    }
  }

  dynamic "network_rule_collection" {
    for_each = each.value.network_rule_collections

    content {
      name     = network_rule_collection.value.name
      priority = network_rule_collection.value.priority
      action   = network_rule_collection.value.action

      dynamic "rule" {
        for_each = network_rule_collection.value.rules

        content {
          name        = rule.value.name
          description = rule.value.description

          protocols             = rule.value.protocols
          source_addresses      = rule.value.source_addresses
          source_ip_groups      = rule.value.source_ip_groups
          destination_ports     = rule.value.destination_ports
          destination_addresses = rule.value.destination_addresses
          destination_ip_groups = rule.value.destination_ip_groups
          destination_fqdns     = rule.value.destination_fqdns
        }
      }
    }
  }
}

resource "azurerm_firewall" "firewall" {
  for_each = var.firewalls

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  sku_name = each.value.sku_name
  sku_tier = each.value.sku_tier

  threat_intel_mode = each.value.threat_intel_mode
  dns_servers       = length(each.value.dns_servers) > 0 ? each.value.dns_servers : null
  dns_proxy_enabled = each.value.dns_proxy_enabled
  private_ip_ranges = each.value.private_ip_ranges

  firewall_policy_id = each.value.firewall_policy_key != null ? azurerm_firewall_policy.policy[each.value.firewall_policy_key].id : each.value.firewall_policy_id

  zones = each.value.zones

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name                 = ip_configuration.value.name
      subnet_id            = ip_configuration.value.subnet_id
      public_ip_address_id = ip_configuration.value.public_ip_key != null ? local.public_ip_ids[ip_configuration.value.public_ip_key] : ip_configuration.value.public_ip_address_id
    }
  }

  dynamic "management_ip_configuration" {
    for_each = each.value.management_ip_configuration != null ? [each.value.management_ip_configuration] : []

    content {
      name                 = management_ip_configuration.value.name
      subnet_id            = management_ip_configuration.value.subnet_id
      public_ip_address_id = management_ip_configuration.value.public_ip_key != null ? local.public_ip_ids[management_ip_configuration.value.public_ip_key] : management_ip_configuration.value.public_ip_address_id
    }
  }

  dynamic "virtual_hub" {
    for_each = each.value.virtual_hub != null ? [each.value.virtual_hub] : []

    content {
      virtual_hub_id  = virtual_hub.value.virtual_hub_id
      public_ip_count = virtual_hub.value.public_ip_count
    }
  }

  tags = each.value.tags
}
