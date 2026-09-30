# azure/dns-records

Map-keyed module for Azure DNS record sets inside an existing zone, public or
private. Each zone entry references its zone (public: `zone_name` +
`resource_group_name` from the `azure/dns-zone` module outputs; private:
`private_dns_zone_id`) and carries its own `records` map, keyed like everything
else in this repo.

Azure has one API resource per record type — the module fans each entry out to
the matching resource internally (9 public types, 7 private types; Azure
Private DNS has no CAA or NS). Record types among each other are independent:
flipping a `type` destroys and recreates the record set.

## Destroy semantics (read before using)

- Removing a record key deletes that record set immediately — resolvers
  only serve stale values for the record's remaining `ttl`.
- Removing a zone entry removes all its records but not the zone itself.
- Records are removed in apply order — no zone lookup fails from here; the
  zone must exist for `zone_name`/`private_dns_zone_id` to resolve.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `zones` | `map(object)` | — | Map of zones keyed by an arbitrary unique ID, each with its `records` map. |

Plan-time validation: `type` is one of the nine supported values, each zone
entry references exactly one zone (public: `zone_name` + `resource_group_name`,
private: `private_dns_zone_id`), map keys contain no `.`, each record takes a
non-empty `name` and a `ttl` (public 1–2147483647 seconds, private 0–2147483647),
`name`+`type` is unique per zone case-insensitively, private entries reject
CAA/NS types and `target_resource_id`, payload attributes of other types are
absent, A values are IPv4 and AAAA values are IPv6, MX/SRV/CAA payload values
respect the provider's ranges, and tags respect the 50-entry / 512-char key /
256-char value limits.

### `zones` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `zone_name` | `string` | `null` | Public zone name (typically `dependency.dns_zone.outputs.zone_names["public"]` with the `azure/dns-zone` module). Set exactly when the zone is public — see `private_dns_zone_id`. |
| `resource_group_name` | `string` | `null` | Resource group hosting the **public** zone. Required when `zone_name` is set. |
| `private_dns_zone_id` | `string` | `null` | Full ARM resource ID of the private zone (typically `dependency.dns_zone.outputs.zone_ids["internal"]`). Set exactly when the zone is private (mutually exclusive with `zone_name`). |
| `records` | `map(object)` | — | Record sets of the zone keyed by an arbitrary unique ID. Keys must not contain `.` — see Notes. |

### `records` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Relative record name — `@` for the zone apex, e.g. `www`, `api`, `@`. Immutable — changing it (or `type`) forces replacement. |
| `type` | `string` | — | `A`, `AAAA`, `CAA`, `CNAME`, `MX`, `NS`, `PTR`, `SRV` or `TXT` (uppercase). CAA and NS are public-zone only (validated). |
| `ttl` | `number` | — | Record TTL in seconds — public 1–2147483647, private 0–2147483647 (validated). |
| `records` | `list(string)` | `null` | Value list for `A`, `AAAA`, `PTR` and `NS`: IPv4 addresses, IPv6 addresses, hostnames or NS targets respectively. Exactly one payload source per record (validated). |
| `record` | `string` | — | `CNAME` target hostname (singular, provider shape). Exactly one payload source per record (validated). |
| `target_resource_id` | `string` | `null` | Alias target — pair `A`/`AAAA`/`CNAME` with an Azure resource (e.g. `azure/public-ip`, `azure/load-balancer`): public zones only, and mutually exclusive with `records`/`record` (validated). |
| `mx` | `list(object)` | `null` | Value blocks for `MX`: `{ preference = 0–65535, exchange = "mail.example.com" }`. |
| `srv` | `list(object)` | `null` | Value blocks for `SRV`: `{ priority = 0–65535, weight = 0–65535, port = 0–65535, target = "..." }` — a leading-dot target aims at the zone apex. |
| `txt` | `list(string)` | `null` | `TXT` values, one string per value — embedded quotes preserved (SPF: `"v=spf1 include:_spf.example.com ~all"` with the inner quotes). |
| `caa` | `list(object)` | `null` | Value blocks for `CAA` (public zones only): `{ flags = 0–255, tag = "issue"|"issuewild"|"iodef"|"contactemail", value = "letsencrypt.org" }`. |
| `tags` | `map(string)` | `{}` | Tags on the record set. The tag set is authoritative per record set. |

## Outputs

| Name | Description |
|---|---|
| `record_fqdns` | Map of `<zone_key>.<record_key>` => record FQDN with the trailing dot the API applies — the `fqdn` attribute. |

## Example

