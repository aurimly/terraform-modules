# stackit/server

Map-keyed module for STACKIT servers (virtual machines), booting from an
image ID or from a boot volume.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `servers` | `map(object)` | — | Map of servers keyed by an arbitrary unique ID. |

### `servers` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Server name; validated against the server name rule (1–63 characters, starts/ends with a letter or digit; only `-` and `.` allowed in between — no underscores, slashes or spaces, unlike other IaaS resource names). |
| `project_id` | `string` | — | STACKIT project UUID the server is created in. Changing it replaces the server. |
| `machine_type` | `string` | — | Machine flavor (e.g. `s3.2xlarge.8`). Changing it replaces the server. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the server. |
| `availability_zone` | `string` | `null` | Availability zone (e.g. `eu01-3`). Changing it replaces the server. |
| `image_id` | `string` | `null` | Image UUID to boot from (e.g. the `image_id` output of `modules/stackit/image`). Exactly one of `image_id` or `boot_volume` must be set. Changing it replaces the server. |
| `boot_volume` | `object` | `null` | Boot volume definition, see sub-table. Exactly one of `image_id` or `boot_volume` must be set. |
| `network_interface_ids` | `list(string)` | `null` | Network interface UUIDs to attach (created with `stackit_network_interface` — not yet a repo module). Changing the list replaces the server. |
| `keypair_name` | `string` | `null` | Name of an existing STACKIT key pair (see `modules/stackit/key_pair`). Changing it replaces the server. |
| `affinity_group` | `string` | `null` | Affinity group UUID. Changing it replaces the server. |
| `user_data` | `string` | `null` | Cloud-init user data. Changing it replaces the server. Pass it via `sensitive()` from consumer config when it contains secrets. |
| `desired_status` | `string` | `null` | Target power state: `active`, `inactive` or `deallocated`. In-place update. `deallocated` stops billing for the machine. |
| `agent_provisioning_policy` | `string` | `null` | STACKIT agent provisioning policy: `ALWAYS`, `NEVER` or `INHERIT`. Changing it replaces the server. |
| `labels` | `map(string)` | `{}` | Labels attached to the server. IaaS label rule: keys 1–63 characters of letters, digits, `.`, `_`, `-`, starting and ending with a letter or digit, no reserved `stackit-` prefix; values follow the same shape or are empty. In-place update. |

### `boot_volume` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `source_type` | `string` | — | `volume` or `image`. |
| `source_id` | `string` | — | UUID of the volume or image to boot from. |
| `size` | `number` | `null` | Boot volume size in GB. Required when `source_type` is `image`. |
| `performance_class` | `string` | `null` | e.g. `storage_premium_perf1`, `storage_premium_perf2`, `storage_standard`. |
| `delete_on_termination` | `bool` | API default (`false`) | Delete the boot volume with the server. Only allowed when `source_type` is `image`. |

## Outputs

`servers` — map of server key => object:

| Attribute | Description |
|---|---|
| `server_id` | Server UUID. |
| `created_at` | Server creation timestamp. |
| `launched_at` | Server launch timestamp. |
| `updated_at` | Server last-update timestamp. |
| `id` | `"{project_id},{region},{server_id}"` — the import ID. |

## Example

```hcl
servers = {
  "app" = {
    project_id        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    region            = "eu01"
    name              = "app-server"
    machine_type      = "s3.2xlarge.8"
    availability_zone = "eu01-3"
    image_id          = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    keypair_name      = "deploy-key"
    network_interface_ids = [
      "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    ]
    labels = {
      "env" = "prod"
    }
  }
  "boot-from-volume" = {
    project_id        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    region            = "eu01"
    name              = "app-server-2"
    machine_type      = "s3.2xlarge.8"
    availability_zone = "eu01-3"
    boot_volume = {
      source_type       = "volume"
      source_id         = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      performance_class = "storage_premium_perf2"
    }
    network_interface_ids = [
      "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    ]
  }
}
```

## Notes

- The IaaS (Compute Engine) service must be enabled on the STACKIT
  project before servers can be created — unlike some other STACKIT
  services, creating IaaS resources does not auto-enable it.
- The create surface is replace-heavy: `machine_type`,
  `availability_zone`, `region`, `image_id`, `boot_volume`,
  `network_interface_ids`, `keypair_name`, `affinity_group`,
  `user_data`, `agent_provisioning_policy` all replace the server when
  changed. Only `labels` and `desired_status` update in place — plan
  flavor changes accordingly.
- `network_interfaces` is optional in the provider schema but the
  provider warns that creating a server without network interfaces
  causes problems when you want to (re-)create it. Attach at least one
  interface in practice.
- Network interfaces are created with `stackit_network_interface`,
  which is not yet a repo module — reference existing interface IDs
  from consumer config or another source for now.
- Exactly one of `image_id` or `boot_volume` must be set (provider
  conflict rule).
- The server `name` rule is stricter than other IaaS resources:
  separators may only be `-` and `.` — no underscores or spaces.
- `desired_status` is an in-place power-state management attribute;
  `deallocated` stops billing for the machine while preserving the
  volumes.
- `user_data` is not marked sensitive by the provider; pass it via
  `sensitive()` from consumer config when it embeds secrets.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_server` ← `{project_id},{region},{server_id}`
