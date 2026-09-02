# stackit/folder_role_assignment

Map-keyed module for STACKIT role assignments on a folder.

These resources are part of the provider's experimental `iam` feature. The
consumer's provider block must set `experiments = ["iam"]`, and the behavior
may change or the resources may be removed in future provider releases.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `role_assignments` | `map(object)` | — | Map of role assignments keyed by an arbitrary unique ID. |

### `role_assignments` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `resource_id` | `string` | — | The folder UUID the role is assigned to (the provider UUID-validates this attribute) — `stackit/folder`'s `folder_id` output. |
| `role` | `string` | — | Role name, e.g. `owner`, `reader`. Available roles are queryable per resource: `stackit curl https://authorization.api.stackit.cloud/v2/{resourceType}/{resourceId}/roles`. |
| `subject` | `string` | — | User email, service account email, or client name; all letters lowercase (provider-enforced). |

## Outputs

`role_assignments` — map of key => assignment ID (`"{resource_id},{role},{subject}"`), also usable as the import ID.

## Example

```hcl
# resource_id may differ per entry — each entry targets its own folder.
# e.g. chain stackit/folder's folder_id output via a Terragrunt dependency.
role_assignments = {
  "folder-owner" = {
    resource_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    role        = "owner"
    subject     = "jane.doe@example.com"
  }
  "npd-auditor" = {
    resource_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    role        = "reader"
    subject     = "audit-bot@example.com"
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not role or subject values.
  Multiple entries can share the same role or subject; only the full
  `resource_id,role,subject` triple must be unique (next bullet).
- Two entries with the same `(resource_id, role, subject)` combination are
  rejected at plan time by the module, and the upstream API rejects them at
  apply ("found a duplicate role assignment") — identical entries are
  redundant by definition.
- The consumer's provider block must set `experiments = ["iam"]` — the
  provider errors if the experiment is not enabled.
- These resources are experimental and may change or be removed in future
  provider releases; pin the provider version at the consumer.
- `subject` must be all lowercase — the provider rejects mixed-case values.
- Role names vary per resource and evolve; discover the available roles via
  the authorization API curl shown above. The module intentionally does not
  validate role names client-side.
- Any change to `resource_id`, `role`, or `subject` — and renaming a map
  key — replaces the assignment (the provider sets `RequiresReplace()` on
  all three attributes), destroying and recreating it; between destroy and
  create the role is briefly revoked. Removing an entry destroys that
  assignment.
- `destroy` revokes the assignments (removes access) — use Terragrunt- or
  pipeline-level safeguards if that is unwanted.
- Chaining: pass `stackit/folder`'s `folder_id` output as `resource_id`
  (Terragrunt `dependency`).
- The runner's service account needs rights to manage role assignments on
  the target resource (owner-level role on the folder covers this —
  guidance, not a documented permission). Provider authentication (service
  account key flow) is configured at the consumer's root level.
- The provider floor `>= 0.113.0` is the version against which the current
  experimental shape of the resource is confirmed; the role-assignment
  resources were refactored by the provider over time and the current shape
  is stable from this floor on.

## Import

`stackit_authorization_folder_role_assignment` ← `{resource_id},{role},{subject}`

Use the `import {}` block with `id = "${resource_id},${role},${subject}"`.
All three attributes are required in config, so an imported assignment plans
clean only when the config matches the upstream assignment.
