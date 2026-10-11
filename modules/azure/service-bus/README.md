# azure/service-bus

Map-keyed module for Azure Service Bus namespaces with nested queues, topics,
subscriptions, subscription rules (SQL and correlation filters), and SAS
authorization rules. Each entry creates one `azurerm_servicebus_namespace` in
the named resource group; namespace names are unique across all of Azure —
they are the host of the namespace's endpoint
(`<name>.servicebus.windows.net`). Child resources wire into the namespace
this module creates itself — every nested resource takes its parent ARM ID
directly, and consumers reference composite keys
(`<namespace_key>.<child_key>`, up to four levels for subscription rules).

## Destroy semantics (read before using)

- Removing a namespace key destroys the namespace and everything on it —
  queues, topics, subscriptions, rules and authorization rules included.
  The namespace name is the endpoint host: a replacement means new endpoints,
  new connection strings for everything.
- Removing a queue, topic, subscription, rule or authorization-rule entry
  deletes it. Removing a topic destroys its subscriptions and their rules
  with it.
- Renaming any entity (namespace, queue, topic, subscription, rule, SAS rule)
  forces replacement of the renamed entity — a queue rename breaks consumers
  holding its connection strings even though the namespace key stays.
- `partitioning_enabled` on queues and topics is immutable — changing it
  forces replacement. `requires_session` on queues and subscriptions is
  immutable — changing it forces replacement.
- Forwarding targets (`forward_to`, `forward_dead_lettered_messages_to`) are
  sibling entity *names*, not IDs. A typo, or removing the target entity in
  the same apply while the forwarder stays, fails at apply on the target.
- Changing `sku` forces namespace replacement.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `servicebus_namespaces` | `map(object)` | — | Map of Service Bus namespaces keyed by an arbitrary unique ID. |

Plan-time validation: `name` is 6–50 characters, letters/digits/hyphens
starting with a letter and ending alphanumeric, unique across entries
case-insensitively; `name`/`resource_group_name`/`location` non-empty; `sku`
in `Basic`/`Standard`/`Premium`; `capacity`, `premium_messaging_partitions`
and `customer_managed_key` only on `Premium` (with `capacity` in
{1,2,4,8,16} and `premium_messaging_partitions` in {1,2,4}, the latter set at
creation only); `customer_managed_key` requires a `UserAssigned` identity and
its `identity_id`; `network_rule_set` requires `Standard`/`Premium`,
`default_action = "Deny"` and at least one rule source; `minimum_tls_version`
is `1.2`/`1.3`; queue/topic names ≤ 260 chars, subscription names ≤ 50,
unique within their parent case-insensitively; `max_delivery_count` ≥ 1;
`express_enabled` disallowed inside Premium namespaces; `status` scoped per
entity type; subscription rules carry exactly one matching filter
(`SqlFilter` + `sql_filter`, or `CorrelationFilter` + `correlation_filter`
with at least one property set inside it) and an optional non-blank `action`
SQL expression; authorization rules unique within scope, granting at least
one of `listen`/`send`/`manage`, with `manage` implying `listen` + `send`;
`forward_to`/`forward_dead_lettered_messages_to` non-empty when set;
`client_scoped_subscription` requires the enabled gate and a non-empty
`client_id`; tags respecting the 50/512/256 limits; and map keys at all four
nesting levels without `.`.

