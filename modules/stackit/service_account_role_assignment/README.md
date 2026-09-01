# stackit/service_account_role_assignment

Map-keyed module for STACKIT 'Act-As' role assignments on a service account.

The `subject` (typically another service account, e.g. the SKE service
account — real-world SKE service-account emails end in
`@ske.sa.stackit.cloud`) is granted the right to impersonate the target
service account — a common example is authorizing the SKE service account to
act as a project-specific service account to access APIs such as KMS.

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
| `resource_id` | `string` | — | The service account UUID the role is assigned to (the provider UUID-validates this attribute) — the `service_account_id` output of the upstream `stackit_service_account` resource (this repo has no `stackit/service-account` module). |
| `role` | `string` | — | Role name, e.g. `user`. Available roles are queryable per resource: `stackit curl https://authorization.api.stackit.cloud/v2/{resourceType}/{resourceId}/roles`. |
| `subject` | `string` | — | The identity that may act as the target service account: user email, service account email, or client name; all letters lowercase (provider-enforced). |

## Outputs

`role_assignments` — map of key => assignment ID (`"{resource_id},{role},{subject}"`), also usable as the import ID.

## Example

```hcl
# Typical case: grant the SKE service account Act-As rights over a
# project-specific service account (real-world SKE service-account emails
# end in @ske.sa.stackit.cloud).
role_assignments = {
  "ske-act-as" = {
    resource_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    role        = "user"
    subject     = "ske-bot@example.com"
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
  create the Act-As right is briefly revoked. Removing an entry destroys
  that assignment.
- `destroy` revokes the Act-As (impersonation) rights — use Terragrunt- or
  pipeline-level safeguards if that is unwanted.
- Act-As grants are effectively credential delegation — the subject can do
  everything the target service account can — so scope entries deliberately.
- Chaining: pass the `service_account_id` output of an upstream
  `stackit_service_account` resource as `resource_id` (no sibling module in
  this repo; Terragrunt `dependency`).
- The runner's service account needs rights to manage role assignments on
  the target resource (rights over the target service account cover this —
  guidance, not a documented permission). Provider authentication (service
  account key flow) is configured at the consumer's root level.
- The provider floor `>= 0.113.0` is the version against which the current
  experimental shape of the resource is confirmed; the role-assignment
  resources were refactored by the provider over time and the current shape
  is stable from this floor on.

## Import

`stackit_authorization_service_account_role_assignment` ← `{resource_id},{role},{subject}`

Use the `import {}` block with `id = "${resource_id},${role},${subject}"`.
All three attributes are required in config, so an imported assignment plans
clean only when the config matches the upstream assignment. (The upstream
doc's import example shows the type name
`stackit_authorization_service_account_assignment` — a typo; the correct
resource type is `stackit_authorization_service_account_role_assignment`.)
