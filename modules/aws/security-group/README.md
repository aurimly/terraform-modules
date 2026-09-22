# aws/security-group

Map-keyed module for AWS security groups, with ingress and egress rules as
separate `aws_vpc_security_group_ingress_rule` / `aws_vpc_security_group_egress_rule`
resources (the provider's recommended shape) rather than inline blocks.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `security_groups` | `map(object)` | `{}` | Map of security groups keyed by an arbitrary unique identifier; each entry also carries its `ingress` and `egress` rule maps. |

### `security_groups` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Name of the security group in AWS; at most 255 characters. Validated client-side. |
| `description` | `string` | — | Description of the security group in AWS; at most 255 characters (AWS limit). Immutable; changing forces replacement. The provider default ("Managed by Terraform") is deliberately not used. |
| `vpc_id` | `string` | — | VPC the group belongs to (typically `dependency.vpc.outputs.vpc_ids["main"]` with the `aws/vpc` module). Immutable; changing forces replacement. |
| `revoke_rules_on_delete` | `bool` | — | Revoke all rules on delete instead of leaving them to the ENI-owner cleanup path. |
| `tags` | `map(string)` | `{}` | Tags; merged with `Name = name` (consumer tags win on any other key). |
| `ingress` | `map(object)` | `{}` | Inbound rules keyed by an arbitrary rule identifier. |
| `egress` | `map(object)` | `{}` | Outbound rules keyed by an arbitrary rule identifier. Same shape as `ingress`. |

Map keys (groups and rules) must not contain `.` — rule resource addresses
are composed as `<group>.<rule>.<direction>` — validated client-side.

### `ingress` / `egress` rule object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `description` | `string` | — | Rule description (visible in the AWS console). |
| `protocol` | `string` | `tcp` | One of `tcp`, `udp`, `icmp`, `icmpv6`, `-1` (all protocols; ports must then be 0). Validated client-side. |
| `cidr_ipv4` | `string` | — | Source (ingress) or destination (egress) IPv4 CIDR, e.g. `10.0.0.0/8`. Validated client-side. |
| `cidr_ipv6` | `string` | — | IPv6 CIDR, e.g. `::/0`. Validated client-side. |
| `prefix_list_id` | `string` | — | Managed prefix list ID (`pl-...`). |
| `referenced_security_group_id` | `string` | — | Referenced security group ID — set this to the group's own ID for self-referencing rules. |
| `from_port` | `number` | `0` | Base port (0-65535 for tcp/udp; ICMP type for icmp/icmpv6, 0-255). Defaults to 0 — the all-protocols (`-1`) value. |
| `to_port` | `number` | `0` | End port inclusive (ICMP code for icmp/icmpv6 — an independent value from `from_port`). |

Each rule must have **exactly one** source: `cidr_ipv4`, `cidr_ipv6`,
`prefix_list_id` or `referenced_security_group_id` (validated client-side).

## Outputs

`security_group_ids` — map of security group key => security group ID (`sg-...`).
`security_group_arns` — map of security group key => security group ARN.
`security_group_vpc_ids` — map of security group key => VPC ID the group lives in.

## Example

```hcl
security_groups = {
  "app" = {
    name        = "example-app"
    description = "Example application tier"
    vpc_id      = dependency.vpc.outputs.vpc_ids["main"]
    ingress = {
      "https" = {
        description = "HTTPS from anywhere"
        protocol    = "tcp"
        cidr_ipv4   = "0.0.0.0/0"
        from_port   = 443
        to_port     = 443
      }
    }
    egress = {
      "all" = {
        description = "Allow all outbound"
        protocol    = "-1"
        cidr_ipv4   = "0.0.0.0/0"
        from_port   = 0
        to_port     = 0
      }
    }
  }
  "db" = {
    name        = "example-db"
    description = "Example database tier"
    vpc_id      = dependency.vpc.outputs.vpc_ids["main"]
    ingress = {
      "pg-from-app" = {
        description                  = "PostgreSQL from app tier"
        protocol                     = "tcp"
        referenced_security_group_id = "sg-0123456789abcdef0"
        from_port                    = 5432
        to_port                      = 5432
      }
    }
  }
}
```

Referencing one security group in the map from another entry (the `app`
group in the `db` rule above) cannot use the module's own outputs — that
would be a dependency cycle. Pass the referenced group's `sg-…` ID
another way: source it from a separate `aws/security-group` unit's
`security_group_ids` output via a Terragrunt dependency, or use the ID of
a group that already exists and the consumer scenario covers.

## Notes

- **Egress default removal**: when a security group is managed by
  Terraform, the AWS default allow-all egress rule is not present — a
  group with no `egress` entries is locked down, not open. Consumers
  wanting default-like behaviour must add an explicit `egress` rule
  (`cidr_ipv4 = "0.0.0.0/0"`, `protocol = "-1"`, ports 0), as in the
  example above.
- Rules are separate `aws_vpc_security_group_*_rule` resources: removing
  a rule from the input map destroys exactly that rule. Never mix these
  resources with inline `ingress`/`egress` blocks on the same security
  group (inline rules are also processed in attributes-as-blocks mode —
  removing them from config silently leaves the managed rules in place).
- One source per rule. To allow flows from multiple CIDR blocks, use
  multiple rules.
- `name` and `description` on the group plus the rule set are all managed
  by this module; referencing a group's ID is done by a consumer-side
  dependency on this unit's `security_group_ids` output (or another
  unit's), not from an input map.
- Group `vpc_id` and AWS `name`/`description` force replacement if
  changed; rules update in place.

## Import

`aws_security_group` — security group ID only: `sg-xxxxx`.
`aws_vpc_security_group_ingress_rule` — rule ID: `sgr-xxxxx`.
`aws_vpc_security_group_egress_rule` — rule ID: `sgr-xxxxx`.
