# cloudflare/r2_bucket

Map-keyed module for Cloudflare R2 buckets with lifecycle rules, CORS
policies, custom domains, and r2.dev public access. Object locks, sippy
gradual migration, and event notifications remain out of scope — the
provider models them as separate resources
(`cloudflare_r2_bucket_lock`, `cloudflare_r2_bucket_sippy`,
`cloudflare_r2_bucket_event_notification`) that consumers manage
themselves.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `account_id` | `string` | `""` | Fallback account ID used when a bucket omits its own. |
| `buckets` | `map(object)` | — | Map of buckets keyed by an arbitrary unique ID. |

### `buckets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Bucket name. Renaming destroys and recreates the bucket (empty it first). |
| `account_id` | `string` | — | Per-bucket account ID; falls back to `var.account_id`. |
| `location` | `string` | — | Location hint: `apac`, `eeur`, `enam`, `weur`, `wnam`, or `oc`. Only honored on first creation and is best-effort — changing it afterwards does not move the bucket. |
| `jurisdiction` | `string` | `"default"` | Jurisdiction: `default`, `eu`, `fedramp`, or `us`. |
| `storage_class` | `string` | `"Standard"` | Default storage class: `Standard` or `InfrequentAccess`. |
| `lifecycle_rules` | `list(object)` | `[]` | Lifecycle rules; see the `lifecycle_rules` object table. Authoritative whole-set per bucket. |
| `cors_rules` | `list(object)` | `[]` | CORS rules; see the `cors_rules` object table. Authoritative whole-set per bucket. |
| `custom_domains` | `list(object)` | `[]` | Custom domains; `{domain, zone_id, enabled, min_tls, ciphers}`. |
| `managed_domain` | `bool` | — | r2.dev public access. Omit to leave it unmanaged, `true` to enable, `false` to explicitly disable. |

### `lifecycle_rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `id` | `string` | — | Unique rule identifier. |
| `enabled` | `bool` | `true` | Whether the rule is in effect. |
| `conditions` | `object` | — | `{prefix}`; an empty prefix scopes the rule to all objects. |
| `abort_multipart_uploads_transition` | `object` | — | `{condition = {type, max_age}}`; `type` must be `Age` (validated). |
| `delete_objects_transition` | `object` | — | `{condition = {type, max_age, date}}`; `type` one of `Age`, `Date` (validated) — `Age` requires `max_age` and `Date` requires `date`, never both. `date` is an RFC3339 timestamp. |
| `storage_class_transitions` | `list(object)` | `[]` | `{condition = {type, max_age, date}, storage_class}`; `storage_class` must be `InfrequentAccess` (validated). |

### `cors_rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `id` | `string` | — | Rule identifier. |
| `allowed` | `object` | — | `{methods, origins, headers}`; `methods`/`origins` required. |
| `expose_headers` | `list(string)` | — | Headers exposed to the browser. |
| `max_age_seconds` | `number` | — | Preflight cache duration. |

## Outputs

`bucket_names`, `bucket_locations`, `bucket_jurisdictions`,
`bucket_creation_dates` — all keyed by bucket key.
`bucket_r2_dev_domains` — map of bucket key => r2.dev domain (only for
buckets with `managed_domain` set).
`custom_domain_statuses` — map of composite key
(`bucket key/domain`) => `{ ownership, ssl }`.

## Notes

- `location` is applied only at first creation and is best-effort; the API
  may place the bucket elsewhere. Editing `location` afterwards forces
  destroy and recreate (with the caveat that the API never honors it post-creation).
- Changing `jurisdiction` does **not** force replacement (only `name` and
  `account_id` do), but the jurisdiction is part of the API identity and
  the import ID — an in-place edit re-targets a *different* bucket. Change
  jurisdiction deliberately by recreating, never in place. The satellite
  resources (lifecycle, CORS, domains) inherit the bucket entry's
  jurisdiction and follow it exactly.
- Renaming a bucket destroys and recreates it; empty the bucket first.
- Keys are arbitrary unique identifiers, not bucket names — the key
  disambiguates multiple entries that share a name (e.g. same bucket name
  under different jurisdictions).
- `lifecycle_rules` and `cors_rules` are authoritative whole-set per
  bucket: the API replaces the entire rule list on every apply, and drift
  reverts to the configured set.
- The lifecycle and r2.dev resources **cannot be destroyed from
  Terraform** (the provider warns about this): removing `lifecycle_rules`
  or setting `managed_domain` back to `null` drops them from state but
  leaves the configuration live in the API until it is deleted manually.
- Adopting the module against buckets whose lifecycle/CORS rules are
  already managed by separate consumer-side
  `cloudflare_r2_bucket_lifecycle`/`cloudflare_r2_bucket_cors` resources
  gives you two Terraform managers fighting over the same whole-set —
  remove those consumer-side resources before enabling the module fields.
  None of the four satellite resources support import; the first module
  apply overwrites whatever the API currently holds.
- Attaching a custom domain creates its DNS record **automatically** on
  Cloudflare's side. The record lives outside this module — do not also
  manage it with `cloudflare/dns-records`, or the two will fight. (Pages
  custom domains are the opposite: there the DNS record is *not*
  auto-created.)
- `managed_domain = false` still creates a management resource with
  r2.dev access disabled, distinguishing "explicitly disabled" from "not
  managed"; flipping it to `true` later is an in-place change.

## Example

```hcl
account_id = "023e105f4ecef8ad9ca31a8372d0c353"

buckets = {
  "assets-eu" = {
    name         = "example-assets"
    location     = "eeur"
    jurisdiction = "eu"
    lifecycle_rules = [
      {
        id = "abort-stale-uploads"
        conditions = { prefix = "" }
        abort_multipart_uploads_transition = {
          condition = { type = "Age", max_age = 86400 }
        }
      },
      {
        id = "expire-logs"
        conditions = { prefix = "logs/" }
        delete_objects_transition = {
          condition = { type = "Age", max_age = 2592000 }
        }
      },
    ]
    cors_rules = [
      {
        allowed = {
          methods = ["GET"]
          origins = ["https://www.example.com"]
        }
        max_age_seconds = 3600
      },
    ]
    custom_domains = [
      {
        domain  = "assets.example.com"
        zone_id = "36ca64a6d92827b8a6b90be344bb1bfd"
      },
    ]
    managed_domain = true
  }
  "archive-cold" = {
    name          = "example-archive"
    storage_class = "InfrequentAccess"
  }
}
```

## Import

`cloudflare_r2_bucket` ← `<account_id>/<bucket_name>/<jurisdiction>`
Buckets created without a jurisdiction import with `default`, e.g.
`023e105f4ecef8ad9ca31a8372d0c353/example-assets/default`.
The lifecycle, CORS, custom-domain, and r2.dev satellite resources do
not support import.