### `servicebus_namespaces` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Namespace name: 6–50 characters, letters/digits/hyphens (validated), the endpoint host and globally unique (module checks only its own entries). Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group the namespace lives in (typically `dependency.rg.outputs.resource_group_names["platform"]` with the `azure/resource-group` module). Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region. Immutable — changing it forces replacement. |
| `sku` | `string` | `Standard` | `Basic` (queues only), `Standard` or `Premium`. Immutable — changing it forces replacement. |
| `capacity` | `number` | `null` | Messaging units reserved for a Premium namespace: 1, 2, 4, 8 or 16 (validated). `null` on Basic/Standard (rejected elsewhere — validated). Updated in place. |
| `premium_messaging_partitions` | `number` | `null` | Premium only: 1, 2 or 4 messaging partitions, set at creation and unchangeable afterwards (validated). `null` leaves the namespace unpartitioned (partitioning applies to Premium namespaces as a whole — see Notes). |
| `public_network_access_enabled` | `bool` | `true` | Public endpoint reachability of the namespace — set `false` together with private endpoints or a network rule set that denies everything but private paths. Updated in place. |
| `local_auth_enabled` | `bool` | `true` | Permit SAS (shared-key, shared-access-signature) authorisation on the namespace. `false` forces Entra-only auth; SAS rules and connection-string outputs become inert — see Notes. |
| `minimum_tls_version` | `string` | `1.2` | Minimum TLS accepted at the endpoint: `1.2` or `1.3` (validated; 1.0/1.1 no longer exist). Updated in place. |
| `identity` | `object` | `null` | Optional managed-identity block — see the object table. Required `UserAssigned` identity when `customer_managed_key` is set (validated). |
| `customer_managed_key` | `object` | `null` | Optional single CMK block (Premium only, validated) — see the object table. Once enabled it cannot be disabled; removing it from the input is not an option on an existing namespace. |
| `network_rule_set` | `object` | `null` | Optional single network-ruleset block (Standard/Premium, validated) — see the object table. Existing entirely null = endpoint open to all networks. |
| `queues` | `map(object)` | `{}` | Queues on the namespace keyed by an arbitrary unique ID — see the object table. |
| `topics` | `map(object)` | `{}` | Topics on the namespace keyed by an arbitrary unique ID — see the object table. |
| `authorization_rules` | `map(object)` | `{}` | Namespace-scoped SAS authorization rules keyed by an arbitrary unique ID — shares the object table of the nested `authorization_rules` maps. |
| `tags` | `map(string)` | `{}` | Tags on the namespace. The tag set is authoritative — see Notes. |

### `identity` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `type` | `string` | — | `SystemAssigned`, `UserAssigned` or `SystemAssigned, UserAssigned` (contains `UserAssigned` when CMK is used — validated). |
| `identity_ids` | `list(string)` | `[]` | Full ARM resource IDs of the user-assigned identities (required for `UserAssigned` types — the provider enforces it; the CMK access identity must be in this list). |

### `customer_managed_key` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `key_vault_key_id` | `string` | — | Full Key Vault key ID (`https://<vault>.vault.azure.net/keys/<key>/<version>` normally resolved via a Key Vault dependency). Consumers rotate keys by swapping the version here. |
| `identity_id` | `string` | — | ARM ID of the user-assigned identity granted Get/Wrap/Unwrap on the key (must be present in `identity.identity_ids` — the containing block only requires the type, see Notes). Immutable — changing it forces replacement of the encryption configuration. |
| `infrastructure_encryption_enabled` | `bool` | `false` | Double encryption at rest (infrastructure layer above the CMK). Immutable — changing it forces replacement, and it can never be turned off on a namespace. |

### `network_rule_set` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `default_action` | `string` | — | `Deny` (case-sensitive; validated) — an `Allow`-everything ruleset is meaningless; omit the block instead. |
| `public_network_access_enabled` | `bool` | `true` | Whether the public network path is reachable at all — mirrors the namespace-level flag inside the ruleset (the provider requires it consistent to actually cut access). |
| `ip_rules` | `set(string)` | `[]` | IPv4 addresses or CIDR blocks allowed through. IP firewall rules work on Standard and Premium. |
| `trusted_services_allowed` | `bool` | `false` | Let known trusted Azure services (Event Grid, Azure Monitor, etc.) bypass the ruleset. Premium-only on the Azure side. |
| `network_rules` | `list(object)` | `[]` | Per-subnet VNet rules — see the object table below. VNet rules are Premium-only on the Azure side. |

### `network_rules` entry (each)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `subnet_id` | `string` | — | Full ARM subnet ID allowed through (typically from `azure/subnet` outputs). The subnet must carry the `Microsoft.ServiceBus` service endpoint, unless `ignore_missing_vnet_service_endpoint` is set. |
| `ignore_missing_vnet_service_endpoint` | `bool` | `false` | Let the namespace bind a subnet without the service endpoint configured (an escape hatch for cross-module ordering; removing it later restores the check). |

