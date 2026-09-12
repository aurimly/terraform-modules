# ns1/record

Map-keyed module for NS1 DNS records (any record type, including linked
records and regions/answers-based records).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `records` | `map(object)` | — | Map of records keyed by an arbitrary unique ID (records like CAA share the name `@`). |

### `records` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `zone` | `string` | — | Zone name the record belongs to. ForceNew. |
| `type` | `string` | — | Record type (`A`, `AAAA`, `CNAME`, `MX`, `TXT`, `CAA`, ...). ForceNew. |
| `domain` | `string` | — | Full record name without trailing dot. Defaults to `<key>.<zone>`; for apex records set `domain` to the zone name. ForceNew. |
| `ttl` | `number` | `3600` | Record TTL (a module-level default; the provider will use MO size otherwise). |
| `override_ttl` | `bool` | `false` | Respect the link TTL instead of this record's (ALIAS records only). |
| `link` | `string` | — | Linked record (FQDN) to serve. Mutually exclusive with `answers`. |
| `use_client_subnet` | `bool` | `true` | Enable client subnet usage for this record. |
| `meta` | `map(string)` | `{}` | Record-level meta. Use `jsonencode()` for values that are not flat strings. |
| `tags` | `map(string)` | `{}` | Record tags. |
| `blocked_tags` | `list(string)` | — | Tags to block. |
| `override_address_records` | `bool` | — | Whether linked record address targets are overridden (ALIAS records only). |
| `filters` | `list(object)` | `[]` | Ordered filter chain (order is significant). |
| `regions` | `list(object)` | `[]` | Region definitions; order-insensitive but pick a stable order. |
| `answers` | `list(object)` | `[]` | Answers; order is significant (state is matched by index). Mutually exclusive with `link`. |

### `filters` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `filter` | `string` | — | Filter ID (e.g. `select`, `geotarget_country`). |
| `disabled` | `bool` | `false` | Disable this filter. |
| `config` | `map(string)` | `{}` | Filter configuration. Values are strings; numbers/bools are coerced to strings on read. |

### `regions` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Region name (AF, AS, NA, SA, OC, EU, or custom). |
| `meta` | `map(string)` | `{}` | Region meta (`country`, `georegion`, `us_state`, `ca_province`, `asn`, `ip_prefixes`, ...); list-typed meta values are comma-separated strings. |

### `answers` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `answer` | `string` | — | Answer value. Set this OR `answer_parts`. |
| `answer_parts` | `list(string)` | — | Multi-string answers (e.g. long TXT records). Set this OR `answer`. |
| `region` | `string` | — | Region name this answer belongs to (must also be defined in `regions` if set). |
| `meta` | `map(string)` | `{}` | Answer-level meta, same shape/encoding as record `meta` and region `meta`. |

`meta` values must be strings. For anything structured (pulsar job
references, object/array-typed GEO meta) build the value with
`jsonencode()` — the provider stores it verbatim after that:

```hcl
meta = { pulsar = jsonencode({ job = "job-id" }) }
```

## Outputs

`record_ids`, `record_fqdns`, `record_types` — all keyed by record key.

## Operational notes

- `zone`, `domain` and `type` are ForceNew; changing them recreates the
  record.
- `link` and `answers` are mutually exclusive (validated in the module,
  enforced by the provider).
- Records with `regions` set lexically by `name` sort cleanly even where
  the provider reports ordering diffs.

## Import

- `ns1_record` ← `<zone>/<domain>/<type>` (e.g.
  `example.com/www.example.com/A`; the apex FQDN is the zone name).

## Example

```hcl
records = {
  "www" = {
    zone = "example.io"
    type = "A"
    ttl  = 60
  }
  "site" = {
    zone   = "example.io"
    type   = "CNAME"
    domain = "core.example.io"
    link   = "myrecord.company.com"
  }
  "geo-apex" = {
    zone   = "example.io"
    domain = "example.io"
    type   = "A"
    regions = [
      { name = "US-E", meta = {} }
    ]
    answers = [
      { answer = "1.2.3.4", region = "US-E" },
      { answer = "5.6.7.8" }
    ]
  }
  "spf" = {
    zone = "example.io"
    type = "TXT"
    answers = [
      { answer_parts = ["v=DKIM1;k=rsa;"] }
    ]
  }
}
```
