# azure/event-hubs

Map-keyed module for Azure Event Hubs namespaces with nested event hubs,
consumer groups, capture-to-storage and SAS authorization rules. Each entry
creates one `azurerm_eventhub_namespace` in the named resource group;
namespace names are unique across all of Azure — they are the DNS label
behind the namespace's endpoint (`<name>.servicebus.windows.net`). Child
resources wire into the namespace resources this module creates itself — no
namespace-ID plumbing on the consumer side.

## Destroy semantics (read before using)

- Removing a namespace key destroys the namespace and everything on it —
  event hubs, consumer groups and authorization rules included. Keep
  `prevent_destroy` in mind for anything holding stream data.
- Removing an event-hub, consumer-group or authorization-rule entry deletes
  that resource. Deleting a hub cascades to its consumer groups and rules
  (they are name-wired on the API side).
- Renaming a namespace or hub (changing `name`) replaces it and cascades to
  all of its children — the composite
  `<namespace_key>.<hub_key>.<child_key>` addresses survive, the names
  underneath do not.
- `partition_count` is fixed on Basic/Standard namespaces (a change forces
  replacement) and can only increase on Premium and dedicated-cluster
  namespaces (a decrease fails at apply).
- The capture destination is a reference to an existing storage account and
  blob container — the module never creates or deletes either. Removing it
  from a hub stops capture; the archived blobs stay where they are.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `eventhub_namespaces` | `map(object)` | — | Map of Event Hubs namespaces keyed by an arbitrary unique ID. |

Plan-time validation: `name` is 6–50 characters, starting with a letter,
alphanumerics/hyphens inside, ending alphanumeric, and unique across entries
case-insensitively; `name`/`resource_group_name`/`location` non-empty; `sku`
in `Basic`/`Standard`/`Premium`; `capacity` positive when set;
`dedicated_cluster_id` a full ARM ID; `customer_managed_key` Premium-only
with a UserAssigned identity; `network_rulesets` (when set) requires
`default_action = "Deny"` and at least one rule source (the provider rejects
an `Allow` default); hub names 1–256 characters, unique within their
namespace case-insensitively; `partition_count` 1–32; `message_retention`
validated against the owning namespace's SKU (1 on Basic, 1–7 otherwise);
`capture_description` encoding/window/size ranges and its destination's ARM
IDs with `storage_authentication_id` required for `UserAssigned`;
consumer-group names 1–50 characters, unique within their hub;
authorization rules with at least one of `listen`/`send`/`manage` and
unique within scope; tags respecting the 50-entry / 512-char key /
256-char value limits; and map keys on every level without `.`.