### `queues` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Queue name, up to 260 characters (validated). Immutable — changing it forces replacement. |
| `lock_duration` | `string` | `null` | ISO 8601 peek-lock duration (e.g. `PT1M`), max 5 minutes — `null` keeps the namespace's default. |
| `max_size_in_megabytes` | `number` | `null` | Memory allocated for the queue — documented values per SKU in the Notes quota table (Azure enforces; no plan check). Immutable — changing it forces replacement. |
| `max_delivery_count` | `number` | `10` | Delivery attempts before a message dead-letters, ≥ 1 (validated). |
| `default_message_ttl` | `string` | `null` | ISO 8601 default time-to-live for messages (e.g. `P14D`) used when the message omits one. |
| `dead_lettering_on_message_expiration` | `bool` | `false` | Move expired messages to the dead-letter subqueue instead of dropping them. |
| `requires_duplicate_detection` | `bool` | `false` | Deduplicate messages inside the detection window (Basic/Standard and up). Immutable — changing it forces replacement. |
| `duplicate_detection_history_time_window` | `string` | `null` | ISO 8601 dedup window (e.g. `PT10M`), only meaningful with `requires_duplicate_detection`. |
| `requires_session` | `bool` | `false` | Sessionful queue (ordered groups of related messages). Immutable — changing it forces replacement. |
| `batched_operations_enabled` | `bool` | `true` | Allow the service to coalesce server-side operations. |
| `express_enabled` | `bool` | `null` | In-memory express entities (Basic/Standard only; rejected on Premium — validated). `null` keeps the API default. |
| `partitioning_enabled` | `bool` | `false` | Spread the queue over multiple brokers (Standard partitions it 16-fold; see Notes). Immutable — changing it forces replacement. |
| `status` | `string` | `Active` | `Active`, `Disabled`, `SendDisabled` or `ReceiveDisabled` (validated). |
| `forward_to` | `string` | `null` | Name of a sibling queue/topic in the same namespace onto which messages auto-forward (see Destroy semantics). |
| `forward_dead_lettered_messages_to` | `string` | `null` | Name of a sibling entity that dead-lettered messages auto-forward to. |
| `authorization_rules` | `map(object)` | `{}` | Queue-scoped SAS rules keyed by an arbitrary unique ID — see the object table. |

### `topics` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Topic name, up to 260 characters (validated). Immutable — changing it forces replacement. |
| `max_size_in_megabytes` | `number` | `null` | Memory allocated for the topic — same quota table as queues (see Notes). Immutable — changing it forces replacement. |
| `default_message_ttl` | `string` | `null` | ISO 8601 default time-to-live applied when the message omits one. |
| `requires_duplicate_detection` | `bool` | `false` | Deduplicate messages inside the detection window. Immutable — changing it forces replacement. |
| `duplicate_detection_history_time_window` | `string` | `null` | ISO 8601 dedup window (e.g. `PT10M`). |
| `batched_operations_enabled` | `bool` | `true` | Allow server-side batched operations. |
| `express_enabled` | `bool` | `null` | In-memory express entities (Basic/Standard only; rejected on Premium — validated). `null` keeps the API default. |
| `partitioning_enabled` | `bool` | `false` | Spread the topic over multiple brokers. Immutable — changing it forces replacement. |
| `status` | `string` | `Active` | `Active` or `Disabled` (validated). |
| `support_ordering` | `bool` | `false` | Guarantee total ordering when published sequentially in one partition. |
| `authorization_rules` | `map(object)` | `{}` | Topic-scoped SAS rules keyed by an arbitrary unique ID — see the object table. |
| `subscriptions` | `map(object)` | `{}` | Subscriptions on the topic keyed by an arbitrary unique ID — see the object table. |

### `subscriptions` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Subscription name, up to 50 characters (validated). Immutable — changing it forces replacement. |
| `max_delivery_count` | `number` | — | Delivery attempts before a message dead-letters, ≥ 1 (validated; required by the provider). |
| `lock_duration` | `string` | `null` | ISO 8601 peek-lock duration — `null` keeps the API default (`PT1M`). |
| `requires_session` | `bool` | `false` | Sessionful subscription. Immutable — changing it forces replacement. |
| `dead_lettering_on_message_expiration` | `bool` | `false` | Move expired messages to the dead-letter subqueue. |
| `dead_lettering_on_filter_evaluation_error` | `bool` | `true` | Dead-letter messages whose filter/action evaluation throws — the provider default (`true`, mirroring Azure). |
| `batched_operations_enabled` | `bool` | `true` | Allow server-side batched operations. |
| `status` | `string` | `Active` | `Active`, `Disabled` or `ReceiveDisabled` (validated). |
| `forward_to` | `string` | `null` | Name of a sibling entity that messages auto-forward to. |
| `forward_dead_lettered_messages_to` | `string` | `null` | Name of a sibling entity that dead-lettered messages auto-forward to. |
| `client_scoped_subscription_enabled` | `bool` | `false` | Gate for the `client_scoped_subscription` block below (JMS 2.0 only — see Notes). Enforced by validation: set the block only with this on. |
| `client_scoped_subscription` | `object` | `null` | Optional single block — see the object table. |
| `rules` | `map(object)` | `{}` | Subscription rules keyed by an arbitrary unique ID — see the object table. |

