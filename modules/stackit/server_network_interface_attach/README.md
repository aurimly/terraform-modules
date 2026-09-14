# stackit/server_network_interface_attach

Map-keyed module attaching existing STACKIT network interfaces to
servers post-create. The attachment only takes full effect after a
server reboot.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `server_network_interface_attaches` | `map(object)` | — | Map of network interface attachments keyed by an arbitrary unique ID. |

### `server_network_interface_attaches` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the server and network interface live in. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the attachment. |
| `server_id` | `string` | — | Server UUID to attach the interface to (e.g. from `stackit/server` outputs). Changing it replaces the attachment. |
| `network_interface_id` | `string` | — | Network interface UUID to attach (e.g. from `stackit/network_interface` outputs). Changing it replaces the attachment. |

## Outputs

`server_network_interface_attaches` — map of server network interface
attachment key => object:

| Attribute | Description |
|---|---|
| `id` | `"{project_id},{region},{server_id},{network_interface_id}"` — the import ID. |

## Example

```hcl
server_network_interface_attaches = {
  "app-second-nic" = {
    project_id           = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    region               = "eu01"
    server_id            = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
    network_interface_id = "zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz"
  }
}
```

## Notes

- Keys are arbitrary unique identifiers.
- The attachment only takes full effect after the server reboots —
  plan a reboot after apply.
- Alternative: `stackit/server` `network_interface_ids` attaches
  interfaces at create time, but changing that list **replaces the
  server**; this module attaches post-create without server
  replacement. Do not manage the same server/interface pair with both.
- Composition: `server_id` from `stackit/server` and
  `network_interface_id` from `stackit/network_interface` outputs.
- Changing any attribute replaces the attachment; detaching means
  removing the map entry (destroying the resource). The interface
  itself is not deleted.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_server_network_interface_attach` ← `{project_id},{region},{server_id},{network_interface_id}`

The region in the import ID must be explicit even when the provider
default region is used.
