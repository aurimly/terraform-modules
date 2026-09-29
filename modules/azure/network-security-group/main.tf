locals {
  security_rules = { for pair in flatten([
    for group_key, group in var.network_security_groups : [
      for rule_key, rule in group.security_rules : {
        key       = "${group_key}.${rule_key}"
        group_key = group_key
        rule      = rule
      }
    ]
    if length(group.security_rules) > 0
  ]) : pair.key => pair }
}

resource "azurerm_network_security_group" "network_security_group" {
  for_each = var.network_security_groups

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  tags                = each.value.tags
}

resource "azurerm_network_security_rule" "security_rule" {
  for_each = local.security_rules

  name                        = each.value.rule.name
  priority                    = each.value.rule.priority
  direction                   = each.value.rule.direction
  access                      = each.value.rule.access
  protocol                    = each.value.rule.protocol
  description                 = each.value.rule.description
  network_security_group_name = azurerm_network_security_group.network_security_group[each.value.group_key].name
  resource_group_name         = azurerm_network_security_group.network_security_group[each.value.group_key].resource_group_name

  source_port_range       = each.value.rule.source_port_range
  source_port_ranges      = each.value.rule.source_port_ranges
  destination_port_range  = each.value.rule.destination_port_range
  destination_port_ranges = each.value.rule.destination_port_ranges

  source_address_prefix                      = each.value.rule.source_address_prefix
  source_address_prefixes                    = each.value.rule.source_address_prefixes
  source_application_security_group_ids      = each.value.rule.source_application_security_group_ids
  destination_address_prefix                 = each.value.rule.destination_address_prefix
  destination_address_prefixes               = each.value.rule.destination_address_prefixes
  destination_application_security_group_ids = each.value.rule.destination_application_security_group_ids
}
