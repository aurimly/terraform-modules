# aws/route53-records

Map-keyed module for Route 53 resource record sets in one or more hosted
zones: standard records with TTLs and alias records (A/AAAA/CAA), keyed by
an arbitrary identifier, grouped per zone.

## Destroy semantics (read before using)

- Removing a record key deletes the DNS record immediately; resolvers
  keep serving cached values only for the remaining TTL.
- Removing a zone entry (`zones.<key>`) removes **all records of that
  zone entry** including NS/SOA defaults handling on the zone side — the
  Route 53 zone itself keeps its own NS/SOA records.
- Caution: do not delete NS or SOA records of the zone itself unless you
  understand delegation loss.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `zones` | `map(object)` | `{}` | Map of zones with records, keyed by an arbitrary unique ID. |

### `zones` object

| Attribute | Type | Description |
|---|---|---|
| `zone_id` | `string` | Hosted zone ID (starts with `Z`, validated) — feed from `aws/route53-zone` outputs. |
| `records` | `map(object)` | Map of records keyed by an arbitrary unique ID; see the `records` object table. |

### `records` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Record name relative to the zone (Route 53 FQDN-normalizes); use `@`-free naming: empty string is not valid on the API side, use the zone name itself. |
| `type` | `string` | — | Record type: `A`, `AAAA`, `CAA`, `CNAME`, `MX`, `NS`, `PTR`, `SOA`, `SPF`, `SRV`, `TXT`, `DS`, `TLSA`, `SSHFP`, `SVCB`, `HTTPS` (validated). |
| `ttl` | `number` | — | TTL in seconds; required exactly when `records` is set (validated). |
| `records` | `list(string)` | — | Record values — exactly one of `records` or `alias` (validated); at least one value (validated). |
| `alias` | `object` | — | `{name, zone_id, evaluate_target_health}` — alias target (A/AAAA/CAA only). `zone_id` is the **target's** hosted zone ID (aliases to non-Route53 AWS endpoints need the endpoint-specific zone IDs, e.g. S3 website endpoints). |

## Outputs

`record_fqdns` — map of `"zone-key.record-key"` => fully qualified domain
name of the record.

## Example

```hcl
zones = {
  "main" = {
    zone_id = "Z0123456789ABCDEFGHIJ"
    records = {
      "apex-a" = {
        name    = "example.com"
        type    = "A"
        ttl     = 300
        records = ["203.0.113.10"]
      }
      "www" = {
        name = "www.example.com"
        type = "A"
        alias = {
          name                   = "example.com"
          zone_id                = "Z0123456789ABCDEFGHIJ"
          evaluate_target_health = true
        }
      }
      "mx" = {
        name    = "example.com"
        type    = "MX"
        ttl     = 3600
        records = ["10 mail.example.com"]
      }
      "-txt" = {
        name    = "example.com"
        type    = "TXT"
        ttl     = 300
        records = ["\"example-spf\""]
      }
    }
  }
}
```

## Notes

- Keys (zone and record) are arbitrary unique identifiers; the record
  FQDN is what matters to Route 53, not the key.
- Standard and alias records are separate resources internally; a record
  flipping between the two forms is destroyed then recreated (with a
  brief gap).
- TXT values need embedded quotes for strings with spaces (DNS
  presentation format, e.g. `"\"v=spf1 ...\""`).
- Multi-value and weighted/latency/geolocation routing policies are out
  of scope — that is the `aws_route53_record` `routing_policy` block,
  better served by dedicated per-record variables if needed; file an
  issue if you need it.
- Alias evaluation of target health only matters when the target is
  behind a health check or is another alias to one; otherwise the value
  is ignored by Route 53.

## Import

`aws_route53_record` ← `zone-id::record-name::record-type` (e.g.
`Z0123456789ABCDEFGHIJ::www.example.com::A`). Alias targets import like
standard records: alias-specific attributes are read from the zone.
Import into `simple[zone-key.record-key]` or
`alias[zone-key.record-key]` matching the form in your configuration.
