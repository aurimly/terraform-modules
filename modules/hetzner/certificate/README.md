# hetzner/certificate

Map-keyed module for Hetzner Cloud TLS certificates. Each entry is either
an **uploaded** certificate (set `private_key` and `certificate`) or a
**managed** certificate (set `domain_names` — Hetzner obtains and renews
it via ACME); the presence of `private_key` selects the kind.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `certificates` | `map(object)` | — | Map of certificates keyed by an arbitrary unique ID. |

### `certificates` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Certificate name, unique per project (validated). In-place. When replacing a certificate, use a **new name**: names are unique per project and the module keeps `create_before_destroy`, so a same-name replacement fails at create with a uniqueness error. |
| `domain_names` | `list(string)` | null | Domains to obtain the certificate for. Required (at least one entry, validated) for managed entries; ForceNew for them. Must stay unset on uploaded entries — their domains are derived from the PEM data and exported computed. |
| `private_key` | `string` | null | PEM private key. Setting it makes the entry an uploaded certificate; unset it for a managed one. Required non-null for uploaded entries (validated). ForceNew. Store it via `sensitive()` and feed it from a secret source — it lives in the Terraform state either way (marked sensitive by the provider, hidden from plan output). |
| `certificate` | `string` | null | PEM certificate. Required for uploaded entries (validated; ForceNew; replacement only happens when the parsed certificate actually differs — the provider normalizes whitespace before diffing). Must stay unset on managed entries — it is computed there. |
| `labels` | `map(string)` | `{}` | User-defined labels; values at most 63 characters, may be empty (validated). |

## Outputs

`certificates` — map of certificate key => object:

| Attribute | Description |
|---|---|
| `id` | String of the numeric certificate ID (import ID). |
| `name` | Certificate name. |
| `type` | `managed` or `uploaded`. |
| `certificate` | Public PEM certificate. The private key is never exported — the API does not return it. |
| `domain_names` | Domains and subdomains covered by the certificate. |
| `fingerprint` | Certificate fingerprint. |
| `created` | Creation timestamp (ISO-8601). |
| `not_valid_before` | Start of the validity window (ISO-8601). |
| `not_valid_after` | End of the validity window (ISO-8601) — renew expiring certificates before it passes. |
| `labels` | User labels. |

Feed `id` to other modules (`hetzner/load_balancer` services
`certificates`) as a string — use `tonumber(...)` where a numeric value
is required.

## Example

```hcl
module "certificate" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/hetzner/certificate?ref=v0.1.0"

  certificates = {
    "managed-edge" = {
      name         = "edge-2026-01"
      domain_names = ["example.com", "*.example.com"]
      labels = { env = "npd" }
    }
    "uploaded-legacy" = {
      name        = "legacy-2026-01"
      private_key = sensitive(file("legacy.key"))
      certificate = file("legacy.crt")
    }
  }
}

# module "load_balancer" { …
#   services = { "https" = { protocol = "https", certificates = [
#     tonumber(module.certificate.certificates["managed-edge"].id),
#     tonumber(module.certificate.certificates["uploaded-legacy"].id),
#   ] } }
# }
```

## Notes

- Managed issuance needs the domains resolvable to Hetzner infrastructure
  (ACME challenge); issuance fails otherwise.
- The module hardcodes `lifecycle { create_before_destroy = true }` on
  both resources:
  the API refuses to delete a certificate still in use, so in-place
  replacement with destroy-first would leave the old entry undeletable
  and dependents broken; with CBD the new certificate is created first,
  dependents switch to it, then the old one deletes. Combined with the
  per-project name uniqueness this makes renaming mandatory when
  replacing a certificate.
- ForceNew surface: `domain_names` (managed), `private_key` and
  `certificate` (uploaded). `name` and `labels` update in place.
- The mode selection (`private_key` presence) and the must-stay-unset
  rules (`domain_names` on uploaded, `certificate` on managed) are this
  module's own contract, checked at plan time; both-set would otherwise
  apply with the surplus attribute silently ignored. The remaining
  checks (missing name, missing uploaded `certificate`, empty
  `domain_names`, label shape, name uniqueness) mirror the provider's
  validators.
- The legacy `hcloud_certificate` resource type is an alias of
  `hcloud_uploaded_certificate` and deprecated upstream; the module uses
  the two explicit resources only. Import legacy certificates as
  uploaded entries.
- Keys are arbitrary unique identifiers, not names.
- The provider floor `>= 1.50.0` is a loose floor; exact pinning is done
  at the consumer's unit level.
- Provider authentication is configured at the consumer's unit level.

## Import

`hcloud_managed_certificate` / `hcloud_uploaded_certificate` ← numeric
certificate ID. The map key (via `private_key` presence) decides which
of the two resources an entry configures — set `private_key` +
`certificate` for uploaded entries, `domain_names` for managed.
