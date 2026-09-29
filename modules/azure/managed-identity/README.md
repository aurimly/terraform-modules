# azure/managed-identity

Map-keyed module for Azure user-assigned managed identities. Each entry
creates one `azurerm_user_assigned_identity` in the named resource group, in
the subscription configured on the provider.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `managed_identities` | `map(object)` | — | Map of managed identities keyed by an arbitrary unique ID. |

Plan-time validation: `name` matches Azure's user-assigned identity naming
rules (3–128 chars; letters, digits, `_`, `-`; no periods; must start with a
letter or digit), names are unique across entries sharing a resource group
case-insensitively, `name`, `resource_group_name` and `location` are
non-empty, and tags respect the 50-entry / 512-char key / 256-char value
limits.

### `managed_identities` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Identity name. 3–128 chars; letters and digits (any Unicode script), `_`, `-`; cannot contain periods; must start with a letter or digit. Validated client-side. Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group the identity lives in (typically `dependency.rg.outputs.resource_group_names["platform"]` with the `azure/resource-group` module). Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region. The provider normalizes display names (`West Europe` → `westeurope`). Immutable — changing it forces replacement. |
| `tags` | `map(string)` | `{}` | Tags on the identity. The tag set is authoritative — see Notes. |

## Outputs

| Name | Description |
|---|---|
| `managed_identity_ids` | Map of key => full ARM resource ID (`/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<name>`). Hand this to consumer resources' identity blocks (e.g. `azurerm_storage_account` `identity.identity_ids`, `azurerm_container_app` identity blocks). |
| `managed_identity_principal_ids` | Map of key => principal ID — the service-principal object ID used for RBAC role assignments (e.g. with `azure/subscription-iam`). |
| `managed_identity_client_ids` | Map of key => client ID — the app (client) ID used for Entra ID / SDK auth and OIDC federated credentials. |
| `managed_identity_tenant_ids` | Map of key => tenant ID the identity belongs to. |

## Example

```hcl
managed_identities = {
  "workload" = {
    name                = "id-workload-prod"
    resource_group_name = "rg-platform-prod"
    location            = "westeurope"
    tags = {
      env = "prod"
    }
  }
  "federation" = {
    name                = "id-federation-prod"
    resource_group_name = "rg-platform-prod"
    location            = "westeurope"
  }
}
```

## Notes

- All three identity attributes (`name`, `resource_group_name`, `location`)
  force replacement if changed; `tags` update in place.
- Tags are authoritative for the identity's tag set: the provider PUTs the
  full configured map, so tags added in the portal or CLI are removed on the
  next apply with tag changes.
- `principal_id` is the object ID of the identity's service principal — use
  it for RBAC role assignments (`"Principal" = <principal_id>`). `client_id`
  is the application (client) ID of the identity's backing service
  principal — use it for SDK/CLI auth and as the app ID when adding
  federated credentials. Both are
  assigned by Azure at creation; the identity itself grants no permissions.
- Role assignments are a separate concern: bind `managed_identity_principal_ids["workload"]`
  with `azure/subscription-iam` (subscription scope) or any other RBAC
  resource. This module creates the identity only.
- Attaching the identity to a consumer resource requires
  `Microsoft.ManagedIdentity/userAssignedIdentities/assign/action` on the
  identity; creating or deleting it requires the matching write/delete
  permissions on the resource group (granted by Contributor or Owner).
- Names are unique per resource group, case-insensitively (Azure-enforced);
  the module rejects duplicates among entries sharing a resource group and
  validates the 3–128-character limit at plan time.
- Placement follows the provider: the resource has no subscription argument,
  so identities are created in the subscription configured on the provider
  block (required by azurerm since 4.0 — set `subscription_id` or
  `ARM_SUBSCRIPTION_ID`).
- Not exposed, deliberately: `isolation_scope` (single value `Regional` for
  new accounts) — pass-through candidate for a later minor release.

## Import

`tofu import 'azurerm_user_assigned_identity.managed_identity["<key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<name>"`
