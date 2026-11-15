# hetzner/zone_record

Map-keyed module for Hetzner Cloud DNS records in a single zone (by name or ID).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `zone` | `string` | — | Name or ID of the parent zone (both are accepted by the resource). Typically wired from a `hetzner/zone` dependency output: `dependency.zone.outputs.zones["example-org"].id`. |
| `records` | `map(object)` | — | Map of records keyed by an arbitrary unique ID. |

### `records` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Record name, lowercase, no trailing dot, 1–255 characters (validated). For the zone apex use `@`. For IDN names transcribe to Punycode (e.g. with the `provider::hcloud::idna` provider function). |
| `type` | `string` | — | Record type: `A`, `AAAA`, `CAA`, `CNAME`, `DS`, `HINFO`, `HTTPS`, `MX`, `NS`, `PTR`, `RP`, `SRV`, `SVCB`, `TLSA` or `TXT` (validated). `SOA` is excluded — the SOA RRSet is created and maintained by the API together with the zone. Changing it replaces the record. |
| `value` | `string` | — | Record value. Changing it replaces the record. MX priority is part of the value, zone-file style (`10 mail.example.org.`); SRV is `10 60 5060 target.`. TXT values must be quoted strings — see Notes. |
| `comment` | `string` | null | Optional comment. The only attribute that updates in place. |

## Outputs

`records` — map of record key => object:

| Attribute | Description |
|---|---|
| `zone` | Parent zone (ID or name as configured). |
| `name` | Record name. |
| `type` | Record type. |
| `value` | Record value. |
| `comment` | Comment or empty. |

The resource has no ID — its identifier is the `zone`/`name`/`type`/`value` tuple, so this output doubles as the import identity (see Import).

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
  }
}

module "records" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/hetzner/zone_record?ref=v0.1.0"

  zone = module.zone.zones["example-org"].id

  records = {
    "mx-primary" = {
      name    = "@"
      type    = "MX"
      value   = "10 mail.example.org."
      comment = "Primary mail server"
    }
    "mx-backup" = {
      name  = "@"
      type  = "MX"
      value = "20 mail-backup.example.org."
    }
    "txt-spf" = {
      name  = "@"
      type  = "TXT"
      value = provider::hcloud::txt_record("v=spf1 include:_spf.example.org -all")
    }
    "a-mail" = {
      name  = "mail"
      type  = "A"
      value = "203.0.113.1"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not record names — several entries can share `name` and `type` (e.g. two MX records) as long as their values are distinct (validated).
- Entries sharing `name` and `type` append to the same RRSet, which the API auto-creates if it does not exist yet. Creating several records on a brand-new RRSet in one apply exercises that auto-create path; there is no atomicity guarantee across the separate records.
- TTL and labels are RRSet-level properties and are not manageable through this resource; an implicitly created RRSet gets the zone's default TTL. If you need RRSet-level TTL, labels or protection, use `hcloud_zone_rrset` instead (this resource exists for the case where per-record values should be managed individually).
- The parent zone must be in `primary` mode — the API rejects record writes on secondary zones with `incorrect_zone_mode`.
- TXT values must consist of one or more quoted strings of at most 255 characters each, with inner quotes escaped as `\"` — use the `provider::hcloud::txt_record` provider function to format them (hand-quoting as `"\"v=spf1 -all\""` also works).
- `name`, `type`, `value` and `zone` are force-new; `comment` updates in place. Deleting a record removes only its value from the RRSet — the RRSet survives as long as other values remain in it; an RRSet left with no records is deleted by the API, taking any out-of-band TTL/labels with it.
- Do not also manage the same `name`/`type` pair with `hcloud_zone_rrset` — the two would fight over the record list.
- Per-type value syntax (other than the TXT quoting above) is validated by the API; see the accepted-value reference at https://docs.hetzner.com/networking/dns/record-types/overview/.
- Plan-time validations mirror the API rules (type allowlist, name format, distinct values, TXT quoting).
- The provider floor `>= 1.60.0` is a loose floor (`hcloud_zone_record` was added in v1.60.0); exact pinning is done at the consumer's unit level.
- Provider authentication is configured at the consumer's unit level.

## Import

Identity-based import only — importing by ID is rejected by the resource.

```hcl
import {
  to = module.records.hcloud_zone_record.record["mx-primary"]

  identity = {
    zone  = "example.org"
    name  = "@"
    type  = "MX"
    value = "10 mail.example.org."
  }
}
```

The identity must match the stored form exactly (for TXT, the quoted form), and `zone` must match what the resource is configured with — if the config passes the zone ID from a `hetzner/zone` output, import it as that same ID string, not the zone name (`zone` is not normalized by the provider and a mismatch replaces the record on first apply). Requires Terraform >= 1.12 (import block with `identity`). On OpenTofu, use provider >= 1.68.0, which sets the identity after read/update and makes identity-based import work there too.
