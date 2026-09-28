# azure/subscription-iam

Map-keyed module for Azure RBAC role assignments at subscription scope. Each
entry creates one `azurerm_role_assignment`, granting a built-in role (by
name) or a custom role (by fully-qualified role definition ID) to a principal.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `subscription_id` | `string` | — | Bare subscription GUID. Not inferred from the provider default. |
| `role_assignments` | `map(object)` | `{}` | Map of role assignments keyed by an arbitrary unique ID. |

Plan-time validation: each entry sets exactly one of `role_definition_id` or
`role_definition_name`, `principal_type` is one of `User`, `Group`,
`ServicePrincipal`, `skip_service_principal_aad_check` requires
`principal_type = "ServicePrincipal"`, `condition_version` (`1.0`/`2.0`)
requires `condition`, condition/description are non-empty, and two entries
for the same principal and role may not both be unconditional (Azure rejects
duplicates server-side).

### `role_assignments` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `principal_id` | `string` | — | Object ID of the principal (Entra ID user, group, service principal or managed identity) — *not* the application/client ID. |
| `role_definition_name` | `string` | — | Built-in role's display name, e.g. `Reader`, `Owner`, `Network Contributor`. Mutually exclusive with `role_definition_id` (XOR enforced). Case-insensitively matched by the provider. |
| `role_definition_id` | `string` | — | Fully-qualified role definition ID, e.g. `/subscriptions/<id>/providers/Microsoft.Authorization/roleDefinitions/<guid>` — typically `azurerm_role_definition.<x>.role_definition_resource_id` or the `role_definition_id` of the `azurerm_role_definition` data source. Mutually exclusive with `role_definition_name` (XOR enforced). Format validated. |
| `principal_type` | `string` | `null` | `User`, `Group` or `ServicePrincipal`. Read back automatically when omitted; set it explicitly when the principal creating the assignment is constrained by ABAC rules filtering on principal type. |
| `condition` | `string` | `null` | ABAC condition limiting what the assignment applies to (CEL syntax). |
| `condition_version` | `string` | `null` | `1.0` or `2.0`; ABAC conditions use `2.0`. When `condition` is set without it, the provider defaults the version; setting it pins the version on the assignment. |
| `description` | `string` | `null` | Free-text description on the assignment. |
| `delegated_managed_identity_resource_id` | `string` | `null` | Delegated ARM resource ID holding a managed identity (cross-tenant scenarios only). |
| `skip_service_principal_aad_check` | `bool` | `false` | For service principals: skip the Entra ID existence check to survive replication lag on freshly-provisioned SPs. Requires `principal_type = "ServicePrincipal"`. |

## Outputs

| Name | Description |
|---|---|
| `role_assignment_ids` | Map of key => role assignment resource ID (`/subscriptions/<id>/providers/Microsoft.Authorization/roleAssignments/<assignment-guid>`). |

## Example

```hcl
subscription_id = "12345678-1234-5678-9012-123456789012"

role_assignments = {
  "viewers" = {
    role_definition_name = "Reader"
    principal_id         = "aabbccdd-1122-3344-5566-778899aabbcc"
    principal_type       = "Group"
  }
  "linux-restart" = {
    role_definition_name = "Virtual Machine Contributor"
    principal_id         = "11223344-5566-7788-9900-aabbccddeeff"
    principal_type       = "ServicePrincipal"
    description          = "Azure Automation run-as SPN"
  }
  "delegated-rbac-admin" = {
    role_definition_name = "Role Based Access Control Administrator"
    principal_id         = "11223344-5566-7788-9900-aabbccddff11"
    principal_type       = "ServicePrincipal"
    condition_version    = "2.0"
    condition            = <<-EOT
    (
     (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
     )
     OR
     (
      @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {00000000-0000-0000-0000-000000000000}
     )
    )
    AND
    (
     (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
     )
     OR
     (
      @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {00000000-0000-0000-0000-000000000000}
     )
    )
    EOT
  }
}
```

## Notes

- Assignments here are non-authoritative: creating one does not remove other
  grants, and destroying one removes only that grant. Grants cascading from
  management group or resource-scope assignments are separate — check what
  already applies through inheritance before relying on a removal here.
- Azure enforces at most one assignment per principal + role + scope,
  conditions notwithstanding — duplicates fail at apply with "role
  assignment already exists", even when one of the two entries would carry
  a condition. The module rejects same-principal-same-role pairs at plan
  time (case-insensitively, matching the provider's CaseDifference
  suppression). Caveat: the same grant expressed once by
  `role_definition_name` and once by `role_definition_id` (the role's GUID)
  looks distinct to the plan check but still conflicts at apply — keep one
  entry per grant.
- `role_definition_name` must be the exact built-in role's display name
  (e.g. `Role Based Access Control Administrator`, not `RBAC Admin`); the
  provider resolves it to the role definition ID in the credential's
  subscription context. Custom roles live on the subscription that defines
  them — definitions from another subscription's scope (or a management
  group's) need the full `role_definition_id`, since the provider's built-in
  role lookup only searches the caller's subscription.
- ABAC conditions filtering on `@Request[...RoleDefinitionId]` /
  `@Resource[...RoleDefinitionId]` compare role-definition GUIDs — see
  Microsoft's role assignment condition examples for the credential format.
  Conditions need `condition_version = "2.0"`.
- Sub-assigning a role to a principal in a different directory fails at
  apply; `skip_service_principal_aad_check` does not remove the requirement
  for the principal to be resolvable after replication settles.
- Removing the principal from Entra ID first, then the assignment, can leave
  the assignment applicable to nobody: delete the assignment first (this
  module's entry), then the principal.
- The caller needs `Microsoft.Authorization/roleAssignments/write` on the
  subscription — granted by Owner or User Access Administrator at the
  subscription (typically inherited via the management group above it, or a
  Role Based Access Control Administrator assignment whose conditions
  cover role assignment management).
- The module builds the scope string `/subscriptions/<subscription_id>`,
  so hand it the bare GUID — for example from `azure/subscription`'s
  `subscription_ids` output.

## Import

`tofu import 'azurerm_role_assignment.role_assignment["<key>"]' "/subscriptions/<id>/providers/Microsoft.Authorization/roleAssignments/<assignment-guid>"`

Cross-tenant assignments carry a tenant suffix after a `|` — include it in
the import ID when present.