```hcl
zones = {
  "public" = {
    zone_name           = "example.com"
    resource_group_name = "rg-dns-prod"
    records = {
      "apex-a" = {
        name          = "@"
        type          = "A"
        ttl           = 300
        records       = ["203.0.113.10"]
      }
      "lb-alias" = {
        name               = "app"
        type               = "A"
        ttl                = 60
        target_resource_id = "/subscriptions/12345678-1234-5678-9012-123456789012/resourceGroups/rg-platform-prod/providers/Microsoft.Network/publicIPAddresses/pip-example"
      }
      "mail-mx" = {
        name = "@"
        type = "MX"
        ttl  = 3600
        mx = [
          { preference = 10, exchange = "mail.example.com" },
        ]
      }
      "spf" = {
        name = "@"
        type = "TXT"
        ttl  = 3600
        txt  = ["\"v=spf1 include:_spf.example.com ~all\""]
      }
      "caa" = {
        name = "@"
        type = "CAA"
        ttl  = 3600
        caa = [
          { flags = 0, tag = "issue", value = "letsencrypt.org" },
        ]
      }
    }
  }
  "private" = {
    private_dns_zone_id = "/subscriptions/12345678-1234-5678-9012-123456789012/resourceGroups/rg-dns-prod/providers/Microsoft.Network/privateDnsZones/internal.example.com"
    records = {
      "api-a" = {
        name    = "api"
        type    = "A"
        ttl     = 0
        records = ["10.20.0.10"]
      }
      "db-srv" = {
        name = "_postgresql._tcp.db"
        type = "SRV"
        ttl  = 300
        srv = [
          { priority = 10, weight = 100, port = 5432, target = "db.internal.example.com" },
        ]
      }
    }
  }
}
```

## Notes

- Pair with `azure/dns-zone`: `zone_names` feeds `zone_name` for public zone
  entries and `zone_ids` feeds `private_dns_zone_id` for private entries. The
  zone must exist when the record module applies (Terragrunt `dependency`
  ordering).
- One resource per record type means flipping **`type`** (or moving between
  public and private zones) destroys and recreates the record set. Same-type
  value edits update in place.
- We intentionally do not default `name` to `@` for apex records even though
  the provider's MX attribute does — pass `name = "@"` explicitly.
- The apex NS record set is **Azure-managed** (it carries the zone's name
  servers) — this module does not touch it; NS entries are for delegation
  points below the apex only.
- Alias records (`target_resource_id` on A/AAAA/CNAME) land in dedicated
  `_alias` resource addresses internally — see Import.
- **TXT quoting**: multi-word TXT values (SPF, DKIM) need embedded quotes in
  the string — `"\"v=spf1 ...\""` — as the API delivers each string back
  verbatim. TXT values are capped at 1024 characters per string privately /
  4096 publicly (documented, not validated); long values split into several
  records map to several `txt` list entries.
- The Azure DNS API throttles at 500 requests per 5 minutes per zone: keep
  very large record maps (many hundreds of entries) split across zones or
  modules, and expect slower applies when re-creating many records.
- `target_resource_id` aliases are the apex for A/AAAA (public IP, load
  balancer) or a CDN endpoint for CNAME — the resource's attribute must be
  exposed by the aliasing resource, not a sub-chain of them.
- Tags are authoritative per record set: the provider PUTs the configured
  map, so portal/CLI tags on the record set are removed at the next apply
  with tag changes.
- The caller needs `Microsoft.Network/dnsZones/<type>/write` (public) or
  `Microsoft.Network/privateDnsZones/*` (private) on the zone.
- Not exposed, deliberately (pass-through candidates for a later minor
  release): a multi-target single map for `MX`/`SRV`/`CAA` mixes (one record
  set takes only its own type's blocks here), and record-set `metadata`.

## Import

```
tofu import 'azurerm_dns_a_record.a["<zone_key>.<record_key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/dnsZones/<zone>/<TYPE>/<name>"
tofu import 'azurerm_private_dns_a_record.private_a["<zone_key>.<record_key>"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/privateDnsZones/<zone>/<TYPE>/<name>"
```

Aliases import into the matching `_alias` address — `azurerm_dns_a_record.a_alias`
/ `aaaa_alias` / `cname_alias` — which is what the routing picks for records
with `target_resource_id` set. Other record
types import identically with the matching resource name (e.g.
`azurerm_dns_cname_record.cname`, `azurerm_private_dns_srv_record.private_srv`)
and the `<TYPE>` segment matching `records.type` — the resource must match the
record's type and privacy.
