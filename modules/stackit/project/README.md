# stackit/project

Map-keyed module for STACKIT Resource Manager projects under an
organization or a folder.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `projects` | `map(object)` | — | Map of projects keyed by an arbitrary unique ID. |

### `projects` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Project name; validated client-side against the API rule: starts with a letter or number (umlauts allowed), contains only letters, numbers, umlauts, `ß`, single spaces, underscores, `+`, `&`, hyphens. No dots. Project names do not need to be unique under the same parent. |
| `owner_email` | `string` | — | Email of the project owner, assigned as the project's owner member at creation. Must be a user account, not a service account. Create-only: changing it later shows a one-time no-op plan diff (state syncs on apply) but does not change the owner upstream. |
| `parent_container_id` | `string` | — | Parent container: the organization's or parent folder's user-friendly container ID or UUID. A project cannot have another project as parent. |
| `labels` | `map(string)` | `{}` | Labels attached to the project. Keys must match `[A-ZÄÜÖa-zäüöß0-9_-]{1,64}`, values `^$|[A-ZÄÜÖa-zäüöß0-9_-]{1,64}` (empty allowed), at most 100 per project. Organization policies may enforce additional label restrictions. Special labels: `networkArea` (see Notes) and `billingReference` for attaching a billing reference. |

## Outputs

`projects` — map of project key => object:

| Attribute | Description |
|---|---|
| `container_id` | Project container ID; the project's user-friendly identifier, also used as the import ID. A project is a leaf container — folders and projects cannot be created under it. |
| `project_id` | Project UUID identifier; this is the ID most other STACKIT resources expect. |

## Example

```hcl
projects = {
  "app-prod" = {
    name                = "prod"
    owner_email         = "team-owner@example.com"
    parent_container_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  }
  "app-npd" = {
    name                = "npd"
    owner_email         = "team-owner@example.com"
    parent_container_id = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
    labels = {
      "env"              = "npd"
      "billingReference" = "ref-12345"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not project names. The key
  disambiguates entries reusing the same naming across stages
  (e.g. `prod`, `npd-prod`).
- The name validation mirrors the STACKIT API rule; the provider itself
  only enforces 1–63 characters, so invalid names fail at plan time
  instead of apply.
- `owner_email` is sent to the API as the project's owner member and is
  only considered at creation. Changing it later produces a one-time
  no-op diff — the provider does not send it on update, and state syncs
  to the config value after apply. The upstream owner can only be changed
  outside this module. The owner must be a user account; a service
  account email is rejected upstream.
- The `networkArea` label (`<networkAreaID>`) is required to create a
  project inside a STACKIT Network Area and is immutable afterwards —
  changing or removing it in the config produces a plan diff whose apply
  the API rejects, so the diff persists until the config is reverted.
- The API requires either a `networkArea` label or a `scope=PUBLIC`
  label for project creation (see the Resource Manager API docs);
  configs without either fail at apply.
- Renames, label changes, and moving a project to another parent are all
  in-place updates — nothing in this resource forces replacement.
- No upstream deletion protection exists for STACKIT projects: `destroy`
  deletes the projects immediately, so use Terragrunt- or pipeline-level
  safeguards if that is unwanted. A deleted project stays hidden for up
  to 7 days, during which deleting its parent folder fails.
- Projects are created under an organization or a folder by passing that
  container's ID as `parent_container_id` (Terragrunt `dependency` on
  `stackit/folder`'s `container_id` output, or the organization ID).
- The runner creating projects needs the `resource-manager.project.create`
  permission on the parent organization or folder (included in the Owner
  role). Provider authentication (service account key flow) is configured
  at the consumer's root level.
- The provider floor `>= 0.66.0` matches the `stackit/folder` module so
  both resources behave identically when consumed together; the project
  resource itself predates that version.

## Import

`stackit_resourcemanager_project` ← `{container_id}` or the project UUID

After import, the configuration must set `owner_email` (required
attribute) — resolve the resulting plan conflict manually by matching the
project's actual owner. After import, state holds the parent in the
user-friendly container-ID form, so a container-ID-form config plans
clean, while a UUID-form config shows a one-time `parent_container_id`
diff — state keeps the UUID form after apply.
