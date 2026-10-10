# azure/log-analytics

Map-keyed module for Log Analytics workspaces with nested linked services and
linked storage accounts. Each entry creates one
`azurerm_log_analytics_workspace` in the named resource group; child links wire
into the workspace resources this module creates itself — no workspace-ID
plumbing on the consumer side.

## Destroy semantics (read before using)

- Removing a workspace key destroys the workspace and its stored queries;
  data already ingested follows the retention policy of the (now deleted)
  workspace — plan purges deliberately.
- Removing a linked-service or linked-storage entry detaches the link only —
  the Automation account, cluster or storage accounts are untouched.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `workspaces` | `map(object)` | — | Map of Log Analytics workspaces keyed by an arbitrary unique ID. |

Plan-time validation: `name` is 4–63 characters (letters/digits/hyphens, no
edge hyphens); `sku` in the documented set; `retention_in_days` 30–730;
`reservation_capacity_in_gb_per_day` only with the `CapacityReservation` SKU
and one of the documented reservation levels; access-type enums; linked
services with exactly one of `read_access_id`/`write_access_id` as full ARM
IDs; linked storage with a valid `data_source_type`, at least one storage
account ID and one entry per data source type per workspace; tags respecting
the 50/512/256 limits; map keys on every level without `.`;
`identity.identity_ids` required when the identity type includes
`UserAssigned`.

### `workspaces` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Workspace name: 4–63 characters letters/digits/hyphens, no edge hyphens (validated). Unique per resource group. |
| `resource_group_name` | `string` | — | Resource group the workspace lives in. Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region. Immutable — changing it forces replacement. |
| `sku` | `string` | `PerGB2018` | `PerGB2018`, `PerNode`, `Premium`, `Standalone`, `Standard`, `CapacityReservation`, `LACluster` or `Unlimited` (validated). Changing it forces replacement **except** PerGB2018↔CapacityReservation — see Notes. |
| `retention_in_days` | `number` | `null` | Data retention, 30–730 days (validated). Some regions accept only 30, 31, 60, 90, 120, 180, 365, 550 or 730. 730 requires Premium commitment tiers on most plans. |
| `daily_quota_gb` | `number` | `null` | Daily ingestion cap in GB; omit or `-1` for no cap (validated ≥ -1). |
| `cmk_for_query_forced` | `bool` | `null` | Make customer-managed storage mandatory for query management. |
| `immediate_data_purge_on_30_days_enabled` | `bool` | `null` | Remove workspace data immediately after 30 days instead of the retention window. |
| `reservation_capacity_in_gb_per_day` | `number` | `null` | Reservation level for `CapacityReservation`: one of 50, 100, 200, 300, 400, 500, 1000, 2000, 5000, 10000, 25000, 50000 GB/day (validated, CapacityReservation-only). Raising or entering it starts a 31-day commitment. |
| `data_collection_rule_id` | `string` | `null` | Full ARM resource ID of the default Data Collection Rule for the workspace. |
| `internet_ingestion_access_type` | `string` | `Enabled` | `Enabled`, `Disabled` or `SecuredByPerimeter` (validated). |
| `internet_query_access_type` | `string` | `Enabled` | `Enabled`, `Disabled` or `SecuredByPerimeter` (validated). |
| `local_authentication_enabled` | `bool` | `true` | Keep the legacy shared-key/certificate access alongside Entra ID. Pair with the shared-key outputs only while it is on. |
| `allow_resource_only_permissions` | `bool` | `true` | Let users read data scoped to resources they can see without workspace-level RBAC. |
| `identity` | `object` | `null` | Optional identity block — `{ type, identity_ids }`; `identity_ids` required when the type includes `UserAssigned` (validated). |
| `linked_services` | `map(object)` | `{}` | Linked services (Automation accounts / clusters) — see the object table. |
| `linked_storage_accounts` | `map(object)` | `{}` | Linked storage accounts (BYOS for insights) — see the object table. |
| `tags` | `map(string)` | `{}` | Tags on the workspace. Authoritative — a change replaces the whole set. |

### `linked_services` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `read_access_id` | `string` | `null` | ARM ID of the linked resource for read access — an Automation Account. Exactly one of this or `write_access_id` (validated). |
| `write_access_id` | `string` | `null` | ARM ID of the linked resource for write access — a Log Analytics Cluster. Exactly one of the two (validated); see Notes for the LACluster SKU pairing. |

