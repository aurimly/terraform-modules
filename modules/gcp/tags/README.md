# gcp/tags

Map-keyed module for Google Cloud resource-manager tags: tag keys under an
organization or a project, and tag values under those keys. Each entry in
`tag_keys` creates one `google_tags_tag_key`; each entry in `tag_values`
creates one `google_tags_tag_value` under the referenced key.

The parent is per-entry and required — keys may span parents (an
organization key and a project key in one module), and the parent
determines the key's namespace, so there is no module-level fallback.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `tag_keys` | `map(object)` | — | Map of tag keys keyed by an arbitrary unique ID. |
| `tag_values` | `map(object)` | — | Map of tag values keyed by an arbitrary unique ID; `key` wires each value to a key entry. |

Plan-time validation: `parent` is `organizations/{numeric id}` or
`projects/{project id or number}` (folders are not valid parents
upstream); `short_name` is at most 256 characters without single quotes,
double quotes, backslashes or forward slashes and unique within its
parent; `description` is at most 256 characters; `purpose` is
`GCE_FIREWALL`/`DATA_GOVERNANCE` and `purpose_data` requires it; value
`key` references a `tag_keys` entry; `deletion_policy` is
`DELETE`/`ABANDON`/`PREVENT`.

### `tag_keys` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `parent` | `string` | — | `organizations/{numeric id}` or `projects/{project id or number}`. |
| `short_name` | `string` | — | User-friendly key name, unique within the parent. Input-only — changing it replaces the key. |
| `description` | `string` | `null` | At most 256 characters. |
| `purpose` | `string` | `null` | `GCE_FIREWALL` or `DATA_GOVERNANCE`. Immutable once set. |
| `purpose_data` | `map(string)` | `null` | Policy-system data as a map, e.g. `{ network = "<project-name>/<vpc-name>" }` for `GCE_FIREWALL`. Immutable once set. |
| `allowed_values_regex` | `string` | `null` | RE2 constraint for dynamic tag values; its presence enables dynamic values. |
| `deletion_policy` | `string` | `DELETE` | `DELETE`, `ABANDON` or `PREVENT`. |

### `tag_values` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `key` | `string` | — | Key of a `tag_keys` entry; the value is created under that key. |
| `short_name` | `string` | — | Value name, unique within its key. Input-only — changing it replaces the value. |
| `description` | `string` | `null` | At most 256 characters. |
| `deletion_policy` | `string` | `DELETE` | `DELETE`, `ABANDON` or `PREVENT`. |

## Outputs

| Name | Description |
|---|---|
| `tag_key_ids` | Map of key => `tagKeys/{numeric id}` — what bindings and downstream resources consume. |
| `tag_key_names` | Map of key => generated numeric id. |
| `tag_key_namespaced_names` | Map of key => `{parent namespace}/{short_name}`. |
| `tag_value_ids` | Map of value key => `tagValues/{numeric id}` — what `google_tags_tag_binding` and tag policy inputs consume. |
| `tag_value_names` | Map of value key => generated numeric id. |
| `tag_value_namespaced_names` | Map of value key => `{parent namespace}/{tag key short_name}/{short_name}`. |

## Example

```hcl
tag_keys = {
  "env" = {
    parent     = "organizations/123456789012"
    short_name = "environment"
  }
  "network" = {
    parent       = "organizations/123456789012"
    short_name   = "network"
    purpose      = "GCE_FIREWALL"
    purpose_data = { network = "example-prj/example-vpc" }
  }
}

tag_values = {
  "prod" = {
    key        = "env"
    short_name = "production"
  }
  "staging" = {
    key        = "env"
    short_name = "staging"
  }
}
```

## Notes

- `purpose` and `purpose_data` are immutable once set; changing them
  requires recreating the key.
- `short_name` and `parent` are input-only; a change replaces the key (or
  value). With the default `deletion_policy = DELETE` the old resource is
  destroyed — a tag key in use is rejected by the API until its values
  and bindings are gone.
- Deletion order matters: delete values before their key (the API refuses
  to delete a key that still has values).
- Tag bindings (`google_tags_tag_binding`) are a separate resource, not
  managed here — consume `tag_value_ids` for them.
- The caller needs resourcemanager tag permissions on the parent
  (`tags.tagKeys/create`, `tags.tagValues/create`, …).

## Import

`google_tags_tag_key` ← `tagKeys/{numeric id}` or `{numeric id}`, e.g.
`tagKeys/1234567` or `1234567`.

`google_tags_tag_value` ← `tagValues/{numeric id}` or `{numeric id}`,
e.g. `tagValues/7654321` or `7654321`.
