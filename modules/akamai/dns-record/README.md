# akamai/dns-record

Map-keyed module for Akamai Edge DNS records in a single (primary) zone.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `zone` | `string` | — | Name of the parent zone (the import ID of an `akamai/dns-zone` resource). Typically wired from a dns-zone dependency output: `dependency.zone.outputs.zone_names["example-org"]`. |
| `records` | `map(object)` | — | Map of records keyed by an arbitrary unique ID. |

### `records` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Owner name in FQDN form without trailing dot; the apex is the zone name itself (validated: the name must be the zone or a subdomain of it, ignoring case). Force-new. |
| `recordtype` | `string` | — | `A`, `AAAA`, `CAA`, `CNAME`, `LOC`, `NS`, `PTR`, `SPF`, `TXT`, `AFSDB`, `DNSKEY`, `DS`, `HINFO`, `MX`, `NAPTR`, `NSEC3`, `NSEC3PARAM`, `RP`, `RRSIG`, `SRV`, `SSHFP`, `SOA`, `AKAMAICDN`, `CERT`, `TLSA`, `SVCB` or `HTTPS` (validated). Force-new. |
| `ttl` | `number` | 3600 | Record TTL; 0 is allowed. |
| `target` | `list(string)` | — | The full record set for the name/recordtype pair. Required for `A`, `AAAA`, `CNAME`, `LOC`, `NS`, `PTR`, `SPF`, `TXT`, `AFSDB`, `AKAMAICDN`, `MX`, `CAA`, `SRV`; must not be set for `CERT`, `DNSKEY`, `DS`, `HINFO`, `HTTPS`, `NAPTR`, `NSEC3`, `NSEC3PARAM`, `RP`, `RRSIG`, `SSHFP`, `SVCB`, `TLSA` (see Notes); `SOA` takes no target (validated). |
| `priority` | `number` | null | MX/SRV priority (or use embedded priorities in `target` — MX allows both forms, SRV does not allow mixing). |
| `priority_increment` | `number` | null | MX only: increments the priority per successive target. Requires `priority` and targets without embedded priorities (validated). |
| `weight`, `port` | `number` | null | SRV weight and port, used with one-part `target` entries (`port` is required and must be non-zero for one-part targets — validated; both scalars must be unset for four-part targets). |
| `subtype` | `number` | null | AFSDB subtype. |
| `name_server` | `string` | null | SOA nameserver. |
| `email_address` | `string` | null | SOA responsible-person mailbox (dot-notation acceptable). |
| `refresh`, `retry`, `expiry`, `nxdomain_ttl` | `number` | null | SOA timing values; all required and non-zero for SOA (validated). |
| `serial` | — | — | Computed; Akamai manages the SOA serial. |
| other type-specific attributes | `number`/`string` | null | Flat pass-through to the resource: `flags`, `protocol`, `algorithm`, `key` (DNSKEY), `keytag`, `digest_type`, `digest` (DS), `hardware`, `software` (HINFO), `order`, `preference`, `flagsnaptr`, `service`, `regexp`, `replacement` (NAPTR), `iterations`, `salt`, `next_hashed_owner_name`, `type_bitmaps` (NSEC3/NSEC3PARAM), `mailbox`, `txt` (RP), `type_covered`, `original_ttl`, `expiration`, `inception`, `signer`, `signature`, `labels` (RRSIG), `fingerprint_type`, `fingerprint` (SSHFP), `usage`, `selector`, `match_type`, `certificate` (CERT), `type_value`, `type_mnemonic`, `svc_priority`, `svc_params`, `target_name` (SVCB/HTTPS). |

## Outputs

`records` — map of record key => object:

| Attribute | Description |
|---|---|
| `zone` | Parent zone. |
| `name` | Record name. |
| `recordtype` | Record type. |
| `ttl` | Record TTL. |
| `target` | Record set. |

`zone`, `name` and `recordtype` are exactly the parts of the import ID: `zone#name#recordtype`.

## Example

