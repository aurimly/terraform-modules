# ns1/zone

Map-keyed module for NS1 zones. Supports primary zones, zone linking,
secondary transfers, DNSSEC, and an optional set of custom primaries that
get matching apex NS records created.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `zones` | `map(object)` | — | Map of zones keyed by zone name. |

### `zones` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `ttl` | `number` | `3600` | Default TTL for NS records. The module enforces this; the provider itself lets the API decide when omitted. |
| `tags` | `map(string)` | `{}` | Free-form tags. |
| `link` | `string` | — | Name of the zone to link this zone to. ForceNew. |
| `primary` | `string` | — | Address of the primary name server (makes the zone secondary). Conflicts with `additional_primaries` and `secondaries`. |
| `primary_port` | `number` | — | Port of the primary nameserver. |
| `primary_network` | `number` | — | Network ID the primary lives on. |
| `additional_primaries` | `list(string)` | — | Addresses of additional primaries. Conflicts with `primary` and `secondaries`. |
| `additional_ports` | `list(number)` | — | Ports for the additional primaries. |
| `additional_networks` | `list(number)` | — | Network IDs for the additional primaries. |
| `additional_notify_only` | `list(bool)` | — | Whether each additional primary is notify-only. |
| `hostmaster` | `string` | — | Hostmaster address of the SOA record. |
| `refresh` | `number` | — | SOA refresh. Conflicts with `primary` / `additional_primaries`. |
| `retry` | `number` | — | SOA retry. Conflicts with `primary` / `additional_primaries`. |
| `expiry` | `number` | — | SOA expiry. Conflicts with `primary` / `additional_primaries`. |
| `nx_ttl` | `number` | — | SOA NX TTL. Conflicts with `primary` / `additional_primaries`. |
| `dnssec` | `bool` | — | Enable DNSSEC. The account must have DNSSEC enabled by NS1 support first. |
| `autogenerate_ns_record` | `bool` | `true` | Autogenerate the NS record on creation. Only effective at create time; imports force it to `true`. |
| `networks` | `set(number)` | — | Network IDs the zone is available on. |
| `secondaries` | `list(object)` | `[]` | Secondary servers allowed to transfer/notify. Conflicts with `primary` / `additional_primaries`. |
| `tsig` | `map(string)` | — | TSIG keys for outgoing transfers: `name`, `hash` (`hmac-sha256`, ...), `key`, `enabled`, `signed_notifies` (`enabled`/`signed_notifies` are bools passed as strings, e.g. `"true"`). Only applies when `primary` is set. |
| `custom_primaries` | `list(string)` | `[]` | Names of upstream primaries. Module-local: for each, an apex `NS` record is created in the zone. |

### `secondaries` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `ip` | `string` | — | Secondary server IP. |
| `port` | `number` | `53` | Secondary server port. |
| `notify` | `bool` | `false` | Whether the secondary receives notifications. |

At most one of `primary`, `additional_primaries`, `secondaries` may be set
per zone (validated in the module; the provider enforces it too).

## Outputs

| Name | Description |
|---|---|
| `zone_ids` | Map of zone name => zone ID. |
| `zone_name_servers` | Map of zone name => list of nameserver hostnames assigned to the zone. |
| `zone_dnssec_states` | Map of zone name => DNSSEC state. |
| `zone_hostmasters` | Map of zone name => hostmaster address. |
| `primary_ns_record_fqdns` | Map of `<zone>/<domain>` => FQDN of the NS records created for custom primaries. |

## Operational notes

- Setting `primary` on a zone that was created without it forces a
  recreate. Switching back and forth between primary and secondary can
  strand records; plan such changes carefully.
- `tsig` has no effect unless `primary` is set.
- `custom_primaries` creates the apex `NS` records automatically; do not
  also manage them via `ns1/record` — that would duplicate them.

## Import

- `ns1_zone` ← `<zone>` (the zone name). Note: importing sets
  `autogenerate_ns_record = true` in state regardless of the prior value.

## Example

```hcl
zones = {
  "example.io" = {
    dnssec = true
    tags = {
      owner = "netops"
    }
  }
  "example.eu" = {
    primary = "1.2.3.4"
    tsig = {
      name    = "mykey"
      hash    = "hmac-sha256"
      key     = "REDACTED"
      enabled = "true"
    }
  }
  "example.net" = {
    custom_primaries = ["example.io"]
    ttl              = 60
  }
}
```
