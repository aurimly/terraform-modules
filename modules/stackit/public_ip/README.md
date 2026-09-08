# stackit/public_ip

Map-keyed module for STACKIT public IP addresses, optionally associated
with a network interface.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `public_ips` | `map(object)` | — | Map of public IPs keyed by an arbitrary unique ID. |

### `public_ips` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the public IP is allocated in. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the resource — a different address is allocated. |
| `network_interface_id` | `string` | `null` | Associates the public IP with a network interface or virtual IP (ID). Associating and disassociating (set to null) are in-place updates. |
| `labels` | `map(string)` | `{}` | Labels attached to the public IP. IaaS label rule: keys 1–63 characters of letters, digits, `.`, `_`, `-`, starting and ending with a letter or digit, no reserved `stackit-` prefix; values follow the same shape or are empty. |

## Outputs

`public_ips` — map of public IP key => object:

| Attribute | Description |
|---|---|
| `public_ip_id` | Public IP UUID. |
| `ip` | The allocated IP address. |
| `id` | `"{project_id},{region},{public_ip_id}"` — the import ID. |

## Example

```hcl
public_ips = {
  "lb" = {
    project_id           = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    region               = "eu01"
    network_interface_id = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
    labels = {
      "env" = "prod"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers; the allocation is regional.
- Destroying this resource — including via a map-key rename or a region
  change, which replace it — releases the address. Re-creation allocates
  a **new** address; DNS records and allowlists pointing at the old IP
  must follow. Plan replacements of this resource deliberately.
- Kubernetes load balancers (and other resources that associate a
  network interface implicitly): use lifecycle `ignore_changes` on
  `network_interface_id` to prevent unintentional removal of the network
  interface due to state drift. The module cannot set lifecycle blocks
  conditionally, so this is consumer-side:

  ```hcl
  lifecycle {
    ignore_changes = [network_interface_id]
  }
  ```

- The dedicated `stackit_public_ip_associate` resource is out of scope;
  association here is the `network_interface_id` attribute.
- The provider floor `>= 0.114.0` is aligned across all stackit modules to
  the latest provider release the modules are tested against; the `region`
  attribute on the public IP resource was introduced in 0.75.0, so no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_public_ip` ← `{project_id},{region},{public_ip_id}`

If the imported public IP is associated with a network interface, the
configuration must set `network_interface_id` to that value (or apply
`ignore_changes` on it) — otherwise the first apply sends a null
interface and **disassociates the IP**, which for a Kubernetes load
balancer means an outage. The same applies to labels: entries imported
with labels but no `labels` in the configuration lose them on the next
apply.
