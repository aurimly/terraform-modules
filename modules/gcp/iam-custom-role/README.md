# gcp/iam-custom-role

Map-keyed module for Google Cloud custom IAM roles, at organization or project
level.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `organization_roles` | `map(object)` | — | Organization-level custom roles; see `organization_roles` object. |
| `project_roles` | `map(object)` | — | Project-level custom roles; see `project_roles` object. |

### `organization_roles` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `org_id` | `string` | — | Bare numeric organization id (e.g. `123456789012`), not `organizations/<org_id>` (validated). |
| `role_id` | `string` | — | Short role id within the parent, e.g. `MyCustomRole` or `example_viewer`; must not contain hyphens and must not use a `google`/`iam` reserved prefix (API-enforced; shape-validated here). Immutable — changing it creates a new role. |
| `title` | `string` | — | Human-readable role title; up to 100 characters (validated). |
| `description` | `string` | — | Human-readable description. |
| `permissions` | `list(string)` | — | Permissions like `storage.buckets.get`. Must already exist in GCP; the API rejects unknown permissions at apply (shape-validated here only). |
| `stage` | `string` | — | One of `EAP`, `ALPHA`, `BETA`, `GA`, `DEPRECATED`, `DISABLED` (case-sensitive). `DISABLED` disables the role. |

### `project_roles` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | Project the role lives in; defaults to the provider-level project. Format validated. |
| `role_id` | `string` | — | As `organization_roles.role_id`. |
| `title` | `string` | — | As `organization_roles.title`. |
| `description` | `string` | — | As `organization_roles.description`. |
| `permissions` | `list(string)` | — | As `organization_roles.permissions`. |
| `stage` | `string` | — | As `organization_roles.stage`. |

## Outputs

`organization_role_names` — map of organization role key => full role name
(`organizations/<org_id>/roles/<role_id>`) to reference in IAM bindings.
`project_role_names` — map of project role key => full role name
(`projects/<project>/roles/<role_id>`).

## Example

```hcl
organization_roles = {
  "viewer" = {
    org_id  = "123456789012"
    role_id = "exampleViewer"
    title   = "Example Viewer"
    stage   = "GA"
    permissions = [
      "storage.buckets.get",
      "storage.objects.list",
    ]
  }
}

project_roles = {
  "deployer" = {
    role_id = "exampleDeployer"
    title   = "Example Deployer"
    permissions = [
      "run.services.get",
      "run.services.update",
    ]
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names.
- Permission changes update the role in place; `role_id` is immutable —
  changing it creates a new role and the old one becomes orphaned.
- Bind roles with `gcp/organization-iam` or `gcp/folder-iam`
  (organization-level) / `gcp/project-iam` (project-level) referencing the
  full role names from the outputs — bindings need the full
  `projects/<project>/roles/<role_id>` form, not the id.
- Deleted custom roles stay soft-deleted for 7 days, during which the
  `role_id` cannot be reused (undelete support is out of scope here).
- Enabling the APIs that own the permissions (`storage.googleapis.com`,
  …) with `gcp/project-services` may be needed before the API accepts them.

## Import

`google_organization_iam_custom_role` ←
`organizations/{org_id}/roles/{role_id}`.
`google_project_iam_custom_role` ←
`projects/{project}/roles/{role_id}` (also the bare `{role_id}`).
