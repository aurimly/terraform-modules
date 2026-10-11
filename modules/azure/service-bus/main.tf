locals {
  queues = merge([
    for namespace_key, namespace in var.servicebus_namespaces : {
      for queue_key, queue in namespace.queues : "${namespace_key}.${queue_key}" => merge(queue, {
        namespace_id = azurerm_servicebus_namespace.namespace[namespace_key].id
      })
    }
  ]...)

  topics = merge([
    for namespace_key, namespace in var.servicebus_namespaces : {
      for topic_key, topic in namespace.topics : "${namespace_key}.${topic_key}" => merge(topic, {
        namespace_id = azurerm_servicebus_namespace.namespace[namespace_key].id
      })
    }
  ]...)

  subscriptions = merge(flatten([
    for namespace_key, namespace in var.servicebus_namespaces : [
      for topic_key, topic in namespace.topics : {
        for subscription_key, subscription in topic.subscriptions : "${namespace_key}.${topic_key}.${subscription_key}" => merge(subscription, {
          topic_id = azurerm_servicebus_topic.topic["${namespace_key}.${topic_key}"].id
        })
      }
    ]
  ])...)

  subscription_rules = merge(flatten([
    for namespace_key, namespace in var.servicebus_namespaces : [
      for topic_key, topic in namespace.topics : [
        for subscription_key, subscription in topic.subscriptions : {
          for rule_key, rule in subscription.rules : "${namespace_key}.${topic_key}.${subscription_key}.${rule_key}" => merge(rule, {
            subscription_id = azurerm_servicebus_subscription.subscription["${namespace_key}.${topic_key}.${subscription_key}"].id
          })
        }
      ]
    ]
  ])...)

  namespace_authorization_rules = merge([
    for namespace_key, namespace in var.servicebus_namespaces : {
      for rule_key, rule in namespace.authorization_rules : "${namespace_key}.${rule_key}" => merge(rule, {
        namespace_id = azurerm_servicebus_namespace.namespace[namespace_key].id
      })
    }
  ]...)

  queue_authorization_rules = merge(flatten([
    for namespace_key, namespace in var.servicebus_namespaces : [
      for queue_key, queue in namespace.queues : {
        for rule_key, rule in queue.authorization_rules : "${namespace_key}.${queue_key}.${rule_key}" => merge(rule, {
          queue_id = azurerm_servicebus_queue.queue["${namespace_key}.${queue_key}"].id
        })
      }
    ]
  ])...)

  topic_authorization_rules = merge(flatten([
    for namespace_key, namespace in var.servicebus_namespaces : [
      for topic_key, topic in namespace.topics : {
        for rule_key, rule in topic.authorization_rules : "${namespace_key}.${topic_key}.${rule_key}" => merge(rule, {
          topic_id = azurerm_servicebus_topic.topic["${namespace_key}.${topic_key}"].id
        })
      }
    ]
  ])...)
}

resource "azurerm_servicebus_namespace" "namespace" {
  for_each = var.servicebus_namespaces

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  sku                 = each.value.sku

  capacity                     = each.value.capacity
  premium_messaging_partitions = each.value.premium_messaging_partitions

  local_auth_enabled            = each.value.local_auth_enabled
  minimum_tls_version           = each.value.minimum_tls_version
  public_network_access_enabled = each.value.public_network_access_enabled

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "customer_managed_key" {
    for_each = each.value.customer_managed_key != null ? [each.value.customer_managed_key] : []
    content {
      key_vault_key_id                  = customer_managed_key.value.key_vault_key_id
      identity_id                       = customer_managed_key.value.identity_id
      infrastructure_encryption_enabled = customer_managed_key.value.infrastructure_encryption_enabled
    }
  }

  dynamic "network_rule_set" {
    for_each = each.value.network_rule_set != null ? [each.value.network_rule_set] : []
    content {
      default_action                = network_rule_set.value.default_action
      public_network_access_enabled = network_rule_set.value.public_network_access_enabled
      trusted_services_allowed      = network_rule_set.value.trusted_services_allowed
      ip_rules                      = network_rule_set.value.ip_rules
      dynamic "network_rules" {
        for_each = network_rule_set.value.network_rules
        content {
          subnet_id                            = network_rules.value.subnet_id
          ignore_missing_vnet_service_endpoint = network_rules.value.ignore_missing_vnet_service_endpoint
        }
      }
    }
  }

  tags = each.value.tags
}

