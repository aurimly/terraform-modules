# azure/storage-account

Map-keyed module for Azure storage accounts. Each entry creates one
`azurerm_storage_account` in the named resource group, in the subscription
configured on the provider. Account names are unique across all of Azure —
not just within the resource group.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `storage_accounts` | `map(object)` | — | Map of storage accounts keyed by an arbitrary unique ID. |

Plan-time validation: `name` is 3–24 lowercase alphanumeric characters and
unique across entries, `name`/`resource_group_name`/`location` are non-empty,
`account_tier` is `Standard`/`Premium`, `account_replication_type` is one of
`LRS`/`ZRS`/`GRS`/`GZRS`/`RAGRS`/`RAGZRS`, `account_kind` is one of the five
provider-accepted kinds, `BlockBlobStorage`/`FileStorage` kinds require the
`Premium` tier, `access_tier` (when set) is one of `Hot`/`Cool`/`Cold`/`Smart`/`Premium`
and only valid for `StorageV2`/`BlobStorage`/`FileStorage` kinds,
`min_tls_version` is `TLS1_2`, `public_network_access` is
`Enabled`/`Disabled`/`SecuredByPerimeter`, `network_rules` (when set)
requires `default_action = "Deny"` (the provider rejects an `Allow`
default), at least one rule
source feeds it (`ip_rules` ≤ 30, bare IPv4 or IPv4 CIDRs with prefix 0–30;
`virtual_network_subnet_ids` are full ARM subnet IDs), `bypass` is a subset
of `AzureServices`/`Logging`/`Metrics`/`None`, and tags respect the
50-entry / 512-char key / 256-char value limits.

### `storage_accounts` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Account name: 3–24 lowercase alphanumeric characters, also the DNS label behind the endpoint hostnames. Globally unique across all of Azure (module checks uniqueness among its own entries only — see Notes). Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group the account lives in (typically `dependency.rg.outputs.resource_group_names["platform"]` with the `azure/resource-group` module). Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region. The provider normalizes display names (`West Europe` → `westeurope`). Immutable — changing it forces replacement. |
| `account_tier` | `string` | — | `Standard` or `Premium` (case-sensitive). Immutable — changing it forces replacement. |
| `account_replication_type` | `string` | — | Redundancy SKU: `LRS`, `ZRS`, `GRS`, `GZRS`, `RAGRS` or `RAGZRS` (case-sensitive, no hyphens). Updated in place within a redundancy class; non-zonal ↔ zonal changes force replacement except the equivalent pairs (`LRS` ↔ `ZRS`, `GRS` ↔ `GZRS`, `RAGRS` ↔ `RAGZRS`), which trigger migrations — see Notes. |
| `account_kind` | `string` | `StorageV2` | `Storage`, `StorageV2`, `BlobStorage`, `BlockBlobStorage` or `FileStorage` (case-sensitive). `Storage` → `StorageV2` upgrades in place; other kind changes force replacement. `BlockBlobStorage`/`FileStorage` require the `Premium` tier (validated). |
| `access_tier` | `string` | `null` | Blob access tier: `Hot`, `Cool`, `Cold`, `Smart` or `Premium` — only valid for `StorageV2`, `BlobStorage` and `FileStorage` kinds (validated). `null` leaves the provider default (`Hot`) in place. Updated in place. |
| `https_traffic_only_enabled` | `bool` | `true` | Require HTTPS for all requests over the data plane. Updated in place. |
| `min_tls_version` | `string` | `TLS1_2` | Minimum TLS version for storage requests. `TLS1_2` is the only value the current provider accepts (TLS 1.0/1.1 retired) — kept as an input so consumers can pin it explicitly. Updated in place. |
| `shared_access_key_enabled` | `bool` | `true` | Permit shared-key/SAS authorisation. `false` forces Entra-only data-plane auth with operational caveats — see Notes. Updated in place. |
| `public_network_access` | `string` | `Enabled` | `Enabled`, `Disabled` or `SecuredByPerimeter` (case-sensitive): the account's public endpoint reachability. `Disabled` pairs with private endpoints, `SecuredByPerimeter` with network security perimeters. Updated in place. |
| `allow_nested_items_to_be_public` | `bool` | `false` | Whether containers/blobs may have public access enabled at all. The current provider defaults it to `false` — public access is opt-in. Updated in place. |
| `infrastructure_encryption_enabled` | `bool` | `null` | Double encryption at rest (Azure-managed keys, above the always-on platform layer). `null` leaves the provider default (`false`) in place. Only valid for `StorageV2` kinds or `Premium` + `BlockBlobStorage`/`FileStorage` — ARM rejects it elsewhere. Immutable — changing it forces replacement, and it can never be turned off on an account. |
| `network_rules` | `object` | `null` | Optional single network-rules block, one per account (provider shape). `null` means no rules object is managed here — the account's default is Allow-everything. Updated in place. See the object table below. |
| `tags` | `map(string)` | `{}` | Tags on the account. The tag set is authoritative — see Notes. |

