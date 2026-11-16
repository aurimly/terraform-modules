# cloudflare/waiting-room

Map-keyed module for Cloudflare Waiting Rooms in one zone. Each entry
creates one `cloudflare_waiting_room`; events attach to rooms as
`cloudflare_waiting_room_event` keyed by `room_key`. Waiting rooms are
zone-scoped only — there is no account-level resource.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `zone_id` | `string` | — | Cloudflare zone ID the waiting rooms belong to. |
| `waiting_rooms` | `map(object)` | — | Map of waiting rooms keyed by an arbitrary unique ID. |
| `events` | `map(object)` | — | Map of events keyed by an arbitrary unique ID; `room_key` wires each event to a room. |

Plan-time validation: map keys and `room_key` contain no `.` (composed
addresses); `host` is non-empty and scheme-free; `name` contains only
letters, digits, hyphens and underscores and is unique within the zone;
the host+path combination is unique, case-insensitively (unset path
counts as `/`); `new_users_per_minute` and `total_active_users` are
positive; `queueing_method` is `fifo`/`random`/`passthrough`/`reject`;
`queueing_status_code` is 200/202/429; `turnstile_mode` is
`off`/`invisible`/`visible_non_interactive`/`visible_managed`;
`turnstile_action` is `log`/`infinite_queue`; `cookie_attributes.samesite`
is `auto`/`lax`/`none`/`strict` and `.secure` is `auto`/`always`/`never`;
`default_template_language` is one of the supported locales; and
`additional_routes` requires `cookie_suffix`.

### `waiting_rooms` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `host` | `string` | — | Hostname the room applies to — no scheme, no wildcards; the host+path combination must be unique. |
| `name` | `string` | — | Unique room name (letters, digits, hyphens, underscores). |
| `new_users_per_minute` | `number` | — | Baseline of new users let in per minute. |
| `total_active_users` | `number` | — | Baseline of total active user sessions on the route. |
| `path` | `string` | `null` | Path on the host to enable the room on (subpaths included; no wildcards or query parameters). |
| `description` | `string` | `null` | Free-form note. |
| `queue_all` | `bool` | `null` | Queue all traffic; no one reaches the origin while set. |
| `queueing_method` | `string` | `null` | `fifo` (default), `random`, `passthrough` or `reject`. Changing from the default requires Waiting Room Advanced. |
| `queueing_status_code` | `number` | `null` | Status code returned while queued: 200, 202 or 429. |
| `session_duration` | `number` | `null` | Lifetime of the accepted-user cookie, in minutes. |
| `suspended` | `bool` | `null` | Suspend the room (traffic skips it). |
| `disable_session_renewal` | `bool` | `null` | Do not renew session cookies on every request (Advanced). |
| `custom_page_html` | `string` | `null` | Mustache template rendered at the edge (Advanced). |
| `default_template_language` | `string` | `null` | Locale of the default page template, e.g. `en-US`, `es-ES`, `de-DE`. Defaults to `en-US` upstream. |
| `cookie_suffix` | `string` | `null` | Suffix appended to the waiting-room cookie name. Required with `additional_routes`. |
| `cookie_attributes` | `object` | `null` | `{samesite, secure}` attributes of the waiting-room cookie. |
| `additional_routes` | `list(object)` | `null` | Extra `{host, path}` combinations the room applies to (Advanced). |
| `enabled_origin_commands` | `list(string)` | `null` | Enabled origin commands (e.g. `revoke`). |
| `json_response_enabled` | `bool` | `null` | Serve a JSON status object to `Accept: application/json` requests (Advanced). |
| `turnstile_mode` | `string` | `null` | Turnstile widget type: `off`, `invisible`, `visible_non_interactive`, `visible_managed`. |
| `turnstile_action` | `string` | `null` | `log` or `infinite_queue`. |

