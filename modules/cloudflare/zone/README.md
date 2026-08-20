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
| `settings` | `map(string)` | `{}` | Setting ID => value (e.g. `{ min_tls_version = "1.2" }`). |

## Outputs

`zone_ids`, `zone_names`, `zone_statuses`, `zone_name_servers` — all keyed by
zone name.

## Settings scope

`settings` is typed `map(string)`. This covers scalar settings like
`min_tls_version`. Dynamic/non-string settings (`browser_cache_ttl`,
`ciphers`, `security_header`) are out of scope for this module; widen the
input type if you need them.

## Import

- `cloudflare_zone` ← `<zone_id>`
- `cloudflare_zone_setting` ← `<zone_id>/<setting_id>`

## Example

```hcl
account_id = "abcd1234"

zones = {
  "example.com" = {
    settings = {
      min_tls_version = "1.2"
    }
  }
}
```
