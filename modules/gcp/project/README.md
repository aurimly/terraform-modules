# gcp/project

Map-keyed module for Google Cloud projects under an organization or a
folder.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `projects` | `map(object)` | — | Map of projects keyed by an arbitrary unique ID. |

### `projects` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Project display name; 4–30 chars, letters/digits/spaces/hyphens/single-quote/double-quote/exclamation. Validated client-side. |
| `project_id` | `string` | — | Globally unique project ID; 6–30 lowercase letters/digits/hyphens, must start with a letter, no trailing hyphen. Immutable; changing forces replacement. Validated client-side. |
| `org_id` | `string` | — | Bare numeric organization ID. Mutually exclusive with `folder_id` (XOR enforced). Format validated. |
| `folder_id` | `string` | — | Bare numeric folder ID or `folders/<folder_id>`. Mutually exclusive with `org_id` (XOR enforced). Format validated. |
| `billing_account` | `string` | — | Billing account ID in the form `XXXXXX-XXXXXX-XXXXXX` (uppercase letters and digits). Format validated. |
| `auto_create_network` | `bool` | `false` | Controls the default network. Default `false` (provider default is `true`); see Notes. |
| `deletion_policy` | `string` | `PREVENT` | One of `PREVENT`, `ABANDON`, `DELETE` (case-sensitive). Matches the provider default. |
| `labels` | `map(string)` | `{}` | Resource labels. Keys `^[a-z][a-z0-9_-]{0,62}$`, values `^[a-z0-9_-]{0,63}$` (validated, following the v1 REST reference). Non-authoritative — see Notes. |
| `tags` | `map(string)` | `{}` | Resource manager tags, namespaced form `"{parent_id}/{tag_key_short_name}" = "{tag_value_short_name}"`. Immutable; forces replacement — see Notes. |

## Outputs

`project_ids` — map of project key => the user-defined `project_id` string.
`project_numbers` — map of project key => GCP-generated numeric project number.
`project_names` — map of project key => display name.

## Example

```hcl
projects = {
  "team-a" = {
    name            = "Team A"
    project_id      = "team-a-prod-1234"
    org_id          = "123456789012"
    billing_account = "01AB23-CD45EF-67GH89"
    labels = {
      env = "prod"
    }
  }
  "team-a-prod" = {
    name            = "prod"
    project_id      = "team-a-prod-9876"
    folder_id       = "folders/987654321098"
    billing_account = "01AB23-CD45EF-67GH89"
    deletion_policy = "DELETE"
    tags = {
      "123456789012/env" = "prod"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not project IDs or names. The key
  disambiguates entries that might share a display name.
- `project_id` validation mirrors the GCP REST rule (6–30 lowercase
  letters/digits/hyphens, start with a letter, no trailing hyphen). Restricted
  substrings (`google`, `ssl`) and global uniqueness are enforced server-side
  and are not checked here.
- `name` validation follows the v1 REST reference: 4–30 chars, ASCII
  letters/digits plus space, hyphen, single-quote, double-quote and
  exclamation point. It is intentionally not the `gcp/folder` `display_name`
  regex — the two resources have different documented char sets.
- Parent is mandatory and mutually exclusive: each entry must set exactly one
  of `org_id` or `folder_id` (XOR enforced). The provider would also accept a
  parentless project; this module does not. `org_id` is sent to the API as-is
  (no prefix stripping), so pass the bare numeric ID; `folder_id` accepts both
  the bare ID and `folders/<id>` (the folder module's `name` output and
  `folder_id` output respectively). Changing the parent on an existing project
  does not replace it — the provider migrates the project to the newly
  specified organization or folder.
- `billing_account` is required here even though the provider marks it
  optional — a platform guardrail. The `XXXXXX-XXXXXX-XXXXXX` format is
  inferred from Google's examples (no formal regex is documented; the provider
  does no client-side validation). The provider pre-checks
  `billing.resourceAssociations.create` on the account at create time and reads
  it on every plan/apply, so the caller needs `roles/billing.user` on it.
- `auto_create_network` defaults to `false` (the provider default is `true`).
  The false default only deletes the default network at create time; the
  update path ignores the field. The recommended mechanism for suppressing the
  default network is the `constraints/compute.skipDefaultNetworkCreation`
  org policy, not this flag. Importing an existing project sets this field to
  `true` in state, producing a one-time cosmetic diff against the module
  default.
- `deletion_policy`: `PREVENT` (default) blocks any destroy; `DELETE`
  soft-deletes the project (it can be undeleted for ~30 days); `ABANDON`
  removes the resource from state without touching GCP.
- `labels` is non-authoritative: Terraform only manages labels present in
  configuration; labels added out-of-band are preserved but not visible
  here. Up to 256 labels per resource.
- `tags` use the namespaced form `"{parent_id}/{tag_key_short_name}" =
  "{tag_value_short_name}"` (e.g. `"123456789012/env" = "prod"`), as used in
  the provider's own examples and acceptance tests. The provider's argument
  description mentions a `tagKeys/{id}` / `tagValues/{id}` form, but that
  contradicts its own examples and tests and is not enforced here. Tags are
  set only at create time and are never read back; mutating them forces
  resource replacement, which the default `deletion_policy = "PREVENT"` then
  blocks. Tag bindings may linger after a project is scheduled for deletion.

## Import

`google_project` ← `{{project_id}}` (the user-defined project ID string, not
the numeric project number — the provider rejects the number).
