# cloudflare/workers-kv

Map-keyed module for Cloudflare Workers KV namespaces. Key/value content
stays out of scope — namespaces are the infrastructure-shaped layer; the
values inside them are runtime data written by Workers and applications,
not Terraform resources.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `account_id` | `string` | `""` | Fallback account ID used when a namespace omits its own. |
| `namespaces` | `map(object)` | — | Map of namespaces keyed by an arbitrary unique ID. |

### `namespaces` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `title` | `string` | — | Human-readable namespace name. Editable in place. |
| `account_id` | `string` | — | Per-namespace account ID; falls back to `var.account_id`. Immutable; changing forces replacement. |
| `jurisdiction` | `string` | — | Durability jurisdiction: `eu`, `fedramp`, or `us`. Creation-time only — editing forces replacement. Requires provider >= 5.25.0. |
| `mode` | `string` | — | Set `instant` for a KV Instant namespace, omit for a classic one. Editing forces replacement. Requires provider >= 5.28.0. |

## Outputs

`namespace_ids` — map of namespace key => namespace ID.
`namespace_titles` — map of namespace key => namespace title.

## Example

```hcl
account_id = "023e105f4ecef8ad9ca31a8372d0c353"

namespaces = {
  "sessions" = {
    title = "example-sessions"
  }
  "eu-data" = {
    title        = "example-sessions-eu"
    jurisdiction = "eu"
  }
}
```

Wire the namespace into a Worker with `cloudflare/workers_script` bindings
or `cloudflare/pages` `kv_namespaces` bindings by key:

```hcl
dependency "kv" {
  config_path = "../kv"
}

# in workers_script bindings:
#   kv_namespaces = { "SESSIONS" = { namespace_id = dependency.kv.outputs.namespace_ids["sessions"] } }
```

## Notes

- This module uses the `required_providers` repo-wide `>= 5.0.0` floor,
  but `jurisdiction` only exists from provider v5.25.0 and `mode` from
  v5.28.0 — consumers pinned below those get "unsupported attribute".
  The module was researched against 5.28.0.
- Keys are arbitrary unique identifiers, not namespace titles.
- Terraform-managed key/value pairs (`cloudflare_workers_kv`) are
  deliberately not exposed: KV is high-churn runtime data, values would
  land in plaintext in Terraform state, and the KV write API is
  rate-limited. Manage namespace content from the application runtime
  or wrangler.
- `jurisdiction` and `mode` are both creation-time only — editing either
  forces destroy and recreate of the namespace (and any keys in it are
  lost, since keys are not managed here anyway).
- Namespace deletion removes the namespace and all keys in it.

## Import

`cloudflare_workers_kv_namespace` ← `<account_id>/<namespace_id>`, e.g.
`023e105f4ecef8ad9ca31a8372d0c353/5ebe363c0f2b4e0d8f8c3a3b0a1b2c3d`.
