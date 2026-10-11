variable "servicebus_namespaces" {
  description = "Map of Azure Service Bus namespaces keyed by an arbitrary identifier. Each entry creates one azurerm_servicebus_namespace in the named resource group; namespace names are unique across all of Azure. Nested queues, topics, subscriptions, subscription rules, and SAS authorization rules wire into the namespace this module creates itself — child resources take the parent ARM IDs, consumers only reference composite \"<namespace_key>.<child_key>\" output keys."
  type = map(object({
    name                          = string
    resource_group_name           = string
    location                      = string
    sku                           = optional(string, "Standard")
    capacity                      = optional(number)
    premium_messaging_partitions  = optional(number)
    public_network_access_enabled = optional(bool, true)
    local_auth_enabled            = optional(bool, true)
    minimum_tls_version           = optional(string, "1.2")
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))
    customer_managed_key = optional(object({
      key_vault_key_id                  = string
      identity_id                       = string
      infrastructure_encryption_enabled = optional(bool, false)
    }))
    network_rule_set = optional(object({
      default_action                = string
      public_network_access_enabled = optional(bool, true)
      ip_rules                      = optional(set(string), [])
      trusted_services_allowed      = optional(bool, false)
      network_rules = optional(list(object({
        subnet_id                            = string
        ignore_missing_vnet_service_endpoint = optional(bool, false)
      })), [])
    }))
    queues = optional(map(object({
      name                                    = string
      lock_duration                           = optional(string)
      max_size_in_megabytes                   = optional(number)
      max_delivery_count                      = optional(number, 10)
      default_message_ttl                     = optional(string)
      dead_lettering_on_message_expiration    = optional(bool, false)
      requires_duplicate_detection            = optional(bool, false)
      duplicate_detection_history_time_window = optional(string)
      requires_session                        = optional(bool, false)
      batched_operations_enabled              = optional(bool, true)
      express_enabled                         = optional(bool)
      partitioning_enabled                    = optional(bool, false)
      status                                  = optional(string, "Active")
      forward_to                              = optional(string)
      forward_dead_lettered_messages_to       = optional(string)
      authorization_rules = optional(map(object({
        name   = string
        listen = optional(bool, false)
        send   = optional(bool, false)
        manage = optional(bool, false)
      })), {})
    })), {})
    topics = optional(map(object({
      name                                    = string
      max_size_in_megabytes                   = optional(number)
      default_message_ttl                     = optional(string)
      requires_duplicate_detection            = optional(bool, false)
      duplicate_detection_history_time_window = optional(string)
      batched_operations_enabled              = optional(bool, true)
      express_enabled                         = optional(bool)
      partitioning_enabled                    = optional(bool, false)
      status                                  = optional(string, "Active")
      support_ordering                        = optional(bool, false)
      authorization_rules = optional(map(object({
        name   = string
        listen = optional(bool, false)
        send   = optional(bool, false)
        manage = optional(bool, false)
      })), {})
      subscriptions = optional(map(object({
        name                                      = string
        max_delivery_count                        = number
        lock_duration                             = optional(string)
        requires_session                          = optional(bool, false)
        dead_lettering_on_message_expiration      = optional(bool, false)
        dead_lettering_on_filter_evaluation_error = optional(bool, true)
        batched_operations_enabled                = optional(bool, true)
        status                                    = optional(string, "Active")
        forward_to                                = optional(string)
        forward_dead_lettered_messages_to         = optional(string)
        client_scoped_subscription_enabled        = optional(bool, false)
        client_scoped_subscription = optional(object({
          client_id                               = string
          is_client_scoped_subscription_shareable = optional(bool, true)
        }))
        rules = optional(map(object({
          name        = string
          filter_type = string
          sql_filter  = optional(string)
          correlation_filter = optional(object({
            content_type        = optional(string)
            message_id          = optional(string)
            correlation_id      = optional(string)
            properties          = optional(map(string))
            subject             = optional(string)
            reply_to            = optional(string)
            reply_to_session_id = optional(string)
            session_id          = optional(string)
            to                  = optional(string)
          }))
          action = optional(string)
        })), {})
      })), {})
    })), {})
    authorization_rules = optional(map(object({
      name   = string
      listen = optional(bool, false)
      send   = optional(bool, false)
      manage = optional(bool, false)
    })), {})
    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for namespace in var.servicebus_namespaces : can(regex("^[a-zA-Z][a-zA-Z0-9-]{4,48}[a-zA-Z0-9]$", namespace.name))
    ])
    error_message = "name must be 6–50 characters, letters, digits and hyphens only — starting with a letter, ending alphanumeric, no leading/trailing hyphen; the name is the host of the namespace's endpoint (<name>.servicebus.windows.net) and must be unique across all of Azure, which the module cannot check: a claimed name fails at apply."
  }

  validation {
    condition = alltrue(flatten([
      for key, namespace in var.servicebus_namespaces : [
        for other_key, other in var.servicebus_namespaces :
        key == other_key || lower(namespace.name) != lower(other.name)
      ]
    ]))
    error_message = "namespace names must be unique across entries, case-insensitively — the endpoint host is case-insensitive, so two entries with the same name collide at the Azure API."
  }

  validation {
    condition = alltrue([
      for namespace in var.servicebus_namespaces : length(trimspace(namespace.name)) > 0 && length(trimspace(namespace.resource_group_name)) > 0 && length(trimspace(namespace.location)) > 0
    ])
    error_message = "name, resource_group_name and location must not be empty."
  }

  validation {
    condition = alltrue([
      for namespace in var.servicebus_namespaces : contains(["Basic", "Standard", "Premium"], namespace.sku)
    ])
    error_message = "sku must be Basic, Standard or Premium (case-sensitive) — Basic carries queues only, Standard adds topics and subscriptions, Premium is the dedicated-resource tier; changing it forces replacement."
  }

  validation {
    condition = alltrue([
      for namespace in var.servicebus_namespaces : namespace.sku == "Premium" || (namespace.capacity == null && namespace.premium_messaging_partitions == null && namespace.customer_managed_key == null)
    ])
    error_message = "capacity, premium_messaging_partitions and customer_managed_key belong to the Premium tier only — on Basic or Standard they must stay unset; Basic/Standard namespaces scale as shared capacity units and encrypt with Azure-managed keys."
  }

  validation {
    condition = alltrue([
      for namespace in var.servicebus_namespaces : namespace.capacity == null || contains([1, 2, 4, 8, 16], namespace.capacity)
    ])
    error_message = "capacity (Premium only) must be 1, 2, 4, 8 or 16 — the messaging-units count reserved for the namespace."
  }

  validation {
    condition = alltrue([
      for namespace in var.servicebus_namespaces : namespace.premium_messaging_partitions == null || contains([1, 2, 4], namespace.premium_messaging_partitions)
    ])
    error_message = "premium_messaging_partitions (Premium only) must be 1, 2 or 4 — set at namespace creation and unchangeable afterwards; with 1 the namespace carries no partitioned entities."
  }

  validation {
    condition = alltrue([
      for namespace in var.servicebus_namespaces : namespace.customer_managed_key == null || (namespace.identity != null && can(regex("UserAssigned", namespace.identity.type)) && length(trimspace(namespace.customer_managed_key.identity_id)) > 0)
    ])
    error_message = "customer_managed_key requires an identity block whose type contains \"UserAssigned\" (the Key Vault access identity is the one named in the resource's identity_ids) and a non-empty identity_id pointing at that user-assigned identity — once a customer-managed key is enabled it cannot be disabled, only swapped for another key."
  }

  validation {
    condition = alltrue([
      for namespace in var.servicebus_namespaces : namespace.network_rule_set == null || namespace.sku != "Basic"
    ])
    error_message = "network_rule_set requires Standard or Premium — virtual-network rules are Premium-only and IP firewall rules do not exist on Basic namespaces."
  }

  validation {
    condition = alltrue([
      for namespace in var.servicebus_namespaces : namespace.network_rule_set == null || (
        namespace.network_rule_set.default_action == "Deny"
        && (length(namespace.network_rule_set.ip_rules) > 0 || length(namespace.network_rule_set.network_rules) > 0)
      )
    ])
    error_message = "network_rule_set, when set, must use default_action = \"Deny\" and carry at least one rule source (ip_rules or network_rules) — an Allow-everything ruleset is meaningless; omitting the block (or clearing it) is the way to permit all traffic."
  }

  validation {
    condition = alltrue([
      for namespace in var.servicebus_namespaces : contains(["1.2", "1.3"], namespace.minimum_tls_version)
    ])
    error_message = "minimum_tls_version must be \"1.2\" or \"1.3\" — TLS 1.0 and 1.1 no longer exist on Service Bus; Azure retired them in August 2025."
  }

  validation {
    condition = alltrue(flatten([
      for namespace_key, namespace in var.servicebus_namespaces : concat(
        [
          for queue_key, queue in namespace.queues :
          length(queue.name) >= 1 && length(queue.name) <= 260 && length(trimspace(queue.name)) > 0
        ],
        [
          for topic_key, topic in namespace.topics :
          length(topic.name) >= 1 && length(topic.name) <= 260 && length(trimspace(topic.name)) > 0
        ],
        [
          flatten([
            for topic_key, topic in namespace.topics :
            [
              for subscription_key, subscription in topic.subscriptions :
              length(subscription.name) >= 1 && length(subscription.name) <= 50 && length(trimspace(subscription.name)) > 0
            ]
          ])
        ]
      )
    ]))
    error_message = "queue and topic names must be 1–260 characters, subscription names 1–50 characters, and none may be blank — Azure's entity-name limits."
  }

  validation {
    condition = alltrue(flatten([
      for namespace_key, namespace in var.servicebus_namespaces : concat(
        flatten([
          for queue_key, queue in namespace.queues : [
            for other_queue_key, other_queue in namespace.queues :
            queue_key == other_queue_key || lower(queue.name) != lower(other_queue.name)
          ]
        ]),
        flatten([
          for topic_key, topic in namespace.topics : [
            for other_topic_key, other_topic in namespace.topics :
            topic_key == other_topic_key || lower(topic.name) != lower(other_topic.name)
          ]
        ]),
        flatten([
          for topic_key, topic in namespace.topics : [
            for subscription_key, subscription in topic.subscriptions : [
              for other_subscription_key, other_subscription in topic.subscriptions :
              subscription_key == other_subscription_key || lower(subscription.name) != lower(other_subscription.name)
            ]
          ]
        ])
      )
    ]))
    error_message = "queue names must be unique within their namespace, topic names unique within their namespace and subscription names unique within their topic — all case-insensitively, since Azure treats Service Bus entity names case-insensitively."
  }

  validation {
    condition = alltrue(concat(
      flatten([
        for namespace_key, namespace in var.servicebus_namespaces : [
          for queue_key, queue in namespace.queues : queue.max_delivery_count >= 1
        ]
      ]),
      flatten([
        for namespace_key, namespace in var.servicebus_namespaces : [
          for topic_key, topic in namespace.topics : [
            for subscription_key, subscription in topic.subscriptions : subscription.max_delivery_count >= 1
          ]
        ]
      ])
    ))
    error_message = "max_delivery_count must be at least 1 — after this many failed deliveries a message is automatically dead-lettered (`1` means every undeliverable count dead-letters immediately; the queue-level default is 10)."
  }

  validation {
    condition = alltrue(flatten(concat([
      for namespace_key, namespace in var.servicebus_namespaces : [
        for queue_key, queue in namespace.queues :
        namespace.sku == "Premium" ? queue.express_enabled != true : true
      ]
      ], [
      for namespace_key, namespace in var.servicebus_namespaces : [
        for topic_key, topic in namespace.topics :
        namespace.sku == "Premium" ? topic.express_enabled != true : true
      ]
    ])))
    error_message = "express_enabled must not be set true inside Premium namespaces — Premium Messaging does not support Express Entities, and the provider documents the flag as failing outright there; leave it unset (null) to keep the Basic/Standard default behaviour."
  }

  validation {
    condition = alltrue(flatten(concat([
      for namespace_key, namespace in var.servicebus_namespaces : [
        for queue_key, queue in namespace.queues : contains(["Active", "Disabled", "SendDisabled", "ReceiveDisabled"], queue.status)
      ]
      ], [
      for namespace_key, namespace in var.servicebus_namespaces : [
        for topic_key, topic in namespace.topics : contains(["Active", "Disabled"], topic.status)
      ]
      ], [
      for namespace_key, namespace in var.servicebus_namespaces : [
        for topic_key, topic in namespace.topics : [
          for subscription_key, subscription in topic.subscriptions : contains(["Active", "Disabled", "ReceiveDisabled"], subscription.status)
        ]
      ]
    ])))
    error_message = "status is scoped per entity type: queues accept Active, Disabled, SendDisabled or ReceiveDisabled; topics only Active or Disabled; subscriptions only Active, Disabled or ReceiveDisabled (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten(concat(
      [for namespace_key in keys(var.servicebus_namespaces) : !can(regex("\\.", namespace_key))],
      flatten([
        for namespace_key, namespace in var.servicebus_namespaces : concat(
          [for queue_key in keys(namespace.queues) : !can(regex("\\.", queue_key))],
          [for queue_key, queue in namespace.queues : [for rule_key in keys(queue.authorization_rules) : !can(regex("\\.", rule_key))]],
          [for topic_key in keys(namespace.topics) : !can(regex("\\.", topic_key))],
          [for topic_key, topic in namespace.topics : [for rule_key in keys(topic.authorization_rules) : !can(regex("\\.", rule_key))]],
          flatten([
            for topic_key, topic in namespace.topics : [
              for subscription_key, subscription in topic.subscriptions : [
                for rule_key in keys(subscription.rules) : !can(regex("\\.", rule_key))
              ]
            ]
          ]),
          [for rule_key in keys(namespace.authorization_rules) : !can(regex("\\.", rule_key))]
        )
      ])
    )))
    error_message = "map keys of servicebus_namespaces and its nested queues, topics, subscriptions, rules and authorization_rules maps must not contain \".\" — namespace keys are composed into child identifiers of the form \"<namespace_key>.<queue_key>\", down to four-level \"<namespace>.<topic>.<subscription>.<rule>\" keys; dots would make outputs ambiguous and composite keys collision-prone."
  }

  validation {
    condition = alltrue(flatten(concat(
      [for namespace_key, namespace in var.servicebus_namespaces : [
        length(distinct([for rule_key, rule in namespace.authorization_rules : lower(rule.name)])) == length(namespace.authorization_rules)
        ]
        ], flatten([
          for namespace_key, namespace in var.servicebus_namespaces : [
            for queue_key, queue in namespace.queues : length(distinct([for rule_key, rule in queue.authorization_rules : lower(rule.name)])) == length(queue.authorization_rules)
          ]
          ]), flatten([
          for namespace_key, namespace in var.servicebus_namespaces : [
            for topic_key, topic in namespace.topics : length(distinct([for rule_key, rule in topic.authorization_rules : lower(rule.name)])) == length(topic.authorization_rules)
          ]
          ]), flatten([
          for namespace_key, namespace in var.servicebus_namespaces : [
            for queue_key, queue in namespace.queues : [
              for rule_key, rule in queue.authorization_rules : anytrue([rule.listen, rule.send, rule.manage])
            ]
          ]
          ]), flatten([
          for namespace_key, namespace in var.servicebus_namespaces : [
            for topic_key, topic in namespace.topics : [
              for rule_key, rule in topic.authorization_rules : anytrue([rule.listen, rule.send, rule.manage])
            ]
          ]
    ]))))
    error_message = "authorization rule names must be unique within their scope, case-insensitively, and each rule must grant at least one of listen, send or manage — an all-empty rule would trade root-level SAS rights for nothing."
  }

  validation {
    condition = alltrue([
      for namespace_key, namespace in var.servicebus_namespaces :
      length(namespace.tags) <= 50 && alltrue([for tag_key, tag_value in namespace.tags : length(tag_key) <= 512 && length(tag_value) <= 256])
    ])
    error_message = "tags are limited to 50 entries, keys to 512 characters and values to 256 characters (provider-enforced limits) — checked on the namespace, and children inherit their namespace's tags."
  }

  validation {
    condition = alltrue(flatten([
      for namespace_key, namespace in var.servicebus_namespaces : concat(
        flatten([
          for queue_key, queue in namespace.queues : [
            queue.forward_to == null || length(trimspace(queue.forward_to)) > 0,
            queue.forward_dead_lettered_messages_to == null || length(trimspace(queue.forward_dead_lettered_messages_to)) > 0
          ]
        ]),
        flatten([
          for topic_key, topic in namespace.topics : [
            for subscription_key, subscription in topic.subscriptions : [
              subscription.forward_to == null || length(trimspace(subscription.forward_to)) > 0,
              subscription.forward_dead_lettered_messages_to == null || length(trimspace(subscription.forward_dead_lettered_messages_to)) > 0
            ]
          ]
        ])
      )
    ]))
    error_message = "forward_to and forward_dead_lettered_messages_to, when set, must be non-empty names of sibling entities in the same namespace — the target's existence cannot be checked at plan time (it may live outside this module), so a typo or a target removed in the same run surfaces at apply; see Notes."
  }

  validation {
    condition = alltrue(flatten(concat([
      for namespace_key, namespace in var.servicebus_namespaces : [
        for queue_key, queue in namespace.queues : [
          for rule_key, rule in queue.authorization_rules : rule.manage == false || (rule.listen && rule.send)
        ]
      ]
      ], [
      for namespace_key, namespace in var.servicebus_namespaces : [
        for rule_key, rule in namespace.authorization_rules : rule.manage == false || (rule.listen && rule.send)
      ]
      ], [
      for namespace_key, namespace in var.servicebus_namespaces : [
        for topic_key, topic in namespace.topics : [
          for rule_key, rule in topic.authorization_rules : rule.manage == false || (rule.listen && rule.send)
        ]
      ]
    ])))
    error_message = "authorization rule manage = true implies both listen = true and send = true — the provider rejects any other combination."
  }

  validation {
    condition = alltrue(flatten([
      for namespace_key, namespace in var.servicebus_namespaces : [
        for topic_key, topic in namespace.topics : [
          for subscription_key, subscription in topic.subscriptions : [
            for rule_key, rule in subscription.rules : contains(["SqlFilter", "CorrelationFilter"], rule.filter_type)
          ]
        ]
      ]
    ]))
    error_message = "rule filter_type must be SqlFilter or CorrelationFilter (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for namespace_key, namespace in var.servicebus_namespaces : [
        for topic_key, topic in namespace.topics : [
          for subscription_key, subscription in topic.subscriptions : [
            for rule_key, rule in subscription.rules :
            (rule.filter_type == "SqlFilter") == (rule.sql_filter != null) && (rule.filter_type == "CorrelationFilter") == (rule.correlation_filter != null)
          ]
        ]
      ]
    ]))
    error_message = "rule filters must match filter_type exactly: SqlFilter requires sql_filter and forbids correlation_filter; CorrelationFilter requires correlation_filter and forbids sql_filter — the provider model carries one filter per rule, never both."
  }

  validation {
    condition = alltrue(flatten([
      for namespace_key, namespace in var.servicebus_namespaces : [
        for topic_key, topic in namespace.topics : [
          for subscription_key, subscription in topic.subscriptions : [
            for rule_key, rule in subscription.rules :
            rule.correlation_filter == null || anytrue([
              rule.correlation_filter.content_type != null,
              rule.correlation_filter.message_id != null,
              rule.correlation_filter.correlation_id != null,
              rule.correlation_filter.subject != null,
              rule.correlation_filter.reply_to != null,
              rule.correlation_filter.reply_to_session_id != null,
              rule.correlation_filter.session_id != null,
              rule.correlation_filter.to != null,
              length(coalesce(rule.correlation_filter.properties, {})) > 0
            ])
          ]
        ]
      ]
    ]))
    error_message = "a correlation_filter must set at least one of its properties — content_type, message_id, correlation_id, subject, reply_to, reply_to_session_id, session_id, to or a non-empty properties map — mirroring the provider note (and Azure's own restriction) that an all-empty correlation filter is a no-op."
  }

  validation {
    condition = alltrue(flatten([
      for namespace_key, namespace in var.servicebus_namespaces : [
        for topic_key, topic in namespace.topics : [
          for subscription_key, subscription in topic.subscriptions : [
            for rule_key, rule in subscription.rules :
            rule.action == null || length(trimspace(rule.action)) > 0
          ]
        ]
      ]
    ]))
    error_message = "rule action, when set, must be a non-empty SQL expression — a blank action is indistinguishable from no action; omit it instead."
  }

  validation {
    condition = alltrue(flatten([
      for namespace_key, namespace in var.servicebus_namespaces : [
        for topic_key, topic in namespace.topics : [
          for subscription_key, subscription in topic.subscriptions : [
            subscription.client_scoped_subscription == null || (subscription.client_scoped_subscription_enabled && length(trimspace(subscription.client_scoped_subscription.client_id)) > 0)
          ]
        ]
      ]
    ]))
    error_message = "a client_scoped_subscription requires client_scoped_subscription_enabled = true and a non-empty client_id — the gate argument is what the provider toggles, the block only carries the JMS client details; client-scoped subscriptions are a JMS-2.0 feature (Premium namespaces, see Notes)."
  }
}
