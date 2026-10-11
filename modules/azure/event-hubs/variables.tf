variable "eventhub_namespaces" {
  description = "Map of Azure Event Hubs namespaces keyed by an arbitrary identifier. Each entry creates one azurerm_eventhub_namespace in the named resource group; namespace names are unique across all of Azure. Nested event hubs, consumer groups and SAS authorization rules wire into the namespace resources this module creates itself."
  type = map(object({
    name                          = string
    resource_group_name           = string
    location                      = string
    sku                           = optional(string, "Standard")
    capacity                      = optional(number)
    dedicated_cluster_id          = optional(string)
    public_network_access_enabled = optional(bool, true)
    local_authentication_enabled  = optional(bool, true)
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))
    customer_managed_key = optional(object({
      key_vault_key_ids                 = map(string)
      user_assigned_identity_id         = string
      infrastructure_encryption_enabled = optional(bool, false)
    }))
    network_rulesets = optional(object({
      default_action = string
      ip_rules = optional(list(object({
        ip_mask = string
        action  = optional(string, "Allow")
      })), [])
      virtual_network_rules = optional(list(object({
        subnet_id                                       = string
        ignore_missing_virtual_network_service_endpoint = optional(bool, false)
      })), [])
      trusted_service_access_enabled = optional(bool, false)
    }))
    eventhubs = optional(map(object({
      name              = string
      partition_count   = number
      message_retention = optional(number)
      status            = optional(string, "Active")
      capture_description = optional(object({
        enabled             = bool
        encoding            = string
        interval_in_seconds = optional(number)
        size_limit_in_bytes = optional(number)
        skip_empty_archives = optional(bool, false)
        destination = object({
          archive_name_format         = string
          blob_container_name         = string
          storage_account_id          = string
          storage_authentication_type = optional(string, "StorageSAS")
          storage_authentication_id   = optional(string)
        })
      }))
      consumer_groups = optional(map(object({
        name          = string
        user_metadata = optional(string)
      })), {})
      authorization_rules = optional(map(object({
        name   = string
        listen = optional(bool, false)
        send   = optional(bool, false)
        manage = optional(bool, false)
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
      for ns in var.eventhub_namespaces : can(regex("^[a-zA-Z][a-zA-Z0-9-]{4,48}[a-zA-Z0-9]$", ns.name))
    ])
    error_message = "name must be 6–50 characters — starting with a letter, alphanumerics and hyphens inside, ending alphanumeric; the name is the DNS label behind the namespace's endpoint (<name>.servicebus.windows.net) and must be unique across all of Azure, which the module cannot check: a claimed name fails at apply."
  }

  validation {
    condition = alltrue(flatten([
      for key, ns in var.eventhub_namespaces : [
        for other_key, other in var.eventhub_namespaces :
        key == other_key || lower(ns.name) != lower(other.name)
      ]
    ]))
    error_message = "namespace names must be unique across entries, case-insensitively — Azure treats the namespace name case-insensitively, so two entries with the same name collide at the Azure API."
  }

  validation {
    condition = alltrue([
      for ns in var.eventhub_namespaces : length(trimspace(ns.name)) > 0 && length(trimspace(ns.resource_group_name)) > 0 && length(trimspace(ns.location)) > 0
    ])
    error_message = "name, resource_group_name and location must not be empty."
  }

  validation {
    condition = alltrue([
      for ns in var.eventhub_namespaces : contains(["Basic", "Standard", "Premium"], ns.sku)
    ])
    error_message = "sku must be one of Basic, Standard or Premium — there is no Dedicated tier on the namespace; a dedicated-cluster namespace is a Standard-SKU namespace wired to a cluster with dedicated_cluster_id (see Notes)."
  }

  validation {
    condition = alltrue([
      for ns in var.eventhub_namespaces : ns.capacity == null || ns.capacity >= 1
    ])
    error_message = "capacity, when set, must be a positive number of throughput units — the provider does not pin the valid range per SKU (Basic tops out at 10, Standard at 20, Premium follows the purchased cluster), so Azure enforces the range at apply and the README documents the typical values."
  }

  validation {
    condition = alltrue([
      for ns in var.eventhub_namespaces : ns.dedicated_cluster_id == null || can(regex("^/", ns.dedicated_cluster_id))
    ])
    error_message = "dedicated_cluster_id, when set, must be a full ARM resource ID of the dedicated Event Hubs cluster (starting with \"/\") — a pass-through of a Standard-SKU namespace onto a cluster; the cluster itself is out of this module's scope."
  }

  validation {
    condition = alltrue([
      for ns in var.eventhub_namespaces : ns.customer_managed_key == null || (ns.sku == "Premium" && ns.identity != null && can(regex("UserAssigned", ns.identity.type)) && length(ns.identity.identity_ids) > 0)
    ])
    error_message = "customer_managed_key is only valid on the Premium SKU and requires an identity block — type UserAssigned with at least one identity id (CMK on dedicated-cluster namespaces is wired Azure-side, not with this input)."
  }

  validation {
    condition = alltrue([
      for ns in var.eventhub_namespaces : ns.customer_managed_key == null || length(ns.customer_managed_key.key_vault_key_ids) > 0
    ])
    error_message = "customer_managed_key.key_vault_key_ids must contain at least one Key Vault key ID — the provider takes a map of keys for the encryption set."
  }

  validation {
    condition = alltrue([
      for ns in var.eventhub_namespaces : ns.network_rulesets == null || (
        ns.network_rulesets.default_action == "Deny"
        && (length(ns.network_rulesets.ip_rules) > 0 || length(ns.network_rulesets.virtual_network_rules) > 0)
      )
    ])
    error_message = "network_rulesets, when set, requires default_action = \"Deny\" and at least one ip_rule or virtual_network_rule — the provider rejects an Allow default here; leaving the block unset is the way to permit all traffic."
  }

  validation {
    condition = alltrue(flatten([
      for ns in var.eventhub_namespaces : [
        for hub in ns.eventhubs : length(hub.name) >= 1 && length(hub.name) <= 256
      ]
    ]))
    error_message = "event hub names must be 1–256 characters."
  }

  validation {
    condition = alltrue(flatten([
      for key, ns in var.eventhub_namespaces : [
        for hk, hub in ns.eventhubs : [
          for other_hk, other in ns.eventhubs :
          hk == other_hk || lower(hub.name) != lower(other.name)
        ]
      ]
    ]))
    error_message = "event hub names must be unique within their namespace, case-insensitively — Azure treats entity names case-insensitively, so two entries with the same name collide at the Azure API."
  }

  validation {
    condition = alltrue(flatten([
      for ns in var.eventhub_namespaces : [
        for hub in ns.eventhubs : ns.dedicated_cluster_id != null || (hub.partition_count >= 1 && hub.partition_count <= 32)
      ]
    ]))
    error_message = "partition_count must be between 1 and 32 on shared namespaces — the shared-namespace limit; namespaces on dedicated clusters (dedicated_cluster_id set) allow far more (up to 1024 per hub), which the module deliberately does not validate so dedicated configs stay valid. The count is immutable on Basic/Standard and can only increase on Premium/dedicated clusters — see Notes."
  }

  validation {
    condition = alltrue(flatten([
      for ns in var.eventhub_namespaces : [
        for hub in ns.eventhubs : hub.status == null || contains(["Active", "Disabled"], hub.status)
      ]
    ]))
    error_message = "status must be Active or Disabled — the two values the event hub resource supports (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for ns in var.eventhub_namespaces : [
        for hub in ns.eventhubs : ns.dedicated_cluster_id != null || hub.message_retention == null || (ns.sku == "Basic" ? hub.message_retention == 1 : hub.message_retention >= 1 && hub.message_retention <= 7)
      ]
    ]))
    error_message = "message_retention is validated against the owning namespace's sku on shared namespaces: exactly 1 day on Basic, 1–7 days on Standard and Premium — dedicated-cluster namespaces (dedicated_cluster_id set) allow much longer windows and are exempt from the check. Extended retention (up to 90 days via retention_description) is out of this module's scope — see Notes."
  }

  validation {
    condition = alltrue(flatten([
      for ns in var.eventhub_namespaces : [
        for hub in ns.eventhubs : hub.capture_description == null || contains(["Avro", "AvroDeflate"], hub.capture_description.encoding)
      ]
    ]))
    error_message = "capture_description.encoding must be Avro or AvroDeflate — the only encodings the capture pipeline accepts; AvroDeflate is legacy compression, prefer Avro (see Notes)."
  }

  validation {
    condition = alltrue(flatten([
      for ns in var.eventhub_namespaces : [
        for hub in ns.eventhubs : hub.capture_description == null || hub.capture_description.interval_in_seconds == null || (hub.capture_description.interval_in_seconds >= 60 && hub.capture_description.interval_in_seconds <= 900)
      ]
    ]))
    error_message = "capture_description.interval_in_seconds, when set, must be between 60 and 900 — the capture window the service captures at (or earlier when the size limit hits)."
  }

  validation {
    condition = alltrue(flatten([
      for ns in var.eventhub_namespaces : [
        for hub in ns.eventhubs : hub.capture_description == null || hub.capture_description.size_limit_in_bytes == null || (hub.capture_description.size_limit_in_bytes >= 10485760 && hub.capture_description.size_limit_in_bytes <= 524288000)
      ]
    ]))
    error_message = "capture_description.size_limit_in_bytes, when set, must be between 10485760 and 524288000 — the first of the two capture triggers to hit (window or size) flushes the archive."
  }

  validation {
    condition = alltrue(flatten([
      for ns in var.eventhub_namespaces : [
        for hub in ns.eventhubs : hub.capture_description == null || (
          length(trimspace(hub.capture_description.destination.archive_name_format)) > 0
          && length(trimspace(hub.capture_description.destination.blob_container_name)) > 0
          && can(regex("^/", hub.capture_description.destination.storage_account_id))
        )
      ]
    ]))
    error_message = "capture_description.destination requires archive_name_format, blob_container_name and a full ARM storage account ID (starting with \"/\" for storage_account_id) — the destination is a reference to an existing storage account + blob container, which this module does not create (wire from azure/storage-account outputs; the container must already exist — see Notes)."
  }

  validation {
    condition = alltrue(flatten([
      for ns in var.eventhub_namespaces : [
        for hub in ns.eventhubs : hub.capture_description == null || hub.capture_description.destination == null || contains(["StorageSAS", "SystemAssigned", "UserAssigned"], hub.capture_description.destination.storage_authentication_type)
      ]
    ]))
    error_message = "capture_description.destination.storage_authentication_type must be StorageSAS, SystemAssigned or UserAssigned — how capture authenticates against the destination storage account."
  }

  validation {
    condition = alltrue(flatten([
      for ns in var.eventhub_namespaces : [
        for hub in ns.eventhubs : hub.capture_description == null || (hub.capture_description.destination.storage_authentication_type != "UserAssigned" || (hub.capture_description.destination.storage_authentication_id != null && length(trimspace(hub.capture_description.destination.storage_authentication_id)) > 0))
      ]
    ]))
    error_message = "capture_description.destination.storage_authentication_id is required when storage_authentication_type is UserAssigned — the user-assigned identity's ID the capture service uses against the storage account."
  }

  validation {
    condition = alltrue(flatten([
      for ns in var.eventhub_namespaces : [
        for hub in ns.eventhubs : [
          for cg in hub.consumer_groups : length(cg.name) >= 1 && length(cg.name) <= 50
        ]
      ]
    ]))
    error_message = "consumer group names must be 1–50 characters."
  }

  validation {
    condition = alltrue(flatten([
      for key, ns in var.eventhub_namespaces : [
        for hk, hub in ns.eventhubs : [
          for cgk, cg in hub.consumer_groups : [
            for other_cgk, other in hub.consumer_groups :
            cgk == other_cgk || lower(cg.name) != lower(other.name)
          ]
        ]
      ]
    ]))
    error_message = "consumer group names must be unique within their event hub, case-insensitively — Azure treats entity names case-insensitively, so two entries with the same name collide at the Azure API. There is no count check: the consumer-group quota is SKU-dependent and Azure enforces it at apply."
  }

  validation {
    condition = alltrue(concat(
      flatten([
        for ns in var.eventhub_namespaces : [
          for rule in ns.authorization_rules : rule.listen || rule.send || rule.manage
        ]
      ]),
      flatten([
        for ns in var.eventhub_namespaces : [
          for hub in ns.eventhubs : [
            for rule in hub.authorization_rules : rule.listen || rule.send || rule.manage
          ]
        ]
      ])
    ))
    error_message = "authorization rules need at least one of listen, send or manage true — a rule with no claims is rejected by the Azure API and gets nobody anywhere."
  }

  validation {
    condition = alltrue(concat(
      flatten([
        for key, ns in var.eventhub_namespaces : [
          for rk, rule in ns.authorization_rules : [
            for other_rk, other in ns.authorization_rules :
            rk == other_rk || lower(rule.name) != lower(other.name)
          ]
        ]
      ]),
      flatten([
        for ns in var.eventhub_namespaces : [
          for hub in ns.eventhubs : [
            for rk, rule in hub.authorization_rules : [
              for other_rk, other in hub.authorization_rules :
              rk == other_rk || lower(rule.name) != lower(other.name)
            ]
          ]
        ]
      ])
    ))
    error_message = "authorization rule names must be unique within their scope — namespace-scoped rules among themselves and hub-scoped rules among their hub, case-insensitively."
  }

  validation {
    condition = alltrue(concat(
      [for ns_key in keys(var.eventhub_namespaces) : !can(regex("\\.", ns_key))],
      flatten([
        for ns in var.eventhub_namespaces : concat(
          [for hub_key in keys(ns.eventhubs) : !can(regex("\\.", hub_key))],
          flatten([
            for hub in ns.eventhubs : concat(
              [for cg_key in keys(hub.consumer_groups) : !can(regex("\\.", cg_key))],
              [for rule_key in keys(hub.authorization_rules) : !can(regex("\\.", rule_key))]
            )
          ]),
          [for rule_key in keys(ns.authorization_rules) : !can(regex("\\.", rule_key))]
        )
      ])
    ))
    error_message = "map keys of eventhub_namespaces and its nested eventhubs, consumer_groups and authorization_rules maps must not contain \".\" — keys are composed into identifiers of the form \"<namespace_key>.<hub_key>.<child_key>\"; dots would make outputs ambiguous and composite keys collision-prone."
  }

  validation {
    condition = alltrue([
      for ns in var.eventhub_namespaces :
      length(ns.tags) <= 50 && alltrue([for tag_key, tag_value in ns.tags : length(tag_key) <= 512 && length(tag_value) <= 256])
    ])
    error_message = "tags are limited to 50 entries, keys to 512 characters and values to 256 characters (provider-enforced limits) — checked on the namespace."
  }
}
