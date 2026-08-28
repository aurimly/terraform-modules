# cloudflare/zone

Map-keyed module for Cloudflare zones and granular zone settings.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `account_id` | `string` | `""` | Fallback account ID used when a zone omits its own. |
| `zones` | `map(object)` | — | Map of zones keyed by zone name. |

### `zones` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `account_id` | `string` | — | Per-zone account ID; falls back to `var.account_id`. |
| `type` | `string` | `"full"` | Zone type (`full`, `partial`, ...). |
| `paused` | `bool` | `false` | Pause Cloudflare on this zone. |
| `settings` | `map(string)` | `{}` | Setting ID => string value (e.g. `{ min_tls_version = "1.2" }`). Passed to the API verbatim. |
| `typed_settings` | `map(string)` | `{}` | Setting ID => JSON-encoded value for numeric, array and object settings (e.g. `{ browser_cache_ttl = jsonencode(14400) }`). Decoded by the module before being sent to the API. A setting ID must not appear in both maps. |

## Outputs

`zone_ids`, `zone_names`, `zone_statuses`, `zone_name_servers` — all keyed by
zone name.

## Settings scope

`cloudflare_zone_setting.value` accepts a string, number, array or object
depending on the setting (the provider's docs list the value type per
setting ID). Terraform's type system cannot express a map with
per-key value types, so the split is:

- `settings` — raw string values, passed to the API verbatim. Covers the
  majority of settings: `on`/`off` flags, enum strings (`cache_level`,
  `min_tls_version`, ...).
- `typed_settings` — values built with `jsonencode()`, decoded back to the
  native JSON type by the module. Covers numeric settings
  (`browser_cache_ttl`, `challenge_ttl`, `max_upload`), array settings
  (`ciphers`) and object settings (`security_header`, `nel`, `aegis`,
  `automatic_platform_optimization`).

Passing a number as a raw string (e.g. `settings = { browser_cache_ttl =
"14400" }`) is not equivalent — the API stores the value with its real
JSON type and a string would diff forever. Use `typed_settings` for
anything non-string.

## Import

- `cloudflare_zone` ← `<zone_id>`
- `cloudflare_zone_setting` ← `<zone_id>/<setting_id>`

## Example

```hcl
account_id = "abcd1234"

zones = {
  "example.com" = {
    settings = {
      min_tls_version  = "1.2"
      always_use_https = "on"
    }
    typed_settings = {
      browser_cache_ttl = jsonencode(14400)
      ciphers = jsonencode([
        "ECDHE-ECDSA-AES128-GCM-SHA256",
        "ECDHE-ECDSA-CHACHA20-POLY1305",
      ])
      security_header = jsonencode({
        strict_transport_security = {
          enabled            = true
          include_subdomains = true
          max_age            = 86400
          nosniff            = true
        }
      })
    }
  }
}
```
