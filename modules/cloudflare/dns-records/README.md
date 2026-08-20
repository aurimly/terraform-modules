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
| `data` | `object` | — | CAA data form (`flags`, `tag`, `value`). Set this OR `content`. |

## Outputs

`record_ids`, `record_names`, `record_contents` — all keyed by record key.

## Content vs data form

Cloudflare returns most records as a flat `content` string. CAA records may
be returned in `data` form (a `flags`/`tag`/`value` object). Set whichever
form the API returns for a given record so the import reaches zero-diff;
exactly one of `content`/`data` must be set per record.

## Notes

- TXT and CAA records are never proxied; leave `proxied = false`.
- `content` must match the API-returned representation byte-for-byte
  (Google's 2048-bit DKIM key is returned as multiple quoted strings;
  preserve that form, do not normalize).
- Keys are arbitrary unique identifiers, not record names — 12 CAA
  records share name `@`, so the key disambiguates them
  (e.g. `caa-issue-pki-goog`).

## Import

`cloudflare_dns_record` ← `<zone_id>/<record_id>`
