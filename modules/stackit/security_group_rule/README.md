# stackit/security_group_rule

Map-keyed module for standalone STACKIT security group rules on existing
security groups.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `security_group_rules` | `map(object)` | — | Map of security group rules keyed by an arbitrary unique ID. |

### `security_group_rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the security group lives in. Changing it replaces the rule. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the rule. |
| `security_group_id` | `string` | — | Security group UUID the rule is created on (e.g. from the stackit/security_group module's output `security_group_id`). Changing it replaces the rule. |
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

`security_group_rules` — map of security group rule key => object:

| Attribute | Description |
|---|---|
| `security_group_rule_id` | Rule UUID. |
| `id` | `"{project_id},{region},{security_group_id},{security_group_rule_id}"` — the import ID. |

## Example

```hcl
security_group_rules = {
  "web-http" = {
    project_id        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    region            = "eu01"
    security_group_id = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
    direction         = "ingress"
    ether_type        = "IPv4"
    protocol_name     = "tcp"
    port_range = {
      min = 80
      max = 80
    }
    ip_range = "0.0.0.0/0"
  }
  "ping" = {
    project_id        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    security_group_id = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
    direction         = "ingress"
    protocol_name     = "icmp"
    icmp_parameters = {
      type = 8
      code = 0
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers.
- The stackit/security_group module only supports inline rules on groups
  it creates itself; this module attaches rules to any existing security
  group — including groups defined in other module instances (pass
  `security_groups["<key>"].security_group_id` via a Terragrunt
  `dependency`, or reference two groups in one root using output→input
  wiring). A rule also cannot reference a remote security group created
  by the same module instance (`remote_security_group_id` is a plain
  string input); chain via two module instances the same way.
- Rules are effectively immutable upstream: every rule attribute is
  replace-on-change, so editing a rule replaces it. Removing the map
  entry destroys the rule.
- Omitted protocol (neither `protocol_name` nor `protocol_number`) means
  the rule matches any protocol; omitted `ip_range` and
  `remote_security_group_id` match any source/destination — matching the
  API's null semantics. Use `protocol_name`, not `protocol_number`, for
  ICMP rules: `icmp_parameters` is restricted to protocol names
  `icmp`/`ipv6-icmp` (mirroring the provider).
- `ether_type` is not enum-validated by the provider — the module
  validates it (`IPv4`/`IPv6`, case-sensitive) so invalid values fail at
  plan time instead of apply.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; the
  `region` attribute on the rule resource was introduced in 0.75.0, so no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_security_group_rule` ←
`{project_id},{region},{security_group_id},{security_group_rule_id}`

The region in the import ID must be explicit even when the provider
default region is used. After importing, state carries both
`protocol.name` and `protocol.number`; the first plan shows a conflict
to resolve manually when the configuration sets only one of the two.