```hcl
module "records" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/akamai/dns-record?ref=v2.69.0"

  zone = dependency.zone.outputs.zone_names["example-org"]

  records = {
    "www-a" = {
      name       = "www.example.org"
      recordtype = "A"
      target     = ["203.0.113.10"]
    }
    "www-alias" = {
      name       = "alias.example.org"
      recordtype = "CNAME"
      target     = ["www.example.org.edges.example.net."]
    }
    "mx" = {
      name       = "example.org"
      recordtype = "MX"
      target     = ["10 mail.example.org.", "20 mail-backup.example.org."]
    }
    "spf" = {
      name       = "example.org"
      recordtype = "TXT"
      target     = ["\"v=spf1 -all\""]
    }
    "caa" = {
      name       = "example.org"
      recordtype = "CAA"
      target     = ["0 issue \"letsencrypt.org\""]
    }
    "srv-sip" = {
      name       = "_sip._tcp.example.org"
      recordtype = "SRV"
      priority   = 10
      weight     = 60
      port       = 5060
      target     = ["sip.example.org."]
    }
  }
}
```

### Wiring records

Ordering is consumer-side, with a Terragrunt `dependency` block consuming the `zone_names` output of a `dns-zone` unit (Terraform-style `depends_on = [module.zones]` does not exist in Terragrunt):

```hcl
dependency "zone" {
  config_path = "../dns-zone"

  mock_outputs = {
    zone_names = { "example-org" = "example.org" }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  zone = dependency.zone.outputs.zone_names["example-org"]
}
```

The mocks exist so `validate`/`plan` work on a fresh clone before the zone unit has state; the first downstream apply must follow the zone unit's apply.

### Provider authentication

The Akamai provider authenticates with EdgeGrid credentials — an `~/.edgerc` file (optionally selecting a section with `config_section` in the provider block at the consumer's unit level) or the `AKAMAI_*` environment variables. The consumer unit also needs Edge DNS authorization for the contract the zone lives in. Modules never configure the provider themselves.

## Notes

- One entry owns the full record set for its `name`/`recordtype` pair: `target` is the complete list, and deleting the entry deletes the whole set. Do not manage the same pair with a second resource or tool.
- The guarantee is not unconditional convergence for MX: brownfield MX create appends existing remote mail hosts omitted from the config, and read can fail with "Remote has diverged from TF Config. Manual intervention required." on drift. Adopt existing records through import first; whole-set deletion on destroy is the only absolute.
- The scalar-built types — `CERT`, `DNSKEY`, `DS`, `HINFO`, `HTTPS`, `NAPTR`, `NSEC3`, `NSEC3PARAM`, `RP`, `RRSIG`, `SSHFP`, `SVCB`, `TLSA` — are single-value only: the provider builds one value from their scalar attributes and ignores a supplied `target`, so this module rejects `target` on them (validated). A second value at one owner is not representable through this module; importing an existing multi-value set of these types plans replacement with the singleton.
- SOA: `serial` is computed and managed by Akamai; the timing values are required and non-zero (validated). The NS and SOA record sets of a primary zone are auto-created by the zone itself — import them before managing them here.
- Secondary zones only accept `AKAMAICDN` (and its read-only counterpart `AKAMAITLC`, which this module does not accept); the parent zone for everything else must be primary.
- `zone`, `name` and `recordtype` are force-new; everything else updates in place.
- TXT and SPF targets must be one or more fully quoted strings, each section at most 255 characters, separated by a single space, with inner quotes escaped as `\"` (e.g. `"\"v=spf1 -all\""` or `format("\"%s\"", "v=spf1 -all")`). Escape non-safe-ASCII bytes as `\ddd`. Empty content is written as a quoted `""`. The module is deliberately stricter than the provider, which would silently auto-quote unquoted values — unquoted values are not accepted here.
- Per-type value syntax other than TXT quoting is validated by the API at apply time.
- The resource exposes a computed `record_sha` attribute for drift detection; it is not part of this module's outputs.
- The provider floor `>= 12.0.0` is a loose floor; exact pinning is done at the consumer's unit level.
- Sensitivity contract: module variables are not sensitive (a fully-sensitive `records` map is unusable with `for_each`), and everything is stored plaintext in state; protect the remote backend accordingly. (This module has no secret-bearing inputs; `akamai/dns-zone` does.)

## Import

Import ID is `zone#name#recordtype`:

```hcl
import {
  to = module.records.akamai_dns_record.record["www-a"]
  id = "example.org#www.example.org#A"
}
```
