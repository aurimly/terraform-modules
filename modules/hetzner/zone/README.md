# hetzner/zone

Map-keyed module for Hetzner Cloud DNS zones (primary or secondary).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `zones` | `map(object)` | — | Map of zones keyed by an arbitrary unique ID. |

### `zones` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Zone DNS name (e.g. `example.org`), lowercase, 1–255 characters, no trailing dot (validated). Subdomains are not supported by the API. For IDN names use the `provider::hcloud::idna` provider function. |
| `mode` | `string` | — | `primary` or `secondary` (validated). Changing it replaces the zone. |
| `ttl` | `number` | API default (`3600`) | Default TTL in seconds, 60–2147483647 (validated). |
| `labels` | `map(string)` | `{}` | User-defined labels; values at most 63 characters, may be empty (validated). |
| `delete_protection` | `bool` | null | Delete protection. |
| `primary_nameservers` | `list(object)` | null | Primary nameservers for a secondary zone. Forbidden when `mode = "primary"`, required when `mode = "secondary"` (at least one entry, validated). Addresses must be unique within the zone (validated). |

### `primary_nameservers` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `address` | `string` | — | Public IPv4 or IPv6 address of the primary nameserver. |
| `port` | `number` | API default | Port of the primary nameserver. |
| `tsig_algorithm` | `string` | null | TSIG algorithm: `hmac-md5`, `hmac-sha1` or `hmac-sha256` (validated). |
| `tsig_key` | `string` | null | TSIG key; requires `tsig_algorithm` in the same entry (validated). |

## Outputs

`zones` — map of zone key => object:

| Attribute | Description |
|---|---|
| `id` | String of the numeric zone ID — also the import ID (which alternatively accepts the zone name). |
| `authoritative_nameservers` | List of authoritative Hetzner nameservers assigned to the zone. |
| `registrar` | Registrar of the zone. |
| `delete_protection` | Whether delete protection is enabled. |

## Example

```hcl
module "zone" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/hetzner/zone?ref=v0.1.0"

  zones = {
    "example-org" = {
      name = "example.org"
      mode = "primary"
      ttl  = 10800
    }
    "example-net-secondary" = {
      name = "example.net"
      mode = "secondary"
      primary_nameservers = [
        { address = "198.51.100.1" },
        { address = "198.51.100.2", port = 5353 }
      ]
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not names.
- Zones are scoped to the provider token, not per-resource projects.
- `mode` and `name` replace the zone; everything else updates in place.
- `primary_nameservers` is only meaningful with `mode = "secondary"`.
- Plan-time validations mirror the provider's validators and the API
  rules (bounds, uniqueness, mode/primary_nameservers coupling, TSIG).
- The provider floor `>= 1.50.0` is a loose floor; exact pinning is done
  at the consumer's unit level.
- Provider authentication is configured at the consumer's unit level.

## Import

`hcloud_zone` ← numeric zone ID or zone name.
