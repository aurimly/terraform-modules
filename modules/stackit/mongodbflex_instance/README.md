# stackit/mongodbflex_instance

Map-keyed module for STACKIT MongoDB Flex instances.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `instances` | `map(object)` | — | Map of instances keyed by an arbitrary unique ID. |

### `instances` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the instance is created in (validated). Changing it replaces the instance. |
| `name` | `string` | — | Instance name: starts with a lowercase letter, lowercase letters/digits/hyphens only, no trailing hyphen (validated). Updates in place. |
| `acl` | `list(string)` | — | Access control list for the instance: non-empty list of valid IPv4 CIDRs (validated). Updates in place. |
| `flavor` | `object` | — | `{cpu, ram}` — CPU (cores) and RAM (GB) of the instance. Updates in place. |
| `replicas` | `number` | — | Number of MongoDB replicas. Changing it replaces the instance. |
| `storage` | `object` | — | `{class, size}`; see the `storage` object table. |
| `version` | `string` | — | MongoDB version (e.g. `7.0`). |
| `backup_schedule` | `string` | — | Backup schedule as a cron expression, five fields (validated). Updates in place. |
| `options` | `object` | — | Backup/HA options; see the `options` object table. |
| `region` | `string` | `null` | Resource region. **Required at apply time: the resource requires a region set here or in the provider's configuration.** Changing it replaces the instance. |

### `storage` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `class` | `string` | — | Storage class (e.g. `premium-perf2-mongodb`); list available classes via `stackit mongodbflex options --storages --flavor-id FLAVOR_ID` (STACKIT CLI). Changing it replaces the instance. |
| `size` | `number` | — | Storage size in gigabytes, at least 1 (validated). Updates in place. |

### `options` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `type` | `string` | — | Instance type: `Replica`, `Sharded` or `Single` (validated). Changing it replaces the instance. |
| `point_in_time_window_hours` | `number` | — | Hours back in time point-in-time recovery can reach. Updates in place. |
| `snapshot_retention_days` | `number` | `null` | Retention of continuous backups (driven by `backup_schedule`). Updates in place. |
| `daily_snapshot_retention_days` | `number` | `null` | Retention of daily backups. Updates in place. |
| `weekly_snapshot_retention_weeks` | `number` | `null` | Retention of weekly backups. Updates in place. |
| `monthly_snapshot_retention_months` | `number` | `null` | Retention of monthly backups. Updates in place. |

## Outputs

`instances` — map of instance key => object:

| Attribute | Description |
|---|---|
| `instance_id` | Instance ID (e.g. referenced by stackit/mongodbflex_user). |
| `id` | `"{project_id},{region},{instance_id}"` — the import ID. |

## Example

```hcl
module "mongodbflex_instance" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/mongodbflex_instance?ref=v1.19.0"

  instances = {
    "app-db" = {
      project_id = "12345678-1234-1234-1234-123456789012"
      name       = "example-app-db"
      acl        = ["10.0.0.0/8"]
      flavor = {
        cpu = 1
        ram = 4
      }
      replicas = 1
      storage = {
        class = "premium-perf2-mongodb"
        size  = 10
      }
      version         = "7.0"
      backup_schedule = "0 0 * * *"
      options = {
        type                       = "Single"
        snapshot_retention_days    = 3
        point_in_time_window_hours = 30
      }
      region = "eu01"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not names.
- Unlike stackit/postgresflex_instance this resource takes the cpu/ram
  `flavor` block (the computed `id`/`description` attributes are
  provider-managed and not inputs here) — there is no `flavor_id`
  variant in MongoDB Flex.
- **`region` must be set in one of the two places** (module input or
  provider config) — the resource requires a region at apply time.
- **Renaming a map key destroys and recreates the instance — data loss
  risk.** The same applies to changing `project_id`, `region`,
  `replicas`, `storage.class` or `options.type`.
- `name`, `acl`, `storage.size`, `version`, `backup_schedule`,
  `flavor.{cpu,ram}` and the `options` retention values update in place.
- Database users and their passwords are managed via
  stackit/mongodbflex_user; this module exposes no credentials.
- Plan-time validations mirror the provider's plan-time validators
  (UUID, name rule) plus, as forward-checking beyond the provider's
  validators (which fail only at apply or warn): non-empty IPv4 CIDR
  ACL, `options.type` enum, storage-size bound, and the five-field cron
  shape for `backup_schedule`.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_mongodbflex_instance` ← `{project_id},{region},{instance_id}`
