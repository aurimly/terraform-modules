# stackit/server_update_schedule

Map-keyed module for STACKIT server update schedules with maintenance
windows. Schedules use the RFC 5545 rrule format, **not** cron. Explicitly
pair with stackit/server_update_enable: schedule resources currently
auto-enable the update service, and that implicit enable is removed
28.09.2026.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `server_update_schedules` | `map(object)` | — | Map of update schedules keyed by an arbitrary unique ID. |

### `server_update_schedules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID (validated). Changing it replaces the schedule. |
| `server_id` | `string` | — | UUID of the server the schedule runs on (validated). Changing it replaces the schedule. |
| `name` | `string` | — | Schedule name, 1–255 characters (validated). Changing it replaces the schedule. |
| `rrule` | `string` | — | RFC 5545 iCalendar RRULE string, validated plan-time by the provider via rrule-go. Changing it replaces the schedule. |
| `enabled` | `bool` | — | Whether the schedule is active. Updates in place. |
| `maintenance_window` | `number` | — | Hour of day (1–24, validated) within which the server update may start. Updates in place. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the schedule. |

## Outputs

`server_update_schedules` — map of schedule key => object:

| Attribute | Description |
|---|---|
| `update_schedule_id` | Schedule ID. |
| `id` | `"{project_id},{region},{server_id},{update_schedule_id}"` — the import ID. |

## Example

```hcl
module "server_update_enable" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/server_update_enable?ref=v1.20.0"

  server_update_enables = {
    "app" = {
      project_id = "12345678-1234-1234-1234-123456789012"
      server_id  = module.server.servers["app"].server_id
      region     = "eu01"
    }
  }
}

module "server_update_schedule" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/server_update_schedule?ref=v1.20.0"

  server_update_schedules = {
    "app-monthly" = {
      project_id         = "12345678-1234-1234-1234-123456789012"
      server_id          = module.server.servers["app"].server_id
      name               = "example-monthly-update"
      rrule              = "DTSTART;TZID=Europe/Berlin:20250101T023000 RRULE:FREQ=MONTHLY;BYMONTHDAY=1"
      enabled            = true
      maintenance_window = 2
      region             = "eu01"
    }
  }

  depends_on = [module.server_update_enable]
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
- **Pair with stackit/server_update_enable.** The schedule resource
  implicitly enables the update service, that behavior is deprecated
  and removed **28.09.2026** — after that, a schedule without an
  explicit enable fails. The example wires `depends_on`.
- `maintenance_window` semantics: hour 1–24 when the update may start —
  an update can still exceed the window (including stopping at a restart).
- `name`, `rrule`, `project_id`, `server_id`, `region` are
  replace-on-change; `enabled` and `maintenance_window` update in place.
- **Import**: see the Import section; the 4-part ID format includes
  region.
- Plan-time validations mirror the provider's plan-time validators
  (UUIDs, name 1–255, maintenance window 1–24). No module-side rrule
  regex — the provider's rrule-go validation is stricter and a
  module-side regex would be weaker and misleading.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_server_update_schedule` ←
`{project_id},{region},{server_id},{update_schedule_id}`
