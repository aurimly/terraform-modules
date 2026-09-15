# stackit/server_update_enable

Map-keyed module enabling the STACKIT server update service for existing
servers. Pair with stackit/server_update_schedule for the update
schedules themselves; use this module to enable the service explicitly —
starting 28.09.2026 schedule resources no longer enable it implicitly.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `server_update_enables` | `map(object)` | — | Map of update enablements keyed by an arbitrary unique ID. |

### `server_update_enables` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID (validated). Changing it replaces the enable. |
| `server_id` | `string` | — | UUID of the server to enable updates on (validated). Changing it replaces the enable. |
| `update_policy_id` | `string` | `null` | UUID of the update policy to apply (validated). Changing it fails at apply — the provider does not support updating this resource; recreate the entry (or rollover the map key) instead. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the enable. |

## Outputs

`server_update_enables` — map of enable key => object:

| Attribute | Description |
|---|---|
| `enabled` | API-reported enablement state (bool). |
| `id` | `"{project_id},{server_id},{region}"`. |

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
```

## Notes

- Keys are arbitrary unique identifiers, not names.
- **Use only one enable resource per server** — a duplicate enable is
  tolerated at create (the API answers 409 "already enabled" and the
  provider accepts it), but only one window should own the service
  state.
- **destroy actually disables the update service** — the provider calls
  the API's disable endpoint on delete, this is a real cloud-side
  effect, not a state-only removal. Removing the map entry (or renaming
  its key) destroys and recreates: updates turn off and back on with a
  brief gap in between.
- **The implicit enable in schedule resources is deprecated and will be
  removed 28.09.2026.** Run this module alongside
  stackit/server_update_schedule (see its README example for the
  `depends_on` wiring) — after that date a schedule without an enable
  fails.
- **Import is not supported** for this resource by the provider — there
  is no import path; adopt existing servers by recreating the enable.
- Plan-time validations mirror the provider's plan-time validators
  (UUIDs for `project_id`/`server_id`/`update_policy_id`). The
  `update_policy_id` update failure is not caught plan-time — the
  provider declares in-place updates for `update_policy_id` but its
  update path always errors.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.
