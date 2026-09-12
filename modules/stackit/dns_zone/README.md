# stackit/dns_zone

Map-keyed module for STACKIT DNS zones (primary or secondary).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `zones` | `map(object)` | — | Map of zones keyed by an arbitrary unique ID. |

### `zones` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the zone is created in (validated). |
| `name` | `string` | — | User-given zone name, 1–63 characters (validated). |
| `dns_name` | `string` | — | The zone's DNS name (e.g. `example.org`), 1–253 characters, no trailing dot (validated). Changing it replaces the zone. |
| `type` | `string` | API default (`primary`) | `primary` or `secondary` (validated). |
| `acl` | `string` | `null` | Access control list (e.g. `0.0.0.0/0,::/0`), at most 2000 characters (validated). Currently has no effect upstream — it does not enforce any access restrictions on the zone; exposed for forward-compatibility. |
| `active` | `bool` | API default (`true`) | Zone active flag; exact semantics are undocumented upstream. |
| `contact_email` | `string` | `null` | Contact e-mail for the zone, at most 255 characters (validated). |
| `default_ttl` | `number` | `null` | Default time to live in seconds, 60–99999999 (validated). |
| `description` | `string` | `null` | Description of the zone, at most 1024 characters (validated). |
| `expire_time` | `number` | `null` | Expire time in seconds, 60–99999999 (validated). |
| `is_reverse_zone` | `bool` | API default (`false`) | Whether the zone is a reverse zone. |
| `negative_cache` | `number` | `null` | Negative caching in seconds, 60–99999999 (validated). |
| `primaries` | `list(string)` | `null` | Primary name servers for a secondary zone (e.g. `["192.0.2.53"]`), at most 10 entries (validated). Changing it replaces the zone. |
| `refresh_time` | `number` | `null` | Refresh time in seconds, 60–99999999 (validated). |
| `retry_time` | `number` | `null` | Retry time in seconds, 60–99999999 (validated). |

## Outputs

`zones` — map of zone key => object:

| Attribute | Description |
|---|---|
| `zone_id` | Zone UUID. |
| `primary_name_server` | Primary name server (FQDN). |
| `record_count` | Number of records in the zone. |
| `serial_number` | Zone SOA serial. Volatile: it changes on every zone mutation, so consumers reading the whole output object will see churn. |
| `state` | Zone state (e.g. `CREATE_SUCCEEDED`). |
| `visibility` | Zone visibility (e.g. `public`). |
| `id` | `"{project_id},{zone_id}"` — the import ID. |

## Example

```hcl
module "dns_zone" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/dns_zone?ref=v1.3.0"

  zones = {
    "public" = {
      project_id  = "12345678-1234-1234-1234-123456789012"
      name        = "example-org"
      dns_name    = "example.org"
      description = "Public zone for example.org"
      default_ttl = 3600
    }
    "secondary" = {
      project_id = "12345678-1234-1234-1234-123456789012"
      name       = "example-backup"
      dns_name   = "example.org"
      type       = "secondary"
      primaries  = ["192.0.2.53"]
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not names.
- DNS is a global service: the resource has no `region` attribute and the
  import ID carries no region.
- `dns_name` and `primaries` replace the zone; everything else updates in
  place.
- `primaries` is only meaningful with `type = "secondary"`; the provider
  does not enforce the combination, so neither does the module.
- The SOA-family numbers (`default_ttl`, `expire_time`, `refresh_time`,
  `retry_time`, `negative_cache`) share the 60–99999999 bound.
- Renaming a map key destroys and recreates the zone — a DNS outage
  window for every name in the zone.
- Plan-time validations mirror the provider's plan-time validators
  (UUIDs, name/dns_name bounds, no trailing dot, TTL bounds, list and
  string sizes).
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_dns_zone` ← `{project_id},{zone_id}`
