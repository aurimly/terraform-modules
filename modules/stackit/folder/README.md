# stackit/folder

Map-keyed module for STACKIT Resource Manager folders under an
organization or a parent folder.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `folders` | `map(object)` | — | Map of folders keyed by an arbitrary unique ID. |

### `folders` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Folder name; validated client-side against the API rule: ≤40 chars, starts with a letter or number (umlauts allowed), contains only letters, numbers, umlauts, `ß`, single spaces, underscores, `+`, `&`, hyphens. No dots. |
| `owner_email` | `string` | — | Email of the folder owner, assigned as the folder's owner member at creation. Must be a user account, not a service account. Create-only: changing it later shows a one-time no-op plan diff (state syncs on apply) but does not change the owner upstream. |
| `parent_container_id` | `string` | — | Parent container: the organization's or parent folder's user-friendly container ID or UUID. |
| `labels` | `map(string)` | `{}` | Labels attached to the folder. Keys must match `[A-ZÄÜÖa-zäüöß0-9_-]{1,64}`, values `^$|[A-ZÄÜÖa-zäüöß0-9_-]{1,64}` (empty allowed), at most 100 per folder. Organization policies may enforce additional label restrictions. |

## Outputs

`folders` — map of folder key => object:

| Attribute | Description |
|---|---|
| `container_id` | Folder container ID; usable directly as the `parent_container_id` of another folder or a project. |
| `folder_id` | Folder UUID identifier. |

## Example

```hcl
folders = {
  "team-a" = {
    name                = "team-a"
    owner_email         = "team-owner@example.com"
    parent_container_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  }
  "team-a-prod" = {
    name                = "prod"
    owner_email         = "team-owner@example.com"
    parent_container_id = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
    labels = {
      "env" = "prod"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not folder names. The key
  disambiguates entries reusing the same naming across branches
  (e.g. `prod`, `npd-prod`).
- The name validation mirrors the STACKIT API rule; the provider itself
  only enforces 1–63 characters, so invalid names fail at plan time
  instead of apply.
- `owner_email` is sent to the API as the folder's owner member and is
  only considered at creation. Changing it later produces a one-time
  no-op diff — the provider does not send it on update, and state syncs
  to the config value after apply. The upstream owner can only be changed
  outside this module. The owner must be a user account; a service
  account email is rejected upstream.
- Renames, label changes, and moving a folder to another parent are all
  in-place updates — nothing in this resource forces replacement.
- No upstream deletion protection exists for STACKIT folders: `destroy`
  deletes the folders immediately, so use Terragrunt- or pipeline-level
  safeguards if that is unwanted. A deleted project stays hidden for up
  to 7 days, during which deleting its parent folder fails.
- Nested folders and projects are created by passing this module's
  `container_id` output as the `parent_container_id` of a dependent unit
  (Terragrunt `dependency`).
- The runner creating folders needs the `resource-manager.folder.create`
  permission on the parent organization or folder (included in the Owner
  role). Provider authentication (service account key flow) is configured
  at the consumer's root level.
- The provider floor `>= 0.66.0` is the version that introduced
  `stackit_resourcemanager_folder`; labels and folder moves are supported
  from that version on.

## Import

`stackit_resourcemanager_folder` ← `{container_id}` or the folder UUID

After import, the configuration must set `owner_email` (required
attribute) — resolve the resulting plan conflict manually by matching the
folder's actual owner. The first plan after import may also show a
one-time `parent_container_id` diff: state normalizes the parent to the
user-friendly container ID form.