### `client_scoped_subscription` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `client_id` | `string` | — | JMS client ID the subscription is scoped to (non-empty — validated). Changing it forces replacement of the block. |
| `is_client_scoped_subscription_shareable` | `bool` | `true` | Whether multiple JMS sessions may share the subscription (the provider default). Changing it forces replacement. |

`is_client_scoped_subscription_durable` is a read-only provider attribute —
durability is decided on the JMS application side, so there is no input for
it (`is_client_scoped_subscription_shareable` mirrors the provider's
`true` default).

### `rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Rule name. Immutable — changing it forces replacement. |
| `filter_type` | `string` | — | `SqlFilter` or `CorrelationFilter` (case-sensitive, validated); one filter per rule, matching the type (validated). |
| `sql_filter` | `string` | `null` | SQL language filter expression (e.g. `colour = 'red'`) — required exactly when `filter_type` is `SqlFilter` (validated). |
| `correlation_filter` | `object` | `null` | Correlation filter — required exactly when `filter_type` is `CorrelationFilter` (validated), and must set at least one property (validated) — see the object table. |
| `action` | `string` | `null` | Optional SQL expression run when the filter matches (e.g. `SET sys.label = 'priority'`) — plain string argument, non-blank when set (validated). |

### `rules.correlation_filter` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `content_type` | `string` | `null` | Match messages with this content type. |
| `message_id` | `string` | `null` | Match messages with this message ID. |
| `correlation_id` | `string` | `null` | Match messages with this correlation ID. |
| `subject` | `string` | `null` | Match messages with this label — the module input keeps the portal's term (`subject`); it maps onto the provider's `label` argument. |
| `reply_to` | `string` | `null` | Match messages with this reply-to address. |
| `reply_to_session_id` | `string` | `null` | Match messages with this reply-to session ID. |
| `session_id` | `string` | `null` | Match messages with this session ID. |
| `to` | `string` | `null` | Match messages addressed to this destination. |
| `properties` | `map(string)` | `null` | Application property name/value pairs matched against the message. |

At least one of the above must be set for the rule to be valid (validated);
an all-empty correlation filter would match nothing meaningful.

### `authorization_rules` object

Shared by the namespace-level `authorization_rules` and the nested
queue/topic maps.

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | SAS rule name, unique within its scope, case-insensitively (validated). Immutable — changing it forces replacement (and, because the rule holds the keys clients use, a rename invalidates every connection string issued from it). |
| `listen` | `bool` | `false` | Grant listen (receive/read) rights. |
| `send` | `bool` | `false` | Grant send (write) rights. |
| `manage` | `bool` | `false` | Grant manage rights — implies `listen` and `send`, which must be set alongside it (validated). |

The provider also carries inline `authorization_rules` blocks on queue/topic
resources; this module does not use them — all SAS rules are the dedicated
per-scope resources above. Keep them separate on the consumer side too: the
two mechanisms fight over the same rights list and produce spurious diffs.

## Outputs

| Name | Description |
|---|---|
| `namespace_ids` | Map of key => full ARM resource ID (`/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.ServiceBus/namespaces/<name>`). |
| `namespace_names` | Map of key => namespace name — the endpoint host. |
| `namespace_endpoints` | Map of key => the namespace's endpoint URL (`https://<name>.servicebus.windows.net:443/`) — the host connection strings target. |
| `namespace_skus` | Map of key => SKU tier (`Basic`/`Standard`/`Premium`) — lets sibling consumers branch on the tier. |
| `queue_ids` | Map of `<namespace_key>.<queue_key>` => queue ARM ID. |
| `topic_ids` | Map of `<namespace_key>.<topic_key>` => topic ARM ID. |
| `subscription_ids` | Map of `<namespace_key>.<topic_key>.<subscription_key>` => subscription ARM ID. |
| `subscription_rule_ids` | Map of `<namespace_key>.<topic_key>.<subscription_key>.<rule_key>` => rule ARM ID. |
| `namespace_authorization_rule_ids` | Map of `<namespace_key>.<rule_key>` => SAS rule ARM ID. |
| `queue_authorization_rule_ids` | Map of `<namespace_key>.<queue_key>.<rule_key>` => SAS rule ARM ID. |
| `topic_authorization_rule_ids` | Map of `<namespace_key>.<topic_key>.<rule_key>` => SAS rule ARM ID. |
| `namespace_authorization_rule_keys` | Map of `<namespace_key>.<rule_key>` => `{ primary_key, secondary_key, primary_connection_string, secondary_connection_string }`. Sensitive — see Notes. |
| `queue_authorization_rule_keys` | Map of `<namespace_key>.<queue_key>.<rule_key>` => `{ primary_key, secondary_key, primary_connection_string, secondary_connection_string }`. Sensitive — see Notes. |
| `topic_authorization_rule_keys` | Map of `<namespace_key>.<topic_key>.<rule_key>` => `{ primary_key, secondary_key, primary_connection_string, secondary_connection_string }`. Sensitive — see Notes. |
| `namespace_default_keys` | Map of key => `{ primary_connection_string, secondary_connection_string }` from the namespace's automatically created `RootManageSharedAccessKey` rule (full manage rights to the whole namespace). Sensitive — see Notes. |

