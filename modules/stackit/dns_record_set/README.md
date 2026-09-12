# stackit/dns_record_set

Map-keyed module for STACKIT DNS record sets inside an existing DNS zone
(see stackit/dns_zone).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `record_sets` | `map(object)` | — | Map of record sets keyed by an arbitrary unique ID. |

### `record_sets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the record set is created in (validated). Changing it replaces the record set. |
| `zone_id` | `string` | — | UUID of the zone the record set lives in (e.g. from stackit/dns_zone's `zones` output, validated). Changing it replaces the record set. |
| `name` | `string` | — | Record name relative to the zone (e.g. `www`, `@` for the zone apex). |
| `type` | `string` | — | Record set type (e.g. `A`, `AAAA`, `CNAME`, `MX`, `TXT`). Passed through as-is; see the type note below. Changing it replaces the record set. |
| `records` | `list(string)` | — | Record values, at least one and no duplicates (validated). Content is validated per type for `A` (IPv4), `AAAA` (IPv6) and `CNAME` (FQDN ending in a dot) at plan time (mirrors the provider). |
| `ttl` | `number` | `null` | Time to live in seconds, 60–99999999 (validated). Updates in place. |
| `active` | `bool` | API default (`true`) | Whether the record set is active. Updates in place. |
| `comment` | `string` | `null` | Comment, at most 255 characters (validated). Updates in place. |

## Outputs

`record_sets` — map of record set key => object:

| Attribute | Description |
|---|---|
| `record_set_id` | Record set UUID. |
| `fqdn` | Fully qualified domain name of the record set. |
| `state` | Record set state — the API is eventually consistent, so this exposes propagation status. |
| `error` | Error message when create/update/delete failed. |
| `id` | `"{project_id},{zone_id},{record_set_id}"` — the import ID. |

## Example

```hcl
module "dns_record_set" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/dns_record_set?ref=v1.3.0"

  record_sets = {
    "apex" = {
      project_id = "12345678-1234-1234-1234-123456789012"
      zone_id    = module.dns_zone.zones["public"].zone_id
      name       = "@"
      type       = "A"
      records    = ["192.0.2.10", "192.0.2.11"]
      ttl        = 3600
    }
    "www" = {
      project_id = "12345678-1234-1234-1234-123456789012"
      zone_id    = module.dns_zone.zones["public"].zone_id
      name       = "www"
      type       = "CNAME"
      records    = ["example.org."]
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not names — multiple entries may
  share a `name` (e.g. several record sets named `@`) as long as they
  target different zones.
- `type` is replace-on-change: changing it destroys and recreates the
  record set, a brief outage window for that name.
- The `type` set is open: the provider validates record content only for
  `A` (IPv4), `AAAA` (IPv6) and `CNAME` (trailing-dot FQDN) — mirrored at
  plan time here — and passes every other type string (e.g. `NS`, `MX`,
  `TXT`, `CAA`, `SRV`) through to the API, which may still reject unknown
  or malformed values at apply.
- Renaming a map key destroys and recreates the record set.
- Plan-time validations mirror the provider's plan-time validators
  (UUIDs, record count/uniqueness, per-type content, TTL bound, comment
  length).
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_dns_record_set` ← `{project_id},{zone_id},{record_set_id}`