### `network_rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `default_action` | `string` | — | `Deny` (case-sensitive; the provider rejects rules with `Allow` — leaving the block `null` is the way to permit all traffic). Updated in place. |
| `bypass` | `set(string)` | `[]` | Services the rules never apply to: any subset of `AzureServices`, `Logging`, `Metrics`, `None` (case-sensitive). |
| `ip_rules` | `set(string)` | `[]` | Up to 30 entries (validated): bare IPv4 addresses or IPv4 CIDRs with prefix 0–30 — ARM rejects `/31`/`/32` and non-public addresses. |
| `virtual_network_subnet_ids` | `set(string)` | `[]` | Full ARM subnet resource IDs allowed through (typically from `azure/subnet`'s outputs). Azure requires the storage account-owning identity to have network operator rights on the VNets for cross-resource wiring. |

## Outputs

| Name | Description |
|---|---|
| `storage_account_ids` | Map of key => full ARM resource ID (`/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<name>`). |
| `storage_account_names` | Map of key => account name — data-plane SDKs/CLIs take the name, not an ID. |
| `storage_account_primary_blob_endpoints` | Map of key => primary blob endpoint URL (`https://<name>.blob.core.windows.net/`). |
| `storage_account_primary_queue_endpoints` | Map of key => primary queue endpoint URL. |
| `storage_account_primary_table_endpoints` | Map of key => primary table endpoint URL. |
| `storage_account_primary_file_endpoints` | Map of key => primary file endpoint URL. |
| `storage_account_access_keys` | Map of key => `{ primary_access_key = ..., secondary_access_key = ... }`. Sensitive: both members are provider-sensitive access keys. Keys are visible in state once there — pull them from state or the pipeline, never from logs; rotate in the portal/CLI — this module does not manage regeneration (the keys are read-only attributes of the account). |

## Example

```hcl
storage_accounts = {
  "data" = {
    name                      = "stexampledata01"
    resource_group_name       = "rg-platform-prod"
    location                  = "westeurope"
    account_tier              = "Standard"
    account_replication_type  = "LRS"
    account_kind              = "StorageV2"
    access_tier               = "Hot"
    network_rules = {
      default_action             = "Deny"
      bypass                     = ["AzureServices"]
      ip_rules                   = ["203.0.113.0/24"]
      virtual_network_subnet_ids = ["/subscriptions/12345678-1234-5678-9012-123456789012/resourceGroups/rg-platform-prod/providers/Microsoft.Network/virtualNetworks/vnet-platform/subnets/snet-workload"]
    }
    tags = {
      env = "prod"
    }
  }
  "blobs" = {
    name                              = "stexampleblobs01"
    resource_group_name               = "rg-platform-prod"
    location                          = "westeurope"
    account_tier                      = "Premium"
    account_replication_type          = "LRS"
    account_kind                      = "BlockBlobStorage"
    infrastructure_encryption_enabled = true
  }
}
```

## Notes

- `name`, `resource_group_name`, `location`, `account_tier` and
  `infrastructure_encryption_enabled` force replacement if changed;
  `account_replication_type` changes are special — see below. Everything
  else updates in place.
- **Redundancy changes**: switching between non-zonal and zonal classes —
  e.g. `LRS` → `GRS` or `ZRS` → `RAGZRS` — forces resource replacement.
  The only exception is the equivalent pairs (`LRS` ↔ `ZRS`,
  `GRS` ↔ `GZRS`, `RAGRS` ↔ `RAGZRS`): those update in place and kick off a
  customer-initiated migration which takes hours to days and which the
  provider does not wait for — plan diffs can stay suppressed while a
  migration runs. Do not stack further changes on the account during a
  migration.
- `BlockBlobStorage` and `FileStorage` kinds require `account_tier =
  "Premium"` (validated, mirroring provider docs). The reverse —
  `Premium` + `StorageV2`, the premium page-blob account — is a valid Azure
  type this module lets through to ARM.
- `shared_access_key_enabled = false` means every request — including SAS
  — must be Entra-authorised. The provider itself needs
  `storage_use_azuread = true` in its `provider {}` block to manage
  data-plane children (containers, blobs) against such an account, and not
  all tooling supports AD-only auth. Flag platform-wide before disabling;
  re-enabling later is a plain in-place update.
- `public_network_access = "Disabled"` cuts public reachability and pairs
  with private endpoints out of this module's scope; `SecuredByPerimeter`
  defers to network security perimeters. Keeping `Enabled` while setting
  `network_rules` is the firewall-filtered middle ground.
- `allow_nested_items_to_be_public` defaults to `false` (mirroring the
  current provider default): with `false`, containers cannot get public
  access at all; with `true`, they still only become public when a container
  sets its own access policy.
- `min_tls_version` is pinned to `TLS1_2` (TLS 1.0/1.1 retired August 2025)
  and kept as an input for explicit pinning — a future provider widening
  would not change the module's shape.
- `network_rules` here is a single optional object matching the provider's
  one-block-per-account shape. Do not mix with the separate
  `azurerm_storage_account_network_rules` resource — the two fight over the
  same block and produce spurious diffs. To return the account to
  Allow-everything, remove the block here (`network_rules = null`); if you
  instead use the separate resource, switching `Deny` → `Allow` requires
  defining the block, not removing it.
- Tags are authoritative for the account's tag set: the provider PUTs the
  full configured map, so portal/CLI tags are removed on the next apply
  with tag changes.
- The caller needs `Microsoft.Storage/storageAccounts/write` (and delete)
  on the resource group for the account, and network-operator involvement
  (typically the `Microsoft.Network/virtualNetworks/subnets/joinViaServiceEndpoint`
  permission or the Storage Account Network Operator role on the VNets
  referenced by `network_rules`) when wiring subnet rules.
- Region availability of the redundancy SKUs and premium-kind restrictions
  (e.g. which replication options a region offers) are checked by ARM at
  apply, not here.
- Placement follows the provider: no subscription argument — everything
  lands in the subscription configured on the provider block (required by
  azurerm since 4.0 — set `subscription_id` or `ARM_SUBSCRIPTION_ID`).
- Not exposed, deliberately (pass-through candidates for a later minor
  release): `identity` block and `customer_managed_key` (add together with
  the CMK use case), `sas_policy`, `static_website`, `blob_properties`
  (versioning, soft delete, change feed, CORS), `share_properties`,
  `queue_properties`, `azure_files_authentication`, `custom_domain`,
  `routing`, `immutability_policy`, `is_hns_enabled` (ADLS Gen2),
  `sftp_enabled`, `nfsv3_enabled`, `dns_endpoint_type`, `edge_zone`,
  `allowed_copy_scope`, `cross_tenant_replication_enabled`,
  `default_to_oauth_authentication`, `large_file_share_enabled`,
  `local_user_enabled`, `queue_encryption_key_type`,
  `table_encryption_key_type`, `provisioned_billing_model_version`, and
  inside `network_rules`: `private_link_access`. Secondary endpoints,
  internet/microsoft-routing endpoint variants and the `_host` variants of
  the service endpoints are available on the resource but not output here.

## Import

`tofu import 'azurerm_storage_account.storage_account["<key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<name>"`