### `linked_storage_accounts` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `data_source_type` | `string` | — | `CustomLogs`, `AzureWatson`, `Query`, `Ingestion` or `Alerts` (validated). Strings the ARM link on the workspace — one entry per type (including net-new `CustomLogs`), validated distinct per workspace. |
| `storage_account_ids` | `list(string)` | — | At least one full ARM storage-account ID (validated) — IDs from the `azure/storage-account` module's `storage_account_ids` output. |

## Outputs

| Name | Description |
|---|---|
| `workspace_ids` | Map of workspace key => full ARM resource ID. |
| `workspace_names` | Map of workspace key => workspace name. |
| `workspace_customer_ids` | Map of workspace key => workspace Customer ID (GUID) — the value DCRs and agents call the workspace ID. |
| `workspace_primary_shared_keys` | Map of workspace key => primary shared key (sensitive). |
| `workspace_secondary_shared_keys` | Map of workspace key => secondary shared key (sensitive). |
| `linked_service_names` | Map of `<workspace_key>.<link_key>` => generated link name (`"<workspace>/<type>"`). |
| `linked_service_ids` | Map of `<workspace_key>.<link_key>` => linked-service ARM resource ID. |
| `linked_storage_account_ids` | Map of `<workspace_key>.<link_key>` => linked-storage ARM resource ID. |

## Example

```hcl
workspaces = {
  "ops-eu" = {
    name                          = "log-ops-eu-01"
    resource_group_name           = "rg-monitor-prod"
    location                      = "westeurope"
    retention_in_days             = 90
    internet_ingestion_access_type = "SecuredByPerimeter"
    local_authentication_enabled  = false

    identity = {
      type = "SystemAssigned"
    }

    linked_services = {
      "automation" = {
        read_access_id = "/subscriptions/<id>/resourceGroups/rg-automation/providers/Microsoft.Automation/automationAccounts/aaa-ops-eu"
      }
    }

    linked_storage_accounts = {
      "custom-logs" = {
        data_source_type    = "CustomLogs"
        storage_account_ids = ["/subscriptions/<id>/resourceGroups/rg-monitor/providers/Microsoft.Storage/storageAccounts/stopslogseu01"]
      }
    }

    tags = {
      env = "prod"
    }
  }
  "reservation-eu" = {
    name                = "log-reservation-eu-01"
    resource_group_name = "rg-monitor-prod"
    location            = "westeurope"
    sku                 = "CapacityReservation"
    reservation_capacity_in_gb_per_day = 100
    linked_services = {
      "cluster" = {
        write_access_id = "/subscriptions/<id>/resourceGroups/rg-monitor/providers/Microsoft.OperationalInsights/clusters/cla-logs-eu"
      }
    }
  }
}
```

## Notes

- **Shared keys in state**: `workspace_primary_shared_keys` and
  `workspace_secondary_shared_keys` are sensitive outputs but still land in
  state. If that is unacceptable, disable `local_authentication_enabled` and
  gate ingestion/query on Entra RBAC only, then do not consume the key
  outputs.
- **SKU changes**: `PerGB2018` ↔ `CapacityReservation` swaps in place; every
  other SKU change forces workspace replacement and all its links cascade.
  Move to `CapacityReservation` on a lower tier before stepping up.
- **LACluster**: set `sku = "LACluster"` only while the workspace is linked
  to a cluster via a `write_access_id` linked service (validated loosely —
  the module cannot see cross-workspace probes); the Azure API cannot change
  the SKU while linked.
- **Network security perimeter**: `SecuredByPerimeter` access types are
  meaningful only together with an `azurerm_network_security_perimeter_
  association` provisioning the workspace — association management is out of
  this module's scope.
- Local auth + Entra: `local_authentication_enabled = false` leaves Entra
  only; agents unicorning through DCRs still need the `data_collection_rule_id`
  wiring, also out of scope for workspace-level settings.
- Tags are authoritative — a change replaces the whole tag set; RBAC needed
  is `Microsoft.OperationalInsights/workspaces/write` plus link CRUD on
  scope.

## Import

Workspaces import by ARM ID; linked services reference the workspace by ID
and linked storage accounts by theirs. Linked services import under the
`<type>` of their link:

```
tofu import 'azurerm_log_analytics_workspace.workspace["ops-eu"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<name>"
tofu import 'azurerm_log_analytics_linked_service.linked_service["ops-eu.automation"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<name>/linkedServices/Automation"
tofu import 'azurerm_log_analytics_linked_service.linked_service["reservation-eu.cluster"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<name>/linkedServices/Cluster"
tofu import 'azurerm_log_analytics_linked_storage_account.linked_storage["ops-eu.custom-logs"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<name>/linkedStorageAccounts/CustomLogs"
```