resource "azurerm_servicebus_queue" "queue" {
  for_each = local.queues

  name         = each.value.name
  namespace_id = each.value.namespace_id

  lock_duration                           = each.value.lock_duration
  max_size_in_megabytes                   = each.value.max_size_in_megabytes
  max_delivery_count                      = each.value.max_delivery_count
  default_message_ttl                     = each.value.default_message_ttl
  dead_lettering_on_message_expiration    = each.value.dead_lettering_on_message_expiration
  requires_duplicate_detection            = each.value.requires_duplicate_detection
  duplicate_detection_history_time_window = each.value.duplicate_detection_history_time_window
  requires_session                        = each.value.requires_session

  batched_operations_enabled = each.value.batched_operations_enabled
  express_enabled            = each.value.express_enabled
  partitioning_enabled       = each.value.partitioning_enabled
  status                     = each.value.status

  forward_to                        = each.value.forward_to
  forward_dead_lettered_messages_to = each.value.forward_dead_lettered_messages_to
}

resource "azurerm_servicebus_topic" "topic" {
  for_each = local.topics

  name         = each.value.name
  namespace_id = each.value.namespace_id

  max_size_in_megabytes                   = each.value.max_size_in_megabytes
  default_message_ttl                     = each.value.default_message_ttl
  requires_duplicate_detection            = each.value.requires_duplicate_detection
  duplicate_detection_history_time_window = each.value.duplicate_detection_history_time_window

  batched_operations_enabled = each.value.batched_operations_enabled
  express_enabled            = each.value.express_enabled
  partitioning_enabled       = each.value.partitioning_enabled
  status                     = each.value.status
  support_ordering           = each.value.support_ordering
}

resource "azurerm_servicebus_subscription" "subscription" {
  for_each = local.subscriptions

  name     = each.value.name
  topic_id = each.value.topic_id

  max_delivery_count                        = each.value.max_delivery_count
  lock_duration                             = each.value.lock_duration
  dead_lettering_on_message_expiration      = each.value.dead_lettering_on_message_expiration
  dead_lettering_on_filter_evaluation_error = each.value.dead_lettering_on_filter_evaluation_error
  batched_operations_enabled                = each.value.batched_operations_enabled
  requires_session                          = each.value.requires_session
  status                                    = each.value.status
  forward_to                                = each.value.forward_to
  forward_dead_lettered_messages_to         = each.value.forward_dead_lettered_messages_to

  client_scoped_subscription_enabled = each.value.client_scoped_subscription_enabled

  dynamic "client_scoped_subscription" {
    for_each = each.value.client_scoped_subscription_enabled && each.value.client_scoped_subscription != null ? [each.value.client_scoped_subscription] : []
    content {
      client_id                               = client_scoped_subscription.value.client_id
      is_client_scoped_subscription_shareable = client_scoped_subscription.value.is_client_scoped_subscription_shareable
    }
  }
}

resource "azurerm_servicebus_subscription_rule" "rule" {
  for_each = local.subscription_rules

  name            = each.value.name
  subscription_id = each.value.subscription_id
  filter_type     = each.value.filter_type

  sql_filter = each.value.sql_filter
  action     = each.value.action

  dynamic "correlation_filter" {
    for_each = each.value.correlation_filter != null ? [each.value.correlation_filter] : []
    content {
      content_type        = correlation_filter.value.content_type
      message_id          = correlation_filter.value.message_id
      correlation_id      = correlation_filter.value.correlation_id
      properties          = correlation_filter.value.properties
      label               = correlation_filter.value.subject
      reply_to            = correlation_filter.value.reply_to
      reply_to_session_id = correlation_filter.value.reply_to_session_id
      session_id          = correlation_filter.value.session_id
      to                  = correlation_filter.value.to
    }
  }
}

resource "azurerm_servicebus_namespace_authorization_rule" "namespace_rule" {
  for_each = local.namespace_authorization_rules

  name         = each.value.name
  namespace_id = each.value.namespace_id

  listen = each.value.listen
  send   = each.value.send
  manage = each.value.manage
}

resource "azurerm_servicebus_queue_authorization_rule" "queue_rule" {
  for_each = local.queue_authorization_rules

  name     = each.value.name
  queue_id = each.value.queue_id

  listen = each.value.listen
  send   = each.value.send
  manage = each.value.manage
}

resource "azurerm_servicebus_topic_authorization_rule" "topic_rule" {
  for_each = local.topic_authorization_rules

  name     = each.value.name
  topic_id = each.value.topic_id

  listen = each.value.listen
  send   = each.value.send
  manage = each.value.manage
}