### `events` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `room_key` | `string` | — | Key of a room in `waiting_rooms`. |
| `name` | `string` | — | Event name (letters, digits, hyphens, underscores); unique within its room. |
| `event_start_time` | `string` | — | ISO 8601 timestamp the event starts. |
| `event_end_time` | `string` | — | ISO 8601 timestamp the event ends. |
| `prequeue_start_time` | `string` | `null` | Timestamp to start queueing users before `event_start_time`. |
| `description` | `string` | `null` | Free-form note. |
| `new_users_per_minute` | `number` | `null` | Override while active; must be set together with `total_active_users`. |
| `total_active_users` | `number` | `null` | Override while active; must be set together with `new_users_per_minute`. |
| `queueing_method` | `string` | `null` | Override while active: `fifo`, `random`, `passthrough`, `reject`. |
| `session_duration` | `number` | `null` | Override while active. |
| `suspended` | `bool` | `null` | Override while active. |
| `disable_session_renewal` | `bool` | `null` | Override while active. |
| `custom_page_html` | `string` | `null` | Override while active. |
| `shuffle_at_event_start` | `bool` | `null` | Shuffle the prequeue randomly when the event starts; requires `prequeue_start_time`. |
| `turnstile_mode` | `string` | `null` | Override while active. |
| `turnstile_action` | `string` | `null` | Override while active. |

## Outputs

| Name | Description |
|---|---|
| `waiting_room_ids` | Map of room key => waiting room ID. |
| `event_ids` | Map of `<room-key>.<event-key>` => event ID. |

## Example

```hcl
zone_id = "023e105f4ecef8ad9ca31a8372d0c353"

waiting_rooms = {
  "shop" = {
    host                 = "shop.example.com"
    name                 = "launch"
    new_users_per_minute = 200
    total_active_users   = 200
    path                 = "/checkout"
    cookie_suffix        = "shop"
    cookie_attributes = {
      samesite = "auto"
      secure   = "auto"
    }
  }
}

events = {
  "release" = {
    room_key            = "shop"
    name                = "black-friday"
    event_start_time    = "2026-11-27T00:00:00Z"
    event_end_time      = "2026-11-27T23:59:59Z"
    prequeue_start_time = "2026-11-26T22:00:00Z"
    total_active_users  = 500
    new_users_per_minute = 250
  }
}
```

## Notes

- Waiting rooms are zone-scoped only; `zone_id` is the module's scope.
- `custom_page_html`, `additional_routes`, `json_response_enabled`,
  `disable_session_renewal` and non-default `queueing_method` values (and
  the `infinite_queue` Turnstile action, and Turnstile modes other than
  `off`/`invisible`) require the Waiting Room Advanced subscription — the
  module passes them through, and plans on other plans still validate.
- Event attributes override the room only while the event is active
  (including its prequeue window). Timing constraints apply upstream: the
  event must start at least one minute before it ends, and a
  `prequeue_start_time` must be at least five minutes before the event
  start — misaligned timestamps are rejected at apply.
- `next_event_start_time`/`next_event_prequeue_start_time` are read-only
  and event-driven — they change outside Terraform and are not outputs.
- The zone's single-room `waiting_room_rules` (Advanced bypass rules) and
  zone-level `waiting_room_settings` (search-engine crawler bypass) are
  not covered by this module; they are natural follow-ups if needed.
- The caller needs `Waiting Rooms Edit` on the zone (the provider's
  permission list names Waiting Rooms Read/Write).

## Import

`cloudflare_waiting_room` ← `<zone_id>/<waiting_room_id>`, e.g.
`023e105f4ecef8ad9ca31a8372d0c353/a1b2c3d4-5e6f-7a8b-9c0d-1e2f3a4b5c6d`.

`cloudflare_waiting_room_event` ←
`<zone_id>/<waiting_room_id>/<event_id>`, e.g.
`023e105f4ecef8ad9ca31a8372d0c353/a1b2c3d4-5e6f-7a8b-9c0d-1e2f3a4b5c6d/b2c3d4e5-6f7a-8b9c-0d1e-2f3a4b5c6d7e`.
