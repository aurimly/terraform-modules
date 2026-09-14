# stackit/server_volume_attach

Map-keyed module attaching existing STACKIT volumes to servers
post-create.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `server_volume_attaches` | `map(object)` | — | Map of volume attachments keyed by an arbitrary unique ID. |

### `server_volume_attaches` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the server and volume live in. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the attachment. |
| `server_id` | `string` | — | Server UUID to attach the volume to (e.g. from `stackit/server` outputs). Changing it replaces the attachment. |
| `volume_id` | `string` | — | Volume UUID to attach (e.g. from `stackit/volume` outputs). Changing it replaces the attachment. |

## Outputs

`server_volume_attaches` — map of server volume attachment key => object:

| Attribute | Description |
|---|---|
| `id` | `"{project_id},{region},{server_id},{volume_id}"` — the import ID. |

## Example

```hcl
server_volume_attaches = {
  "data-disk" = {
    project_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    region     = "eu01"
    server_id  = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
    volume_id  = "zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz"
  }
}
```

## Notes

- Keys are arbitrary unique identifiers.
- The `stackit/server` module has no attach-at-create volume list beyond
  `boot_volume`, so this module is the way to attach a data volume to a
  server post-create without touching the server.
- Composition: `server_id` from `stackit/server` and `volume_id` from
  `stackit/volume` outputs.
- Changing any attribute replaces the attachment; detaching means
  removing the map entry (destroying the resource). The volume and its
  data are not deleted — only the attachment goes away.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_server_volume_attach` ← `{project_id},{region},{server_id},{volume_id}`

The region in the import ID must be explicit even when the provider
default region is used.
