# cloudflare/r2_bucket

Map-keyed module for Cloudflare R2 buckets. Lifecycle rules, CORS policies,
object locks, sippy gradual migration, and event notifications are out of
scope — the provider models them as separate resources
(`cloudflare_r2_bucket_lifecycle`, `cloudflare_r2_bucket_cors`,
`cloudflare_r2_bucket_lock`, `cloudflare_r2_bucket_sippy`,
`cloudflare_r2_bucket_event_notification`) that consumers manage themselves.

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

## Outputs

`bucket_names`, `bucket_locations`, `bucket_jurisdictions`,
`bucket_creation_dates` — all keyed by bucket key.

## Notes

- `location` is applied only at first creation and is best-effort; the API
  may place the bucket elsewhere. Editing `location` afterwards forces
  destroy and recreate (with the caveat that the API never honors it post-creation).
- Changing `jurisdiction` does **not** force replacement (only `name` and
  `account_id` do), but the jurisdiction is part of the API identity and
  the import ID — an in-place edit re-targets a *different* bucket. Change
  jurisdiction deliberately by recreating, never in place.
- Renaming a bucket destroys and recreates it; empty the bucket first.
- Keys are arbitrary unique identifiers, not bucket names — the key
  disambiguates multiple entries that share a name (e.g. same bucket name
  under different jurisdictions).

## Example

```hcl
account_id = "023e105f4ecef8ad9ca31a8372d0c353"

buckets = {
  "assets-eu" = {
    name         = "example-assets"
    location     = "eeur"
    jurisdiction = "eu"
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
