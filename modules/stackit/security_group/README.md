# stackit/security_group

Map-keyed module for STACKIT security groups with optional inline security
group rules.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `security_groups` | `map(object)` | — | Map of security groups keyed by an arbitrary unique ID. |

### `security_groups` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Security group name; validated against the provider's rule: 1–63 characters, starts/ends with a letter or digit, letters/digits/hyphens/underscores/dots/whitespace in between. No slashes (unlike network names). |
| `project_id` | `string` | — | STACKIT project UUID the security group is created in. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the group and all of its rules. |
| `description` | `string` | `null` | 1–127 characters when set. |
| `stateful` | `bool` | API default (`true`) | Stateful vs stateless group. Only one statefulness type per network interface/server. Changing it replaces the group and all of its rules. |
| `labels` | `map(string)` | `{}` | Labels attached to the security group. IaaS label rule: keys 1–63 characters of letters, digits, `.`, `_`, `-`, starting and ending with a letter or digit, no reserved `stackit-` prefix; values follow the same shape or are empty. |
| `rules` | `map(object)` | `{}` | Security group rules; see the `rules` object table. |

### `rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `direction` | `string` | — | `ingress` or `egress`. |
| `description` | `string` | `null` | At most 127 characters. |
| `ether_type` | `string` | API default (`IPv4`) | `IPv4` or `IPv6`, case-sensitive. |
| `ip_range` | `string` | `null` | Remote IP range as a CIDR (either family). Omit to match any source/destination. |
| `remote_security_group_id` | `string` | `null` | Remote security group UUID. May be combined with `ip_range` — the API does not enforce exclusivity. |
| `protocol_name` | `string` | `null` | One of `ah`, `dccp`, `egp`, `esp`, `gre`, `icmp`, `igmp`, `ipip`, `ipv6-encap`, `ipv6-frag`, `ipv6-icmp`, `ipv6-nonxt`, `ipv6-opts`, `ipv6-route`, `ospf`, `pgm`, `rsvp`, `sctp`, `tcp`, `udp`, `udplite`, `vrrp`. Mutually exclusive with `protocol_number`. |
| `protocol_number` | `number` | `null` | IP protocol number, 0–255. Mutually exclusive with `protocol_name`. |
| `port_range` | `object({min, max})` | `null` | Port range, 0–65535, `min <= max`. Not allowed with ICMP protocol names. |
| `icmp_parameters` | `object({type, code})` | `null` | ICMP type and code, 0–255 each. Only valid with `protocol_name = "icmp"` or `"ipv6-icmp"`. |

## Outputs

`security_groups` — map of security group key => object:

| Attribute | Description |
|---|---|
| `security_group_id` | Security group UUID. |
| `id` | `"{project_id},{region},{security_group_id}"` — the import ID. |

`rules` — map of rule composite key (`"<group key>.<rule key>"`) => object:

| Attribute | Description |
|---|---|
| `security_group_rule_id` | Rule UUID. |
| `id` | `"{project_id},{region},{security_group_id},{security_group_rule_id}"` — the import ID. |

## Example

```hcl
security_groups = {
  "web" = {
    project_id  = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    name        = "web-sg"
    description = "Allow HTTP/HTTPS from anywhere"
    rules = {
      "http" = {
        direction  = "ingress"
        ether_type = "IPv4"
        protocol_name = "tcp"
        port_range = {
          min = 80
          max = 80
        }
        ip_range = "0.0.0.0/0"
      }
      "https" = {
        direction  = "ingress"
        protocol_name = "tcp"
        port_range = {
          min = 443
          max = 443
        }
      }
    }
  }
  "monitoring" = {
    project_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    name       = "monitoring-sg"
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, and must not contain `.` — rule
  resource addresses and output keys are composed as
  `<group key>.<rule key>` (validated).
- Rules are separate resources and effectively immutable upstream: every
  rule attribute is replace-on-change, so editing a rule replaces it.
  Removing a rule entry destroys it; rules are destroyed before their
  group.
- Replacing a group (changing `stateful`, `region`, `project_id`, or a
  map-key rename) replaces all of its rules with it. A group attached to
  NICs/servers cannot be destroyed, so `stateful`/region changes on an
  attached group fail at the destroy step — detach first or treat the
  group as pinned.
- A rule cannot reference a security group created by the same module
  instance (`remote_security_group_id` is a plain string input). To chain
  groups, use two module instances (separate Terragrunt units, or two
  module blocks in one root with output→input wiring) and pass
  `security_groups["key"].security_group_id` between them.
- Omitted protocol (neither `protocol_name` nor `protocol_number`) means
  the rule matches any protocol; omitted `ip_range` and
  `remote_security_group_id` match any source/destination — matching the
  API's null semantics. Use `protocol_name`, not `protocol_number`, for
  ICMP rules: `icmp_parameters` is restricted to protocol names
  `icmp`/`ipv6-icmp` (mirroring the provider).
- `ether_type` is not enum-validated by the provider — the module
  validates it (`IPv4`/`IPv6`, case-sensitive) so invalid values fail at
  plan time instead of apply.
- Names are not unique per project upstream, so duplicate names across
  entries are allowed; no uniqueness check is enforced.
- The provider floor `>= 0.114.0` is aligned across all stackit modules to
  the latest provider release the modules are tested against; the `region`
  attribute on the security group and rule resources was introduced in
  0.75.0, so no behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_security_group` ← `{project_id},{region},{security_group_id}`

`stackit_security_group_rule` ←
`{project_id},{region},{security_group_id},{security_group_rule_id}`

After importing a rule, state carries both `protocol.name` and
`protocol.number`; the first plan shows a conflict to resolve manually
when the configuration sets only one of the two.
