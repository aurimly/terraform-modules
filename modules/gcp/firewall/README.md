# gcp/firewall

Map-keyed module for Google Cloud firewall rules in a VPC network.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `firewalls` | `map(object)` | — | Map of firewall rules keyed by an arbitrary unique ID; each entry creates one `google_compute_firewall`. |

### `firewalls` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Rule name; unique inside a project, 1–63 lowercase RFC1035 characters. Validated client-side. Immutable; changing forces replacement. |
| `network` | `string` | — | VPC network name or self link. |
| `direction` | `string` | — | One of `INGRESS`, `EGRESS` (case-sensitive, validated). Immutable; changing forces replacement. |
| `project_id` | `string` | — | Project the rule lives in; defaults to the provider-level project. Format validated. |
| `description` | `string` | — | Human-readable description. |
| `priority` | `number` | `1000` | 0–65535 integer; a lower value beats a higher one when rules overlap (validated). |
| `disabled` | `bool` | `false` | Evaluates the rule as not matching, without deleting it — useful for staging. |
| `source_ranges` | `list(string)` | — | IPv4 or IPv6 CIDR ranges; `INGRESS` only (validated). Required for `INGRESS` unless another source is set. |
| `destination_ranges` | `list(string)` | — | IPv4 or IPv6 CIDR ranges; `EGRESS` only (validated) and required for `EGRESS`. |
| `source_tags` | `list(string)` | — | Instance network tags; `INGRESS` only, mutually exclusive with `source_service_accounts` (validated). |
| `source_service_accounts` | `list(string)` | — | Source service-account emails; `INGRESS` only (validated). |
| `target_tags` | `list(string)` | — | Instances to apply the rule to by tag; mutually exclusive with `target_service_accounts` (validated). |
| `target_service_accounts` | `list(string)` | — | Instances to apply the rule to by service account; mutually exclusive with `target_tags` (validated). |
| `allow` | `list(object)` | `[]` | Matched traffic to permit; exactly one of `allow`/`deny` must be non-empty (validated). See below. |
| `deny` | `list(object)` | `[]` | Traffic to deny; see below. |
| `log_config` | `object` | — | Presence enables firewall rule logging; `{metadata = "INCLUDE_ALL_METADATA"/"EXCLUDE_ALL_METADATA"}` (validated; metadata defaults to `INCLUDE_ALL_METADATA`). |

`allow` / `deny` entries: `{protocol = "tcp"|"udp"|"icmp"|... | protocol number, ports = optional list}` — `ports` (single port or `from-to`, validated shape) only for `tcp`/`udp`/`sctp` or numbers 6/17/132 (validated).

## Outputs

`firewall_names` — map of rule key => rule name.
`firewall_ids` — map of rule key => rule ID (`projects/{project}/global/firewalls/{name}`).
`firewall_self_links` — map of rule key => rule self link.

## Example

```hcl
firewalls = {
  "ssh" = {
    name          = "example-allow-ssh-ingress"
    network       = "example-vpc"
    direction     = "INGRESS"
    description   = "SSH from the office"
    priority      = 1000
    source_ranges = ["203.0.113.0/24"]
    target_tags   = ["example-app"]
    allow = [
      { protocol = "tcp", ports = ["22"] },
    ]
    log_config = {}
  }
  "internal-svc" = {
    name          = "example-allow-internal-ingress"
    network       = "example-vpc"
    direction     = "INGRESS"
    source_ranges = ["10.0.0.0/8"]
    allow = [
      { protocol = "tcp", ports = ["8080-8443"] },
    ]
  }
  "egress-all" = {
    name                = "example-allow-all-egress"
    network             = "example-vpc"
    direction           = "EGRESS"
    destination_ranges  = ["0.0.0.0/0"]
    allow = [
      { protocol = "all" },
    ]
  }
  "block-rdp" = {
    name          = "example-deny-rdp-ingress"
    network       = "example-vpc"
    direction     = "INGRESS"
    priority      = 900
    source_ranges = ["0.0.0.0/0"]
    deny = [
      { protocol = "tcp", ports = ["3389"] },
    ]
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not rule names — the key
  disambiguates entries; rule names must still be unique inside a project.
- `network` accepts the VPC network name (same project) or a self link; pair
  with `gcp/vpc`.
- This module deliberately rejects the provider's implicit defaults: an
  `INGRESS` rule without any source attribute and an `EGRESS` rule without
  `destination_ranges` both fall back to implicit `0.0.0.0/0` on the API side
  — spell the scope out (validated).
- The provider's source/target exclusivity matrix is enforced at plan time:
  `source_tags` ⊗ `source_service_accounts`, `source_tags` ⊗
  `target_service_accounts`, `source_service_accounts` ⊗ `target_tags`,
  `target_tags` ⊗ `target_service_accounts` (all validated). A rule naming
  both a `source_service_accounts` target and a `target_tags` target must be
  split in two.
- `ports` is only meaningful for TCP/UDP/SCTP (validated); `protocol = "all"`
  is a ramp for both `allow` and `deny` Internet traffic and must not carry
  `ports`.
- Ranges accept IPv4 and IPv6 CIDRs, so no CIDR shape validation is applied
  here.
- `name` is immutable (renaming forces replacement; imports key on it);
  most other attributes — including the tags/service-account scopes and
  `network` — update in place from the provider's perspective (verify against
  the provider docs for the version you pin before scripting changes).
- When rules overlap, the lower `priority` wins; between two rules at the
  same priority, `deny` beats `allow`.
- Firewall rule logging requires the enabled Logging API and generates
  complex costs at high rule match rates — start with `log_config` on
  deny rules only.

- Not yet in scope (future additions): `params.resource_manager_tags` and `deletion_policy` (how a guarded delete behaves).

## Import

`google_compute_firewall` ← `projects/{project}/global/firewalls/{name}`
(also `{project}/{name}`, and the bare `{name}` within the provider's
default project).