The three `*_authorization_rule_keys` outputs are kept as separate maps, not
one merged dictionary, so a namespace key and a queue key with the same
string can never collide.

## Example

```hcl
servicebus_namespaces = {
  "orders-premium" = {
    name                = "sbus-orders-prod-01"
    resource_group_name = "rg-messaging-prod"
    location            = "westeurope"
    sku                 = "Premium"
    capacity            = 4
    identity = {
      type = "UserAssigned"
      identity_ids = [
        "/subscriptions/12345678-1234-5678-9012-123456789012/resourceGroups/rg-identity-prod/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-sbus-cmk"
      ]
    }
    customer_managed_key = {
      key_vault_key_id  = "https://kv-crypto-prod.vault.azure.net/keys/sbus/58c0f123456789012345678901234567"
      identity_id       = "/subscriptions/12345678-1234-5678-9012-123456789012/resourceGroups/rg-identity-prod/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-sbus-cmk"
    }
    network_rule_set = {
      default_action           = "Deny"
      ip_rules                 = ["203.0.113.0/24"]
      trusted_services_allowed = true
      network_rules = [
        {
          subnet_id = "/subscriptions/12345678-1234-5678-9012-123456789012/resourceGroups/rg-net-prod/providers/Microsoft.Network/virtualNetworks/vnet-orders/subnets/snet-messaging"
        }
      ]
    }
    queues = {
      "settlements" = {
        name                 = "orders-settlements"
        partitioning_enabled = true
        requires_session     = true
        authorization_rules = {
          "workers" = {
            listen = true
            send   = true
          }
        }
      }
    }
    authorization_rules = {
      "event-grid" = {
        send = true
      }
    }
    tags = {
      env = "prod"
    }
  }
  "events-standard" = {
    name                = "sbus-events-prod-01"
    resource_group_name = "rg-messaging-prod"
    location            = "westeurope"
    topics = {
      "order-events" = {
        name = "order-events"
        subscriptions = {
          "invoice" = {
            name               = "invoice"
            max_delivery_count = 10
            rules = {
              "sql-high-value" = {
                name       = "high-value"
                filter_type = "SqlFilter"
                sql_filter = "total_price > 1000"
                action     = "SET sys.label = 'high-value'"
              }
              "corr-partner" = {
                name         = "partner-updates"
                filter_type  = "CorrelationFilter"
                correlation_filter = {
                  subject    = "partner-update"
                  properties = {
                    partner = "acme"
                  }
                }
              }
            }
          }
          "sessions" = {
            name                            = "fulfilment"
            max_delivery_count              = 5
            requires_session                = true
            dead_lettering_on_filter_evaluation_error = false
          }
        }
      }
    }
    tags = {
      env = "prod"
    }
  }
}
```

It wires downstream like:

```hcl
dependency "sbus" {
  config_path = "../sbus"

  mock_outputs = {
    queue_authorization_rule_keys = {
      "orders-premium.settlements.workers" = {
        primary_connection_string = "mock"
      }
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "output"]
}
```

a worker consumes `dependency.sbus.outputs.queue_authorization_rule_keys["orders-premium.settlements.workers"].primary_connection_string`.

## Notes

