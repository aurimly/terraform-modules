locals {
  webhooks = merge([
    for registry_key, registry in var.container_registries : {
      for webhook_key, webhook in registry.webhooks : "${registry_key}.${webhook_key}" => merge(webhook, {
        registry_name       = registry.name
        resource_group_name = registry.resource_group_name
        location            = registry.location
      })
    }
  ]...)

  scope_maps = merge([
    for registry_key, registry in var.container_registries : {
      for scope_map_key, scope_map in registry.scope_maps : "${registry_key}.${scope_map_key}" => merge(scope_map, {
        registry_name       = registry.name
        resource_group_name = registry.resource_group_name
      })
    }
  ]...)

  tokens = merge([
    for registry_key, registry in var.container_registries : {
      for token_key, token in registry.tokens : "${registry_key}.${token_key}" => merge(token, {
        registry_name       = registry.name
        resource_group_name = registry.resource_group_name
        scope_map_id        = azurerm_container_registry_scope_map.scope_map["${registry_key}.${token.scope_map_key}"].id
      })
    }
  ]...)

  token_passwords = merge([
    for registry_key, registry in var.container_registries : {
      for token_key, token in registry.tokens : "${registry_key}.${token_key}" => merge(token, {
        container_registry_token_id = azurerm_container_registry_token.token["${registry_key}.${token_key}"].id
      })
    }
  ]...)
}

resource "azurerm_container_registry" "registry" {
  for_each = var.container_registries

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  sku                 = each.value.sku

  admin_enabled                 = each.value.admin_enabled
  public_network_access_enabled = each.value.public_network_access_enabled

  anonymous_pull_enabled = each.value.anonymous_pull_enabled
  data_endpoint_enabled  = each.value.data_endpoint_enabled

  quarantine_policy_enabled                    = each.value.quarantine_policy_enabled
  retention_policy_in_days                     = each.value.retention_policy_in_days
  zone_redundancy_enabled                      = each.value.zone_redundancy_enabled
  export_policy_enabled                        = each.value.export_policy_enabled
  azuread_authentication_as_arm_policy_enabled = each.value.azuread_authentication_as_arm_policy_enabled

  network_rule_bypass_option            = each.value.network_rule_bypass_option
  network_rule_bypass_for_tasks_enabled = each.value.network_rule_bypass_for_tasks_enabled
  role_assignment_mode                  = each.value.role_assignment_mode

  dynamic "network_rule_set" {
    for_each = each.value.network_rule_set != null ? [each.value.network_rule_set] : []
    content {
      default_action = network_rule_set.value.default_action

      dynamic "ip_rule" {
        for_each = network_rule_set.value.ip_rule
        content {
          action   = ip_rule.value.action
          ip_range = ip_rule.value.ip_range
        }
      }
    }
  }

  # the Azure API rejects georeplication blocks out of alphabetic location
  # order — the module emits them sorted no matter how the map is written
  dynamic "georeplications" {
    for_each = [
      for pair in sort([
        for geo_key, geo in each.value.georeplications : "${lower(geo.location)}|${geo_key}"
      ]) : each.value.georeplications[split("|", pair)[1]]
    ]
    content {
      location                        = georeplications.value.location
      global_endpoint_routing_enabled = georeplications.value.global_endpoint_routing_enabled
      zone_redundancy_enabled         = georeplications.value.zone_redundancy_enabled
      tags                            = georeplications.value.tags
    }
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "encryption" {
    for_each = each.value.encryption != null ? [each.value.encryption] : []
    content {
      key_vault_key_id   = encryption.value.key_vault_key_id
      identity_client_id = encryption.value.identity_client_id
    }
  }

  tags = each.value.tags
}

resource "azurerm_container_registry_webhook" "webhook" {
  for_each = local.webhooks

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  registry_name       = each.value.registry_name
  location            = each.value.location

  service_uri    = each.value.service_uri
  actions        = each.value.actions
  status         = each.value.status
  scope          = each.value.scope
  custom_headers = each.value.custom_headers

  tags = each.value.tags
}

resource "azurerm_container_registry_scope_map" "scope_map" {
  for_each = local.scope_maps

  name                    = each.value.name
  resource_group_name     = each.value.resource_group_name
  container_registry_name = each.value.registry_name

  actions     = each.value.actions
  description = each.value.description
}

resource "azurerm_container_registry_token" "token" {
  for_each = local.tokens

  name                    = each.value.name
  resource_group_name     = each.value.resource_group_name
  container_registry_name = each.value.registry_name

  scope_map_id = each.value.scope_map_id
  enabled      = each.value.enabled
}

resource "azurerm_container_registry_token_password" "password" {
  for_each = local.token_passwords

  container_registry_token_id = each.value.container_registry_token_id

  password1 {
    expiry = each.value.password1_expiry
  }

  dynamic "password2" {
    for_each = each.value.password2_expiry != null ? [each.value.password2_expiry] : []
    content {
      expiry = password2.value
    }
  }
}