### `eventhub_namespaces` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Namespace name: 6–50 characters (validated), the DNS label of `<name>.servicebus.windows.net`. Globally unique across all of Azure (module checks uniqueness among its own entries only — see Notes). Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group the namespace lives in (typically `dependency.rg.outputs.resource_group_names["platform"]` with the `azure/resource-group` module). Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region. Immutable — changing it forces replacement. |
| `sku` | `string` | `Standard` | `Basic`, `Standard` or `Premium` (case-sensitive) — there is no `Dedicated` enum; see Notes. Immutable — SKU changes are Azure-side replacements. |
| `capacity` | `number` | `null` | Throughput units for `Basic`/`Standard` (1–10 basic, 1–20 standard); the provider docs do not document a `Premium` meaning for it. `null` leaves the provider default (1) in place. The module validates positivity only — Azure enforces the SKU range at apply. |
| `dedicated_cluster_id` | `string` | `null` | Full ARM resource ID of a dedicated Event Hubs cluster (validated); pairs with the `Standard` SKU — see Notes. Immutable once attached. |
| `public_network_access_enabled` | `bool` | `true` | Public endpoint reachability of the namespace. Set `false` together with private endpoints (out of this module's scope). Updated in place. |
| `local_authentication_enabled` | `bool` | `true` | Permit SAS/shared-key auth. `false` forces Entra-only access — see Notes for what stops working. Updated in place. |
| `identity` | `object` | `null` | Optional single managed-identity block — see the object table. Required (with `UserAssigned` type) for CMK. |
| `customer_managed_key` | `object` | `null` | Optional customer-managed encryption for `Premium` namespaces — see the object table. |
| `network_rulesets` | `object` | `null` | Optional single network-rulesets block (provider shape). `null` means no ruleset is managed here — the namespace's default is Allow-everything. Updated in place. See the object table below. |
| `eventhubs` | `map(object)` | `{}` | Event hubs on the namespace keyed by an arbitrary unique ID — see the object table. |
| `authorization_rules` | `map(object)` | `{}` | Namespace-scoped SAS authorization rules keyed by an arbitrary unique ID — see the object table. |
| `tags` | `map(string)` | `{}` | Tags on the namespace. The tag set is authoritative — see Notes. |

### `identity` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `type` | `string` | — | `SystemAssigned`, `UserAssigned` or `SystemAssigned, UserAssigned`. `UserAssigned` is required with `customer_managed_key` (validated). |
| `identity_ids` | `list(string)` | `[]` | Full ARM resource IDs of the user-assigned identities. |

### `customer_managed_key` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `key_vault_key_ids` | `map(string)` | — | Map of Key Vault key IDs backing the encryption set (at least one entry, validated). The identity must have Key Vault access — consumer-side RBAC. |
| `user_assigned_identity_id` | `string` | — | Full ARM resource ID of the user-assigned identity the namespace uses for Key Vault access. |
| `infrastructure_encryption_enabled` | `bool` | `false` | Double encryption at rest (platform layer above CMK). Enabled once, it cannot be turned off later. |

### `network_rulesets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `default_action` | `string` | — | `Deny` (case-sensitive; validated — the provider rejects rulesets with an `Allow` default; leaving the block `null` is the way to permit all traffic). Updated in place. |
| `ip_rules` | `list(object)` | `[]` | IP entries allowed through — see the object table; at least one of these or `virtual_network_rules` is required (validated). |
| `virtual_network_rules` | `list(object)` | `[]` | Subnet entries allowed through — see the object table. |
| `trusted_service_access_enabled` | `bool` | `false` | Let first-party Azure services (e.g. Event Grid) reach the namespace across the firewall. |

### `network_rulesets.ip_rules[]`

| Attribute | Type | Default | Description |
|---|---|---|---|
| `ip_mask` | `string` | — | IPv4 address or CIDR (e.g. `203.0.113.0/24`). |
| `action` | `string` | `Allow` | `Allow` is the only supported action — kept as an input for shape parity with the API. |

### `network_rulesets.virtual_network_rules[]`

| Attribute | Type | Default | Description |
|---|---|---|---|
| `subnet_id` | `string` | — | Full ARM subnet resource ID allowed through (typically from `azure/subnet`'s outputs). |
| `ignore_missing_virtual_network_service_endpoint` | `bool` | `false` | Skip the check that the subnet carries the `Microsoft.EventHub` service endpoint. |

### `eventhubs` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Hub name: 1–256 characters (validated), unique within its namespace case-insensitively (validated). Immutable — changing it forces replacement. |
| `partition_count` | `number` | — | Partitions, 1–32 on shared namespaces (validated); dedicated clusters allow more — see Notes. Immutable on Basic/Standard, increase-only on Premium/dedicated — see Notes. |
| `message_retention` | `number` | `null` | Retention in days, validated against the owning namespace's SKU: exactly 1 on `Basic`, 1–7 otherwise (validated). `null` leaves the provider default (1). Extended retention is out of this module's scope — see Notes. |
| `status` | `string` | `Active` | `Active` or `Disabled` (case-sensitive, validated). |
| `capture_description` | `object` | `null` | Optional capture-to-storage block — see the object table. |
| `consumer_groups` | `map(object)` | `{}` | Consumer groups on the hub keyed by an arbitrary unique ID — see the object table. |
| `authorization_rules` | `map(object)` | `{}` | Hub-scoped SAS authorization rules keyed by an arbitrary unique ID — see the object table. |

### `capture_description` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `enabled` | `bool` | — | Turn capture on. |
| `encoding` | `string` | — | `Avro` or `AvroDeflate` (case-sensitive, validated) — see Notes on why `Avro` is preferred. |
| `interval_in_seconds` | `number` | `null` | Capture window, 60–900 seconds (provider enforces at apply when unset — the default is 300; validated when set). |
| `size_limit_in_bytes` | `number` | `null` | Container size trigger, 10485760–524288000 (validated when set) — whichever of window or size hits first flushes the archive. The provider default is 314572800. |
| `skip_empty_archives` | `bool` | `false` | Skip writing an archive when the window flushes no data. |
| `destination` | `object` | — | Capture destination — see the object table. |

### `capture_description.destination` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `archive_name_format` | `string` | — | Naming pattern of the written blobs, e.g. `{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}`. |
| `blob_container_name` | `string` | — | Blob container the archives land in — must already exist (see Notes). |
| `storage_account_id` | `string` | — | Full ARM resource ID of the storage account the container lives in (validated). The module does not create it. |
| `storage_authentication_type` | `string` | `StorageSAS` | `StorageSAS`, `SystemAssigned` or `UserAssigned` (validated). With `SystemAssigned`/`UserAssigned` the identity needs `Storage Blob Data Contributor` on the account — consumer-side RBAC. |
| `storage_authentication_id` | `string` | `null` | Full ARM resource ID of a user-assigned identity — required when `storage_authentication_type` is `UserAssigned`, forbidden otherwise (validated). |

### `consumer_groups` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Consumer-group name: 1–50 characters (validated), unique within its hub case-insensitively (validated). Immutable — changing it forces replacement. |
| `user_metadata` | `string` | `null` | Free-form metadata, up to 1024 characters, echoed to `CREATE`/`UPDATE` consumers. |

### `authorization_rules` object (both scopes)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Rule name — unique within its scope, case-insensitively (validated). Immutable — changing it forces replacement. |
| `listen` | `bool` | `false` | Grant listen rights. |
| `send` | `bool` | `false` | Grant send rights. |
| `manage` | `bool` | `false` | Grant manage rights (implies listen/send Azure-side). At least one of the three must be true (validated). |

## Outputs

| Name | Description |
|---|---|
| `namespace_ids` | Map of namespace key => full ARM resource ID. |
| `namespace_names` | Map of namespace key => namespace name — data-plane address is `<name>.servicebus.windows.net` (derived; see Notes). |
| `namespace_skus` | Map of namespace key => SKU (`Basic`, `Standard`, `Premium`). |
| `eventhub_ids` | Map of `<namespace_key>.<hub_key>` => event hub ARM resource ID. |
| `eventhub_partition_counts` | Map of `<namespace_key>.<hub_key>` => partition count — consumers size their maximum reader parallelism to it. |
| `consumer_group_ids` | Map of `<namespace_key>.<hub_key>.<consumer_group_key>` => consumer-group ARM resource ID. |
| `namespace_authorization_rule_ids` | Map of `<namespace_key>.<rule_key>` => namespace-scoped rule ARM resource ID. |
| `eventhub_authorization_rule_ids` | Map of `<namespace_key>.<hub_key>.<rule_key>` => hub-scoped rule ARM resource ID. |
| `namespace_authorization_rule_keys` | Map of `<namespace_key>.<rule_key>` => `{ primary_key = ..., secondary_key = ..., primary_connection_string = ..., secondary_connection_string = ... }`. Sensitive — see Notes. |
| `eventhub_authorization_rule_keys` | Map of `<namespace_key>.<hub_key>.<rule_key>` => the same shape for hub-scoped rules. Sensitive — see Notes. |
| `namespace_default_keys` | Map of namespace key => `{ primary_connection_string = ..., secondary_connection_string = ... }` from the built-in `RootManageSharedAccessKey` (populated when `local_authentication_enabled` is true). Sensitive — see Notes. |

No hostname/endpoint output exists: the namespace resource exports no
endpoint attribute, and the data-plane address is the derived
`<name>.servicebus.windows.net`.

## Example

```hcl
eventhub_namespaces = {
  "telemetry" = {
    name                = "ehn-telemetry-prod-01"
    resource_group_name = "rg-messaging-prod"
    location            = "westeurope"
    sku                 = "Standard"
    capacity            = 4
    local_authentication_enabled = true
    eventhubs = {
      "telemetry" = {
        name              = "telemetry"
        partition_count   = 8
        message_retention = 3
        capture_description = {
          enabled   = true
          encoding  = "Avro"
          interval_in_seconds = 300
          skip_empty_archives = true
          destination = {
            archive_name_format = "{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}"
            blob_container_name = "capture"
            storage_account_id  = dependency.capture.outputs.storage_account_ids["capture"]
          }
        }
        consumer_groups = {
          "analytics" = {
            name = "analytics"
          }
        }
      }
    }
    authorization_rules = {
      "publisher" = {
        send = true
      }
    }
    tags = {
      env = "prod"
    }
  }
}
```

## Notes

- **SKU matrix**: `capacity` carries documented ranges per SKU (1–10 on
  `Basic`, 1–20 on `Standard`) — the provider
  does not pin them, so the module validates positivity and Azure enforces
  the rest at apply. `dedicated_cluster_id` only pairs with the `Standard`
  SKU: a dedicated-cluster namespace is created as a standard-tier namespace
  attached to a cluster — the cluster resource itself is out of scope.
  `customer_managed_key` is `Premium`-only (dedicated-cluster namespaces get
  CMK wired Azure-side, validated accordingly).
- **Retention**: shared namespaces keep 1–7 days (exactly 1 on `Basic`,
  validated); extended retention — up to 90 days and compact mode via the
  `retention_description` attribute — is out of scope (pass-through
  candidate for a later minor release).
- **Partitions**: 1–32 per hub on shared namespaces (validated); dedicated
  clusters allow up to 1024 per hub, deliberately not validated so dedicated
  configs stay valid. The count is immutable on Basic/Standard namespaces
  (a change forces replacement and re-balances the stream) and can only
  increase on Premium/dedicated namespaces — Azure enforces the
  increase-only rule at apply.
- **Capture**: the destination must pre-exist — storage account and blob
  container (created by the `azure/storage-account` module or externally);
  the module only references the account's ARM ID and never creates the
  container. With `storage_authentication_type` `SystemAssigned`/`UserAssigned`,
  the identity needs `Storage Blob Data Contributor` on the account
  (consumer-side RBAC, including Key Vault access wiring under CMK).
  Prefer `Avro`: `AvroDeflate` is compressed legacy and most tooling
  recompresses anyway.
- The destination `name` is fixed to `EventHubArchive.AzureBlockBlob` — the
  only destination name the service accepts for blob-block capture.
- **Consumer-group quota** is SKU-dependent (20 on Basic, 100 on Standard,
  1000 on Premium; dedicated clusters take far more) — Azure enforces it at
  apply, so the module checks names and skips the count.
- **Disabling SAS** (`local_authentication_enabled = false`) forces
  Entra-only access: every consumer must come with an Entra identity, and
  the default root keys stop working (`namespace_default_keys` becomes
  meaningless). Re-pair authorization-rule keys with Entra-only tooling
  before flipping it off; re-enabling later is a plain in-place update.
- The caller needs `Microsoft.EventHub/namespaces/write` (and delete) on the
  resource group, plus wiring rights for children (eventhubs, consumerGroups,
  authorizationRules) and Key Vault `get` for the CMK identity.
- Region availability of Cluster SKUs and CMK support is checked by ARM at
  apply, not here.
- Placement follows the provider: no subscription argument — everything
  lands in the subscription configured on the provider block (required by
  azurerm since 4.0 — set `subscription_id` or `ARM_SUBSCRIPTION_ID`).
- **State exposure**: SAS keys and connection strings land in state and are
  visible to anyone with state access — pull them from state or the
  pipeline, not from logs; rotate in the portal or CLI (regeneration is not
  managed by this module; the keys are read-only attributes of the rules).
- Not exposed, deliberately (pass-through candidates for a later minor
  release): `auto_inflate_enabled`/`maximum_throughput_units`, namespace
  `minimum_tls_version`, `retention_description` (extended/compact
  retention), Kafka clients (a service-level property, not a provider
  argument), dedicated cluster resources, schema groups/schema registry, and
  private endpoints. Secondary endpoints are available on the resource but
  not output here.

## Import

Namespace by ARM ID; hub, consumer group and authorization rules by their
scope IDs (quoted composite-key addresses):

```
tofu import 'azurerm_eventhub_namespace.namespace["telemetry"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.EventHub/namespaces/<name>"
tofu import 'azurerm_eventhub.hub["telemetry.telemetry"]' "<namespace_id>/eventhubs/<name>"
tofu import 'azurerm_eventhub_consumer_group.consumer_group["telemetry.telemetry.analytics"]' "<hub_id>/consumerGroups/<name>"
tofu import 'azurerm_eventhub_namespace_authorization_rule.namespace_rule["telemetry.publisher"]' "<namespace_id>/authorizationRules/<name>"
tofu import 'azurerm_eventhub_authorization_rule.hub_rule["telemetry.telemetry.publisher"]' "<hub_id>/authorizationRules/<name>"
```
