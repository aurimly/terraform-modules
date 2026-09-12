# stackit/network_interface

Map-keyed module for STACKIT network interfaces (ports) in a network,
with explicit IPv4, security groups, and allowed address pairs.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `network_interfaces` | `map(object)` | — | Map of network interfaces keyed by an arbitrary unique ID. |

### `network_interfaces` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the interface is created in. Changing it replaces the interface. |
| `network_id` | `string` | — | Network UUID the interface is attached to. Changing it replaces the interface. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the interface. |
| `name` | `string` | `null` | Interface name (1–63 characters, IaaS name rule). If unset, STACKIT assigns one. In-place update. |
| `ipv4` | `string` | `null` | IPv4 address to assign. If unset, one is drawn from the network's pool. Changing it **replaces** the interface (new MAC and ID). |
| `allowed_addresses` | `list(string)` | `null` | Additional source CIDRs allowed to send traffic from this interface (allowed address pairs), IPv4 or IPv6. In-place update. |
| `security` | `bool` | API default (`true`) | Whether security groups apply to the interface. When set to `false`, `security_group_ids` must be empty (rejected at plan time; the provider only errors at apply). In-place update. |
| `security_group_ids` | `list(string)` | `null` | Security group UUIDs attached to the interface, e.g. from the `stackit/security_group` outputs. In-place update. |
| `labels` | `map(string)` | `{}` | Labels attached to the interface. IaaS label rule: keys 1–63 characters of letters, digits, `.`, `_`, `-`, starting and ending with a letter or digit, no reserved `stackit-` prefix; values follow the same shape or are empty. |

## Outputs

`network_interfaces` — map of network interface key => object:

| Attribute | Description |
|---|---|
| `network_interface_id` | Network interface UUID — feed into `stackit/server` `network_interface_ids` or `stackit/public_ip` `network_interface_id`. |
| `ipv4` | The assigned IPv4 address. |
| `mac` | The interface MAC address. |
| `device` | Device UUID the interface is attached to. |
| `type` | Interface type (`server`, `metadata` or `gateway`) — assigned by the platform, not settable. |
| `id` | `"{project_id},{region},{network_id},{network_interface_id}"` — the import ID. |

## Example

```hcl
network_interfaces = {
  "app-nic" = {
    project_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    network_id = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
    region     = "eu01"
    name       = "app-nic"
    security_group_ids = [
      "zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz",
    ]
    labels = {
      "env" = "prod"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not interface names.
- Composition: take `network_id` from `stackit/network` and
  `security_group_ids` from `stackit/security_group`; feed the output
  `network_interface_id` into `stackit/server` `network_interface_ids`
  and `stackit/public_ip` `network_interface_id`.
- Egress NAT is a composition pattern, not a managed resource: STACKIT
  IaaS has no NAT gateway resource. The pattern is a dedicated
  interface in the target network, a public IP associated to it via
  `stackit/public_ip` `network_interface_id`, and routing-table routes
  pointing at the interface's IP as next hop. The platform may mark
  such an interface with the `gateway` type; `type` is computed and
  cannot be set through the provider.
- Replacements: `project_id`, `network_id`, `region` and `ipv4`
  replace the interface when changed — a new MAC address is issued and
  DHCP/static references, server attachments and public IP
  associations must follow. Everything else updates in place.
- `name`, `ipv4`, `security`, `security_group_ids` and
  `allowed_addresses` are Optional+Computed upstream: leaving them
  unset lets STACKIT assign values (auto name, auto IP from the
  network pool, `security = true`). After an import, set them
  explicitly or the next apply may drift — see the import section.
- An interface still attached to a server cannot be deleted upstream;
  detach it (and any associated public IP) before destroying an entry.
- Plan-time validations mirror the provider rules; IP/CIDR checks use
  Terraform's IP functions so they match the provider's parser.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  attribute in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_network_interface` ← `{project_id},{region},{network_id},{network_interface_id}`

Because `name`, `ipv4`, `security`, `security_group_ids` and
`allowed_addresses` are Optional+Computed, an imported interface must
have those attributes pinned in the configuration to their imported
values — otherwise the first apply sends nulls and may rename the
interface, release the assigned IP, or clear its security groups.
