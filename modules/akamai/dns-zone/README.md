# akamai/dns-zone

Map-keyed module for Akamai Edge DNS zones: primary, secondary (with TSIG-authenticated transfers), and alias zones, with sign-and-serve, outbound zone transfer, and multi-signer DNSSEC options.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `zones` | `map(object)` | — | Map of zones keyed by an arbitrary unique ID. |

### `zones` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `zone` | `string` | — | The DNS zone name, e.g. `example.org`, without a trailing dot (validated). Treat it as immutable: see Notes. |
| `contract` | `string` | — | Contract ID, with or without the `ctr_` prefix (the resource accepts both). Treat it as immutable: see Notes. |
| `group` | `string` | — | Group ID, with or without the `grp_` prefix (the resource accepts both — it is a string, not a number, despite some doc examples). Required: zone create fails without it whenever more than one group is visible to the credentials, which is the common account shape. |
| `type` | `string` | — | `primary`, `secondary` or `alias` (validated; lowercase in config, stored uppercased). Force-new: changing it replaces the zone. |
| `masters` | `list(string)` | `[]` | Names/IPs of the primary nameservers. Required for `secondary` zones, forbidden otherwise (validated). |
| `target` | `string` | null | Name of the zone this alias points to. Required for `alias` zones, forbidden otherwise (validated). Must already exist remotely — see Notes. |
| `comment` | `string` | `"Managed by Terraform"` | Mirrors the provider default. |
| `sign_and_serve` | `bool` | `false` | Sign the zone at the edge. Ignored (nulled) for alias zones. |
| `sign_and_serve_algorithm` | `string` | null | `RSA_SHA1`, `RSA_SHA256`, `RSA_SHA512`, `ECDSA_P256_SHA256` or `ECDSA_P384_SHA384`. Only valid when the zone is actually signed (validated). |
| `end_customer_id` | `string` | null | Free-form identifier for reporting. |
| `tsig_key` | `object` | null | TSIG key authenticating transfers from the masters: `{ name, algorithm, secret }`. Only valid for `secondary` zones (validated). `algorithm` must be one of `hmac-md5`, `hmac-sha1`, `hmac-sha224`, `hmac-sha256`, `hmac-sha384`, `hmac-sha512`, `HMAC-MD5.SIG-ALG.REG.INT` (validated). |
| `outbound_zone_transfer` | `object` | null | Outbound transfer properties for letting others transfer from this zone: `{ acl, enabled, notify_targets, tsig_key }` (`acl` and `notify_targets` are lists of CIDRs/addresses; the nested `tsig_key` uses the same shape and algorithm list as above). |
| `multi_provider_dnssec` | `object` | null | Multi-signer DNSSEC: `{ enabled, webhook }`. `enabled = true` requires the zone to be effectively signed — see Notes. |

## Outputs

All keyed by the input map key:

| Output | Description |
|---|---|
| `zone_names` | key => zone name. The zone name is also the import ID of the resource. |
| `zone_types` | key => zone type as stored in state (`PRIMARY`, `SECONDARY`, `ALIAS`). |
| `zone_activation_states` | key => activation state. Starts at `PENDING` after create. |
| `zone_version_ids` | key => version ID of the current zone version. |
| `zone_alias_counts` | key => number of alias zones pointing at this zone. |

## Example

```hcl
module "zones" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/akamai/dns-zone?ref=v2.69.0"

  zones = {
    "example-org" = {
      zone     = "example.org"
      contract = "ctr_C-0N7RAC7"
      group    = "grp_12345"
      type     = "primary"
    }
    "example-org-secondary" = {
      zone     = "example.net"
      contract = "ctr_C-0N7RAC7"
      group    = "grp_12345"
      type     = "secondary"
      masters  = ["ns1.example.net.", "ns2.example.net."]
      tsig_key = {
        name      = "example.net."
        algorithm = "hmac-sha256"
        secret    = "base64encodedsecret="
      }
    }
  }
}
```

### Wiring records

Ordering is consumer-side, with a Terragrunt `dependency` block consuming the `zone_names` output (Terraform-style `depends_on = [module.zones]` does not exist in Terragrunt):

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

The Akamai provider authenticates with EdgeGrid credentials — an `~/.edgerc` file (optionally selecting a section with `config_section` in the provider block at the consumer's unit level) or the `AKAMAI_*` environment variables. The consumer unit also needs Edge DNS authorization for the contract the zones live in. Modules never configure the provider themselves.

## Notes

- `type` is force-new — changing it replaces the zone. `zone` and `contract` are NOT force-new, but treat both as immutable anyway: renaming `zone` makes the update address a different remote zone (possibly a missing one), and editing `contract` does not transfer the zone — the update carries the remote contract forward. `prevent_destroy` protects destroy only, not these in-place paths.
- A newly created zone starts with `activation_state = PENDING`; a later `-refresh-only` apply picks up `ACTIVE`. A record change flips the zone back to `PENDING` without updating its state.
- Primary zones get auto-created SOA and NS record sets that are not part of this module's config; import them (via `akamai/dns-record`) if they need to be managed.
- Secondary zones only accept `AKAMAICDN`/`AKAMAITLC` record types; `akamai/dns-record` targets primary zones.
- Alias zones have no cross-instance dependency: an alias entry whose `target` points at a sibling entry's zone in the same map has no ordering guarantee within one apply — the target zone must already exist remotely or in a previously applied unit.
- Removing `tsig_key` may not remove the key remotely: the provider copies the remote TSIG key back into the update object when the configured list is empty. Verify via the Edge DNS API/Control Center and remove it there if it persists. TSIG rotation and transition to unsigned transfers are not validated by the provider either — verify those transitions consumer-side.
- Importing an already-signed zone without carrying over `sign_and_serve` (and other optional settings) plans a signing change — reconcile every optional setting after import and review the plan. Reverting this module's merge reverts code only; it is not a reversal of any signing change applied against real state.
- Import and refresh of a primary zone can create the default SOA and NS record sets (the provider populates them when the pair is incomplete) — they are not guaranteed read-only operations and need Edge DNS write permissions.
- The masters/tsig_key/target restrictions are surfaced at plan time by the module; the provider enforces the same rules at apply.
- The provider floor `>= 12.0.0` is a loose floor (every attribute used here exists since v11.0.0; v12.0.0 only marks the TSIG secrets sensitive); exact pinning is done at the consumer's unit level.
- Sensitivity contract: the resource marks TSIG secrets sensitive, which redacts them in plan/apply output only. Module variables are not sensitive (a fully-sensitive `zones` map is unusable with `for_each`), and everything — including secrets — is stored plaintext in state; protect the remote backend accordingly.

## Import

Zone name only — import does not populate `group`, so the first apply after import shows a group update; reconcile every module-defaulted optional at the same time.

```hcl
import {
  to = module.zones.akamai_dns_zone.zone["example-org"]
  id = "example.org"
}
```
