# cloudflare/dns-records

Map-keyed module for Cloudflare DNS records in a single zone.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `zone_id` | `string` | — | Cloudflare zone ID. |
| `records` | `map(object)` | — | Map of records keyed by an arbitrary unique ID. |

### `records` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Record name (`@`, `www`, `_mta-sts`, ...). |
| `type` | `string` | — | Record type (`A`, `AAAA`, `CNAME`, `MX`, `TXT`, `CAA`, ...). |
| `content` | `string` | — | Record content. Set this OR `data`. |
| `ttl` | `number` | `1` | TTL; `1` = automatic. |
| `proxied` | `bool` | `false` | Cloudflare orange-cloud. |
| `priority` | `number` | — | MX priority. |
| `comment` | `string` | — | Record comment. |
| `tags` | `set(string)` | `[]` | Record tags. |
| `data` | `object` | — | Structured data form for record types the API returns as data objects (CAA, SRV, LOC, DS, SSHFP, TLSA, ...). See below. Set this OR `content`. |
| `settings` | `object` | `null` | Record-level settings: `flatten_cname`, `ipv4_only`, `ipv6_only` (all optional `bool`). |
| `private_routing` | `bool` | `null` | Enables private network routing to the origin. |

### `data` object

The fields are the union of the per-type data objects in the
[Cloudflare API](https://developers.cloudflare.com/api/resources/dns/subresources/records/);
set only the ones the record type uses. All fields are optional; the API
validates the combination per record type at apply time.

| Field | Type | Used by |
|---|---|---|
| `tag`, `value`, `flags` | `string`, `string`, `number` | CAA |
| `priority`, `target` | `number`, `string` | MX, URI, SRV |
| `weight`, `port` | `number`, `number` | SRV, URI |
| `order`, `preference`, `regex`, `replacement`, `service` | `number`, `number`, `string`, `string`, `string` | NAPTR |
| `algorithm`, `key_tag`, `digest_type`, `digest` | `number`, `number`, `number`, `string` | DS |
| `algorithm`, `protocol`, `public_key` | `number`, `number`, `string` | DNSKEY |
| `usage`, `selector`, `matching_type`, `certificate` | `number`, `number`, `number`, `string` | TLSA, SMIMEA |
| `type`, `fingerprint` | `number`, `string` | SSHFP |
| `size`, `altitude`, `lat_degrees`, `lat_direction`, `lat_minutes`, `lat_seconds`, `long_degrees`, `long_direction`, `long_minutes`, `long_seconds`, `precision_horz`, `precision_vert` | `number`/`string` (directions are `string`) | LOC |

`flags` is typed `number` (CAA `0`/`128`, DNSKEY flags). The API also uses
a string form of `flags` for NAPTR records; that form is out of scope —
create NAPTR records outside this module if you need them.

## Outputs

`record_ids`, `record_names`, `record_contents` — all keyed by record key.

## Content vs data form

Cloudflare returns most records as a flat `content` string. Record types
like CAA, SRV, LOC, DS, SSHFP and TLSA are returned in `data` form (a
structured object) — set whichever form the API returns for a given record
so the import reaches zero-diff; exactly one of `content`/`data` must be
set per record (validated).

## Notes

- TXT and CAA records are never proxied; leave `proxied = false`.
- `content` must match the API-returned representation byte-for-byte
  (Google's 2048-bit DKIM key is returned as multiple quoted strings;
  preserve that form, do not normalize).
- Keys are arbitrary unique identifiers, not record names — 12 CAA
  records share name `@`, so the key disambiguates them
  (e.g. `caa-issue-pki-goog`).

## Example

```hcl
records = {
  "txt-spf" = {
    name    = "@"
    type    = "TXT"
    content = "\"v=spf1 -all\""
  }
  "caa-issue-letsencrypt" = {
    name = "@"
    type = "CAA"
    data = { flags = 0, tag = "issue", value = "letsencrypt.org" }
  }
  "srv-sip" = {
    name = "_sip._tcp"
    type = "SRV"
    data = { priority = 10, weight = 60, port = 5060, target = "sipserver.example.com" }
  }
  "cname-flat" = {
    name    = "flat"
    type    = "CNAME"
    content = "origin.example.com"
    settings = {
      flatten_cname = true
    }
  }
}
```

## Import

`cloudflare_dns_record` ← `<zone_id>/<record_id>`
