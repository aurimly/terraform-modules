locals {
  eventhubs = merge([
    for ns_key, ns in var.eventhub_namespaces : {
      for hub_key, hub in ns.eventhubs : "${ns_key}.${hub_key}" => merge(hub, {
        namespace_id = azurerm_eventhub_namespace.namespace[ns_key].id
      })
    }
  ]...)

  consumer_groups = merge(flatten([
    for ns_key, ns in var.eventhub_namespaces : [
      for hub_key, hub in ns.eventhubs : {
        for cg_key, cg in hub.consumer_groups : "${ns_key}.${hub_key}.${cg_key}" => merge(cg, {
          namespace_name      = ns.name
          eventhub_name       = hub.name
          resource_group_name = ns.resource_group_name
        })
      }
    ]
  ])...)

  eventhub_authorization_rules = merge(flatten([
    for ns_key, ns in var.eventhub_namespaces : [
      for hub_key, hub in ns.eventhubs : {
        for rule_key, rule in hub.authorization_rules : "${ns_key}.${hub_key}.${rule_key}" => merge(rule, {
          namespace_name      = ns.name
          eventhub_name       = hub.name
          resource_group_name = ns.resource_group_name
        })
      }
    ]
  ])...)

  namespace_authorization_rules = merge([
    for ns_key, ns in var.eventhub_namespaces : {
      for rule_key, rule in ns.authorization_rules : "${ns_key}.${rule_key}" => merge(rule, {
        namespace_name      = ns.name
        resource_group_name = ns.resource_group_name
      })
    }
  ]...)

  customer_managed_keys = {
    for ns_key, ns in var.eventhub_namespaces : ns_key => ns.customer_managed_key
    if ns.customer_managed_key != null
  }
}

resource "azurerm_eventhub_namespace" "namespace" {
  for_each = var.eventhub_namespaces

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  sku                 = each.value.sku
  capacity            = each.value.capacity

  dedicated_cluster_id          = each.value.dedicated_cluster_id
  public_network_access_enabled = each.value.public_network_access_enabled
  local_authentication_enabled  = each.value.local_authentication_enabled

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "network_rulesets" {
    for_each = each.value.network_rulesets != null ? [each.value.network_rulesets] : []
    content {
      default_action = network_rulesets.value.default_action

      dynamic "ip_rule" {
        for_each = network_rulesets.value.ip_rules
        content {
          ip_mask = ip_rule.value.ip_mask
          action  = ip_rule.value.action
        }
      }

      dynamic "virtual_network_rule" {
        for_each = network_rulesets.value.virtual_network_rules
        content {
          subnet_id                                       = virtual_network_rule.value.subnet_id
          ignore_missing_virtual_network_service_endpoint = virtual_network_rule.value.ignore_missing_virtual_network_service_endpoint
        }
      }

      trusted_service_access_enabled = network_rulesets.value.trusted_service_access_enabled
    }
  }

  tags = each.value.tags
}

resource "azurerm_eventhub_namespace_customer_managed_key" "cmk" {
  for_each = local.customer_managed_keys

  eventhub_namespace_id             = azurerm_eventhub_namespace.namespace[each.key].id
  key_vault_key_ids                 = each.value.key_vault_key_ids
  user_assigned_identity_id         = each.value.user_assigned_identity_id
  infrastructure_encryption_enabled = each.value.infrastructure_encryption_enabled
}

resource "azurerm_eventhub" "hub" {
  for_each = local.eventhubs

  name              = each.value.name
  namespace_id      = each.value.namespace_id
  partition_count   = each.value.partition_count
  message_retention = each.value.message_retention
  status            = each.value.status

  dynamic "capture_description" {
    for_each = each.value.capture_description != null ? [each.value.capture_description] : []
    content {
      enabled             = capture_description.value.enabled
      encoding            = capture_description.value.encoding
      interval_in_seconds = capture_description.value.interval_in_seconds
      size_limit_in_bytes = capture_description.value.size_limit_in_bytes
      skip_empty_archives = capture_description.value.skip_empty_archives

      destination {
        name                        = "EventHubArchive.AzureBlockBlob"
        archive_name_format         = capture_description.value.destination.archive_name_format
        blob_container_name         = capture_description.value.destination.blob_container_name
        storage_account_id          = capture_description.value.destination.storage_account_id
        storage_authentication_type = capture_description.value.destination.storage_authentication_type
        storage_authentication_id   = capture_description.value.destination.storage_authentication_id
      }
    }
  }
}

resource "azurerm_eventhub_consumer_group" "consumer_group" {
  for_each = local.consumer_groups

  name                = each.value.name
  namespace_name      = each.value.namespace_name
  eventhub_name       = each.value.eventhub_name
  resource_group_name = each.value.resource_group_name
  user_metadata       = each.value.user_metadata
}

resource "azurerm_eventhub_authorization_rule" "hub_rule" {
  for_each = local.eventhub_authorization_rules

  name                = each.value.name
  namespace_name      = each.value.namespace_name
  eventhub_name       = each.value.eventhub_name
  resource_group_name = each.value.resource_group_name
  listen              = each.value.listen
  send                = each.value.send
  manage              = each.value.manage
}

resource "azurerm_eventhub_namespace_authorization_rule" "namespace_rule" {
  for_each = local.namespace_authorization_rules

  name                = each.value.name
  namespace_name      = each.value.namespace_name
  resource_group_name = each.value.resource_group_name
  listen              = each.value.listen
  send                = each.value.send
  manage              = each.value.manage
}
