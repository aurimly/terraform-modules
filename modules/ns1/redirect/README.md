# ns1/redirect

Map-keyed module for NS1 URL redirection (HTTP redirects on domains served
by NS1).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `redirects` | `map(object)` | — | Map of redirects keyed by an arbitrary unique identifier. The domain/path pair must be unique within the NS1 account. |

### `redirects` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `domain` | `string` | — | FQDN served by NS1 to redirect. ForceNew. |
| `target` | `string` | — | URL to redirect to. |
| `path` | `string` | `"/"` | Path to redirect from; the provider has no default so the module always applies one. |
| `forwarding_type` | `string` | `"permanent"` | one of `permanent` (301), `temporary` (302), `masking`. |
| `forwarding_mode` | `string` | `"all"` | URI forwarding mode: one of `all`, `capture`, `none`. |
| `https_forced` | `bool` | `false` | Redirect HTTP to HTTPS before forwarding. |
| `query_forwarding` | `bool` | `false` | Forward query strings to the target. |
| `tags` | `set(string)` | `[]` | Tags. Note this is a set of strings on redirects, not a map like on zones and records. |
| `certificate_id` | `string` | — | HTTP certificate ID. |

## Outputs

| Name | Description |
|---|---|
| `redirect_ids` | Map of redirect key => redirect UUID. |
| `redirect_targets` | Map of redirect key => target URL. |

## Import

- `ns1_redirect` ← `<uuid>`. UUIDs are listed by `GET /v1/redirect`, which
  returns at most 50 per page with an `after` cursor for pagination.

## Example

```hcl
redirects = {
  "home" = {
    domain            = "example.io"
    target            = "https://example.com"
    https_forced      = true
    query_forwarding  = true
  }
  "inflight" = {
    domain           = "inflight.example.io"
    path             = "/"
    target           = "https://example.com/inflight"
    forwarding_type  = "temporary"
    forwarding_mode  = "all"
    tags             = ["team:netops"]
  }
}
```
