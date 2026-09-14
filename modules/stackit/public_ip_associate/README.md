# stackit/public_ip_associate

Map-keyed module associating an existing STACKIT public IP with a
network interface.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `public_ip_associates` | `map(object)` | — | Map of public IP associations keyed by an arbitrary unique ID. |

### `public_ip_associates` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the public IP and network interface live in. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the association. |
| `public_ip_id` | `string` | — | Existing public IP UUID to associate. Changing it replaces the association. |
| `network_interface_id` | `string` | — | Network interface (or virtual IP) UUID to attach the public IP to. Changing it replaces the association. |

## Outputs

`public_ip_associates` — map of public IP association key => object:

| Attribute | Description |
|---|---|
| `ip` | The associated IP address. |
| `id` | `"{project_id},{region},{public_ip_id},{network_interface_id}"` — the import ID. |

## Example

```hcl
public_ip_associates = {
  "lb-nic" = {
    project_id           = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    region               = "eu01"
    public_ip_id         = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
    network_interface_id = "zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz"
  }
}
```

## Notes

- Do **not** use this module together with `stackit/public_ip` for the
  same public IP or the same network interface — both control the
  association and **will conflict**. Pick one: allocate and associate
  via `stackit/public_ip` `network_interface_id`, or associate a
  pre-allocated IP with this module.
- Keys are arbitrary unique identifiers; the association is regional.
- Composition: `public_ip_id` from `stackit/public_ip` outputs (IP
  allocated without association) or from a pre-allocated IP imported
  consumer-side; `network_interface_id` from `stackit/network_interface`
  outputs.
- Changing any attribute replaces the association; detaching means
  removing the map entry (destroying the resource). The underlying
  public IP and network interface are not touched.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_public_ip_associate` ← `{project_id},{region},{public_ip_id},{network_interface_id}`

The region in the import ID must be explicit even when the provider
default region is used.
