# stackit/server_service_account_attach

Map-keyed module attaching existing STACKIT service accounts to servers
post-create.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|---|
| `server_service_account_attaches` | `map(object)` | — | Map of service account attachments keyed by an arbitrary unique ID. |

### `server_service_account_attaches` object

| Attribute | Type | Default | Description |
|---|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the server lives in. Changing it replaces the attachment. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the attachment. |
| `server_id` | `string` | — | Server UUID to attach the service account to (e.g. from `stackit/server` outputs). Changing it replaces the attachment. |
| `service_account_email` | `string` | — | Full service account email (e.g. from the stackit/service_account module's output `email`). Changing it replaces the attachment. |

## Outputs

`server_service_account_attaches` — map of server service account
attachment key => object:

| Attribute | Description |
|---|---|
| `id` | `"{project_id},{region},{server_id},{service_account_email}"` — the import ID. |

## Example

```hcl
server_service_account_attaches = {
  "backup-sa" = {
    project_id            = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    region                = "eu01"
    server_id             = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
    service_account_email = "backup-sa-aBc2defg@sa.stackit.cloud"
  }
}
```

## Notes

- Keys are arbitrary unique identifiers.
- Composition: `server_id` from `stackit/server` and
  `service_account_email` from `stackit/service_account` outputs.
- Changing any attribute replaces the attachment; detaching means
  removing the map entry (destroying the resource). The service account
  itself is untouched — only the attachment goes away, which also means
  an attachment can be removed for a service account still in use
  elsewhere.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_server_service_account_attach` ←
`{project_id},{region},{server_id},{service_account_email}`

The region in the import ID must be explicit even when the provider
default region is used.
