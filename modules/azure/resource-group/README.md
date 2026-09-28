# azure/resource-group

Map-keyed module for Azure resource groups. Each entry creates one
`azurerm_resource_group` with tags and optional managed-by metadata, placed
in the subscription configured on the provider.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `resource_groups` | `map(object)` | — | Map of resource groups keyed by an arbitrary unique ID. |

Plan-time validation: `name` matches Azure's resource group naming rules
(1–90 chars; letters, digits, `_`, `-`, `(`, `)`, `.`; no trailing period),
names are unique across entries case-insensitively (Azure enforces
per-subscription uniqueness and all entries share the provider's
subscription), `location` is non-empty, `managed_by` is a full ARM resource
ID, and tags respect the 50-entry / 512-char key / 256-char value limits.

### `resource_groups` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Resource group name. 1–90 chars; letters and digits (any Unicode script), `_`, `-`, `(`, `)`, `.`; cannot end in a period. Unique per subscription, case-insensitively. Immutable — Azure cannot rename a resource group, so changing it forces replacement. Validated client-side. |
| `location` | `string` | — | Azure region where the group's metadata lives — not the location of the resources inside it, which may sit in any region. The provider normalizes display names (`West Europe` → `westeurope`). Immutable — changing it forces replacement. |
| `managed_by` | `string` | `null` | Full ARM resource ID of the resource or application that manages this group (informational metadata, e.g. an Automation account). Immutable — changing it forces replacement. Format validated (must start with `/`). |
| `tags` | `map(string)` | `{}` | Tags on the resource group. The tag set is authoritative — see Notes. Tags do not propagate to the resources inside the group. Azure-enforced limits: 50 tags, keys ≤ 512 chars, values ≤ 256 chars. |

## Outputs

| Name | Description |
|---|---|
| `resource_group_ids` | Map of key => full ARM resource ID (`/subscriptions/<id>/resourceGroups/<name>`). |
| `resource_group_names` | Map of key => resource group name. azurerm resources take `resource_group_name` (a name string), not an ID — hand this to other Azure modules. |

## Example

```hcl
resource_groups = {
  "platform-prod" = {
    name     = "rg-platform-prod"
    location = "westeurope"
    tags = {
      env = "prod"
    }
  }
  "platform-npd" = {
    name     = "rg-platform-npd"
    location = "West Europe"
    tags = {
      env = "npd"
    }
  }
  "automation-managed" = {
    name       = "rg-shared-automation"
    location   = "westeurope"
    managed_by = "/subscriptions/12345678-1234-5678-9012-123456789012/resourceGroups/rg-automation/providers/Microsoft.Automation/automationAccounts/automation-example"
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource group names — but names
  themselves must be unique per subscription and the module rejects
  case-insensitive duplicates at plan time (the resource has no subscription
  argument, so every entry lands in the provider's subscription).
- Destroying a resource group deletes every resource inside it, including
  resources Terraform does not manage. Since azurerm 3.0 the provider refuses
  that destroy while unmanaged resources remain; the provider feature toggle
  `features { resource_group { prevent_deletion_if_contains_resources = false } }`
  restores the older delete-everything behavior (the toggle defaults to true,
  i.e. refuse). Review what lives in the group before destroying.
- `name`, `location` and `managed_by` are immutable — changing any of the
  three forces replacement (new group, then destroy of the old one, with the
  destroy semantics above). There is no rename or move through this
  resource; moving existing resources between groups is a separate ARM
  operation this module does not manage.
- Tags are authoritative for the group's tag set: the provider PUTs the full
  configured map, so tags added in the portal or CLI are removed on the next
  apply with tag changes. Manage resource group tags here or not at all.
  Resource group tags do not inherit down to the resources inside the group.
- Placement follows the provider: the resource has no `subscription_id`
  argument, so groups are created in the subscription configured on the
  provider block (required by azurerm since 4.0 — set `subscription_id` or
  `ARM_SUBSCRIPTION_ID`). All entries in one module instance share that
  subscription.
- The caller needs `Microsoft.Resources/subscriptions/resourceGroups/write`
  on the subscription (granted by Contributor or Owner); deleting groups
  needs the matching delete permission from the same roles.
- `location` is validated loosely on purpose: the provider normalizes display
  names ("West Europe" → "westeurope"), so a strict region allowlist would
  reject valid inputs and go stale as regions launch; unknown regions fail at
  apply with ARM's error.
- For the subscription GUID in import IDs and scoping, see
  `azure/subscription`'s `subscription_ids` output.

## Import

`tofu import 'azurerm_resource_group.resource_group["<key>"]' "/subscriptions/<id>/resourceGroups/<name>"`

Importing adopts only the group shell — resources already inside stay
unmanaged by Terraform and will block destroy unless the provider's
`features { resource_group { prevent_deletion_if_contains_resources = false } }`
toggle is set.