- SKU matrix: `capacity` and `customer_managed_key` are Premium-only;
  `network_rule_set` exists on Standard and Premium (VNet rules and the
  trusted-services bypass are Premium-only on the Azure side); express
  entities are Basic/Standard-only (the module rejects them inside Premium —
  the service does too). Partitioned queues/topics exist on Basic and
  Standard; on Premium, partitioning is managed at namespace level via
  `premium_messaging_partitions` and the per-entity flags are moot.
- `max_size_in_megabytes` — Azure-enforced value sets; no plan check (a
  stricter check would reject configs Azure accepts). Documented values:
  1024/2048/3072/4096/5120 MB on Basic and Standard, plus 40960/81920/102400
  MB on Premium. Partitioned entities multiply the ceiling (16 partitions on
  Standard) — Azure enforces the combinations at apply.
- Durations on `lock_duration`, `*_ttl` and dedup windows are ISO 8601
  (`PT5M`, `P14D`, `P10675199DT2H48M5.4775807S`; the API max for TTL).
- Forwarding: `forward_to`/`forward_dead_lettered_messages_to` are sibling
  entity names inside the same namespace. Cross-namespace forwarding
  (`SendVia`-style) is out of scope. No cross-entry consistency can be
  checked at plan — a removed or misspelled target fails at apply.
- `requires_session` on a subscription (and a queue) is set at creation;
  turning it on or off forces replacement.
- Client-scoped subscriptions are a JMS 2.0 feature — Premium namespaces
  only, meaningful only with JMS client versions that support them; the
  Azure portal/ARM surface for them is thin to nonexistent.
- `dead_lettering_on_filter_evaluation_error` defaults to `true` (the
  provider default, mirroring Azure): filter errors route into
  `$deadletterqueue` instead of being retried forever. The example sets it
  false only to show the knob.
- SAS: the sensitive key/connection-string outputs land in state — anyone
  with state access can read them. Rotate keys in the portal/CLI (the
  module reads the keys; regeneration is not managed here). The built-in
  `RootManageSharedAccessKey` cannot be removed or recreated by this
  module — its connection strings come off the namespace resource.
- RBAC the caller needs: `Microsoft.ServiceBus/namespaces/write` (and
  delete) on the resource group, plus `Microsoft.ServiceBus/namespaces/`
  queue/topic/subscription-level write permissions. Consumers of
  `local_auth_enabled = false` namespaces must use Entra-ID roles
  (Service Bus Data Owner/Receiver) — SAS rules and connection strings
  stop working.
- Zone redundancy on a Premium namespace is managed Azure-side per region
  choice — there is no module input (the 4.x provider attribute was
  removed); call the desired posture out in the consumer's reservation
  instead.
- Not exposed, deliberately (pass-through candidates for a later minor):
  Service Bus geo-DR / disaster-recovery configs (including the
  `*_connection_string_alias` attributes that only exist there), migration
  configs, `auto_delete_on_idle`, `max_message_size_in_kilobytes`
  (Premium large-message preview), and diagnostic settings — everything else
  on the namespace/queue/topic/subscription/rule surface is carryable here.
- `sql_filter_compatibility_level` is a read-only provider attribute of the
  rule resource (reserved by the service, hard-coded to 20) — there is no
  input for it, and none is needed.

## Import

```text
tofu import 'azurerm_servicebus_namespace.namespace["<namespace_key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.ServiceBus/namespaces/<name>"

tofu import 'azurerm_servicebus_queue.queue["<namespace_key>.<queue_key>"]' "<namespace_id>/queues/<name>"

tofu import 'azurerm_servicebus_topic.topic["<namespace_key>.<topic_key>"]' "<namespace_id>/topics/<name>"

tofu import 'azurerm_servicebus_subscription.subscription["<namespace_key>.<topic_key>.<subscription_key>"]' "<topic_id>/subscriptions/<name>"

tofu import 'azurerm_servicebus_subscription_rule.rule["<namespace_key>.<topic_key>.<subscription_key>.<rule_key>"]' "<subscription_id>/rules/<name>"

tofu import 'azurerm_servicebus_namespace_authorization_rule.namespace_rule["<namespace_key>.<rule_key>"]' "<namespace_id>/authorizationRules/<name>"

tofu import 'azurerm_servicebus_queue_authorization_rule.queue_rule["<namespace_key>.<queue_key>.<rule_key>"]' "<queue_id>/authorizationRules/<name>"

tofu import 'azurerm_servicebus_topic_authorization_rule.topic_rule["<namespace_key>.<topic_key>.<rule_key>"]' "<topic_id>/authorizationRules/<name>"
```
