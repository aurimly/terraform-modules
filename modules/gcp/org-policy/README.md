# gcp/org-policy

Map-keyed module for Google Cloud organization policies
(`google_org_policy_policy`), applying constraints at the organization,
folder, or project level.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `org_policies` | `map(object)` | — | Map of policies keyed by an arbitrary unique ID. |

### `org_policies` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Policy resource name: `organizations/{org_id}/policies/{constraint}`, `folders/{folder_id}/policies/{constraint}` or `projects/{project_id}/policies/{constraint}`. Format validated. |
| `parent` | `string` | — | Parent resource the policy belongs to: `organizations/{org_id}`, `folders/{folder_id}` or `projects/{project_id}`. Format validated and must match the resource type of `name`. |
| `deletion_policy` | `string` | `PREVENT` | One of `PREVENT`, `DELETE`, `ABANDON`. Stricter than the provider default (`DELETE`), matching this repo's `gcp/folder` and `gcp/project` modules. |
| `spec` | `object` | `null` | Active policy configuration. See below. |
| `dry_run_spec` | `object` | `null` | Audit-only policy configuration (monitors impact without enforcing). Same shape as `spec`. |

### `spec` / `dry_run_spec` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `inherit_from_parent` | `bool` | `null` | Inherit rules set higher up in the hierarchy. Only for list constraints. |
| `reset` | `bool` | `null` | Ignore policies above this resource and restore the constraint's default behavior. If `true`, `rules` must be empty and `inherit_from_parent` must not be `true` (validated). |
| `rules` | `list(object)` | `[]` | Policy rules, evaluated in order. See below. |

### `rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `allow_all` | `string` | `null` | `"TRUE"` allows all values; overridable via `values.allowed_values`. Only for list constraints. |
| `deny_all` | `string` | `null` | `"TRUE"` denies all values; overridable via `values.denied_values`. Only for list constraints. |
| `enforce` | `string` | `null` | `"TRUE"`/`"FALSE"` enforcement for boolean constraints. |
| `parameters` | `string` | `null` | JSON-encoded parameter values for managed constraints (e.g. `jsonencode({...})`). |
| `condition` | `object` | `null` | CEL condition deciding whether the rule applies. `expression` is required by the module (the provider schema marks it optional, but the API rejects a condition without it); `title`, `description`, `location` optional. |
| `values` | `object` | `null` | `allowed_values` / `denied_values` lists for list constraints. |

At most one of `allow_all`, `deny_all`, `enforce` can be set per rule (validated), and
their values must be `"TRUE"` or `"FALSE"` (validated).

## Outputs

`org_policies` — map of policy key => object:

| Attribute | Description |
|---|---|
| `id` | Provider ID in the form `{parent}/policies/{name}`. |
| `name` | Policy resource name. |
| `parent` | Parent resource. |
| `etag` | Opaque concurrency-control tag computed by the server. |
| `spec` | The active spec block as returned by GCP (list with one element; empty when unset). |
| `dry_run_spec` | The dry-run spec block as returned by GCP (list with one element; empty when unset). |

## Example

```hcl
org_policies = {
  require-os-login = {
    name   = "projects/example-project/policies/compute.requireOsLogin"
    parent = "projects/example-project"
    spec = {
      rules = [
        { enforce = "TRUE" },
      ]
    }
  }
  allowed-image-projects = {
    name   = "projects/example-project/policies/compute.trustedImageProjects"
    parent = "projects/example-project"
    spec = {
      rules = [
        {
          allow_all = "TRUE"
        },
      ]
    }
  }
  restrict-subnetworks = {
    name   = "projects/example-project/policies/compute.restrictSharedVpcSubnetworks"
    parent = "projects/example-project"
    spec = {
      rules = [
        {
          values = {
            allowed_values = ["projects/example-host-project/regions/us-central1/subnetworks/example-subnet"]
          }
        },
      ]
    }
  }
  dry-run-serial-port = {
    name   = "projects/example-project/policies/compute.disableSerialPortLogging"
    parent = "projects/example-project"
    dry_run_spec = {
      rules = [
        { enforce = "TRUE" },
      ]
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not policy names. Multiple policies
  can share a constraint name at different parents, so the key disambiguates.
- At least one of `spec` or `dry_run_spec` should be set for the policy to
  take effect; both can be set together (dry-run evaluates alongside the
  active spec).
- The API accepts `projects/{project_id}/policies/...` in `name` but stores and
  returns the equivalent project number. The provider treats the two forms as
  equal (diff suppressed), so project IDs are safe to use.
- `name` and `parent` are immutable upstream (ForceNew). Combined with the
  default `deletion_policy = "PREVENT"`, renaming or moving a policy forces a
  blocked replacement — set `deletion_policy = "DELETE"` first when a policy
  needs to move between parents.
- `enforce` is only for boolean constraints; `allow_all`, `deny_all` and
  `values` are only for list constraints. For boolean constraints exactly one
  rule without a `condition` is required, and conditional rules must set
  `enforce` opposite to it.
- `inherit_from_parent` can only be set for list constraints.
- If a policy was created outside Terraform, import it first
  (`terraform import google_org_policy_policy.org_policy["key"] {parent}/policies/{constraint}`)
  instead of creating a duplicate — the API rejects existing policies with 409.
- `etag` is server-computed and not settable, so it is not exposed as an
  input.
- With the default `deletion_policy = "PREVENT"`, Terraform refuses to destroy
  or replace a policy. Set `deletion_policy = "DELETE"` to allow deletion;
  `ABANDON` removes the policy from state without touching it in GCP.

## Import

`google_org_policy_policy` ← `{parent}/policies/{constraint}`

```bash
terraform import 'google_org_policy_policy.org_policy["key"]' 'projects/example-project/policies/compute.requireOsLogin'
```
