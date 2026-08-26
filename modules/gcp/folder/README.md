# gcp/folder

Map-keyed module for Google Cloud folders under an organization or a
parent folder.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `folders` | `map(object)` | — | Map of folders keyed by an arbitrary unique ID. |

### `folders` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `display_name` | `string` | — | Folder display name; must be unique among sibling folders. Validated client-side: ≤30 chars, starts/ends with a letter or number, contains only letters, numbers, spaces, hyphens, underscores. |
| `parent` | `string` | — | Parent resource: `organizations/{org_id}` or `folders/{folder_id}`. Format validated. |
| `tags` | `map(string)` | `{}` | Resource manager tags, namespaced form `"{parent_id}/{tag_key_short_name}" = "{tag_value_short_name}"`, the parent being the org or project where the tag key is defined. Immutable upstream — changing tags forces folder replacement. |
| `deletion_protection` | `bool` | `true` | Prevents Terraform from destroying **or recreating** the folder. Combined with tags being immutable upstream, a tags change under the default forces a blocked replacement. |
| `deletion_policy` | `string` | `PREVENT` | One of `PREVENT`, `DELETE`, `ABANDON`. Stricter than the provider default (`DELETE`), matching this repo's project module. |

## Outputs

`folders` — map of folder key => object:

| Attribute | Description |
|---|---|
| `name` | Full resource name (`folders/<id>`); usable directly as the `parent` of another folder entry or a project. |
| `folder_id` | Bare numeric ID without the prefix. |

## Example

```hcl
folders = {
  "team-a" = {
    display_name = "Team A"
    parent       = "organizations/123456789012"
  }
  "team-a-prod" = {
    display_name        = "prod"
    parent              = "folders/987654321098"
    deletion_policy     = "DELETE"
    deletion_protection = false
    tags = {
      "123456789012/env" = "prod"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not folder names. Display names
  only need to be unique within the same parent, so the key disambiguates
  siblings with shared naming across branches (e.g. `prod`, `npd-prod`).
- The display_name validation mirrors the GCP API rule using Unicode
  letter/number classes, so non-ASCII names (e.g. `Ürünler`) pass.
- Deletion guards run in order: `deletion_policy` first, then
  `deletion_protection`. With the defaults (`PREVENT` + `true`) destroy is
  blocked outright, and so is any change that forces recreation. To let
  Terraform delete a folder, set `deletion_policy = "DELETE"` and
  `deletion_protection = false`. `ABANDON` removes the folder from state
  without touching it in GCP and bypasses `deletion_protection` entirely.
- Tags use the namespaced form `"{parent_id}/{tag_key_short_name}" =
  "{tag_value_short_name}"` — parent being the org or project where the tag
  key is defined — matching the provider's own examples and the Resource
  Manager v3 API reference. The provider's argument description instead
  mentions a `tagKeys/{id}` / `tagValues/{id}` form, which contradicts its
  examples and tests; no client-side format validation is applied here. Tags
  are create-time only and never read back; changing them forces folder
  replacement (see the deletion-guards note above).
- Tag bindings may linger for a while after a folder is scheduled for
  deletion; don't recreate same-named tag bindings immediately.
- Nested folders are supported by referencing this module's own output as
  the parent of a dependent unit (Terragrunt `dependency`).
- The runner creating folders must hold `roles/resourcemanager.folderCreator`
  on the parent organization — mirroring the `roles/billing.user` prerequisite
  documented in the `gcp/project` module.

## Import

`google_folder` ← `folders/{folder_id}` or bare `{folder_id}`
