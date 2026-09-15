# stackit/server_backup_schedule

Map-keyed module for STACKIT server backup schedules. Schedules use the
RFC 5545 rrule format, **not** cron — unlike stackit/postgresflex_instance
and stackit/mongodbflex_instance. Explicitly pair with
stackit/server_backup_enable: schedule resources currently auto-enable
the backup service, and that implicit enable is removed 26.09.2026.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `server_backup_schedules` | `map(object)` | — | Map of backup schedules keyed by an arbitrary unique ID. |

### `server_backup_schedules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID (validated). Changing it replaces the schedule. |
| `server_id` | `string` | — | UUID of the server the schedule runs on (validated). Changing it replaces the schedule. |
| `name` | `string` | — | Schedule name, 1–255 characters (validated). Changing it replaces the schedule. |
| `rrule` | `string` | — | RFC 5545 iCalendar RRULE string, validated plan-time by the provider via rrule-go. Changing it replaces the schedule. |
| `enabled` | `bool` | — | Whether the schedule is active. Updates in place. |
| `backup_properties` | `object` | — | `{name, retention_period, volume_ids}`; see the `backup_properties` table. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the schedule. |

### `backup_properties` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Backup name. Updates in place. |
| `retention_period` | `number` | — | Backup retention in days, at least 1 (validated). Updates in place. |
| `volume_ids` | `list(string)` | `null` | Volume UUIDs to back up; when unset the provider sends null (all volumes). Updates in place. |

## Outputs

`server_backup_schedules` — map of schedule key => object:

| Attribute | Description |
|---|---|
| `backup_schedule_id` | Schedule ID. |
| `id` | `"{project_id},{region},{server_id},{backup_schedule_id}"` — the import ID. |

## Example

```hcl
module "server_backup_enable" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/server_backup_enable?ref=v1.20.0"

  server_backup_enables = {
    "app" = {
      project_id = "12345678-1234-1234-1234-123456789012"
      server_id  = module.server.servers["app"].server_id
      region     = "eu01"
    }
  }
}

module "server_backup_schedule" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/server_backup_schedule?ref=v1.20.0"

  server_backup_schedules = {
    "app-daily" = {
      project_id = "12345678-1234-1234-1234-123456789012"
      server_id  = module.server.servers["app"].server_id
      name       = "example-daily-backup"
      rrule      = "DTSTART;TZID=Europe/Berlin:20250101T023000 RRULE:FREQ=DAILY;INTERVAL=1"
      enabled    = true
      backup_properties = {
        name             = "example-app-daily"
        retention_period = 7
      }
      region = "eu01"
    }
  }

  depends_on = [module.server_backup_enable]
}
```

## Notes

- Keys are arbitrary unique identifiers, not names.
- **The rrule is RFC 5545, not cron.** The rrule string is parsed and
  validated plan-time by the provider (rrule-go; spaces are normalized
  to newlines before parsing).
- **Commas are not allowed in the rrule string** (the provider applies
  NoSeparator validation, and the RFC 5545 separator is `,`) — this
  blocks multi-day sequences like `RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE`.
  One schedule entry per day or a single-day rule instead.
- **Pair with stackit/server_backup_enable.** The schedule resource
  implicitly enables the backup service, that behavior is deprecated
  and removed **26.09.2026** — after that, a schedule without an
  explicit enable fails. The example wires `depends_on`.
- **Deleting a schedule can disable the backup service** — when the API
  reports no backups existing on the server (checked via ListBackups
  first), the provider's delete path also disables the backup service,
  even if other schedules would remain. Destructive on a server with no
  existing backups; with backups present, only the schedule is removed.
- `name`, `rrule`, `project_id`, `server_id`, `region` are
  replace-on-change; `enabled` and the `backup_properties` fields
  update in place.
- **Import**: see the Import section; the 4-part ID format includes
  region.
- Plan-time validations mirror the provider's plan-time validators
  (UUIDs, name 1–255, retention >= 1, non-empty volume_ids when set).
  No module-side rrule regex — the provider's rrule-go validation is
  stricter and a module-side regex would be weaker and misleading.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_server_backup_schedule` ←
`{project_id},{region},{server_id},{backup_schedule_id}`
