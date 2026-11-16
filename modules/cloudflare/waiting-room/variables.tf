variable "zone_id" {
  description = "Cloudflare zone ID the waiting rooms belong to. Waiting rooms are zone-scoped only — there is no account-level resource in v5."
  type        = string
}

variable "waiting_rooms" {
  description = "Map of Cloudflare Waiting Rooms keyed by an arbitrary unique identifier. Each entry creates one cloudflare_waiting_room; events reference rooms by these keys."
  type = map(object({
    host                      = string
    name                      = string
    new_users_per_minute      = number
    total_active_users        = number
    path                      = optional(string)
    description               = optional(string)
    queue_all                 = optional(bool)
    queueing_method           = optional(string)
    queueing_status_code      = optional(number)
    session_duration          = optional(number)
    suspended                 = optional(bool)
    disable_session_renewal   = optional(bool)
    custom_page_html          = optional(string)
    default_template_language = optional(string)
    cookie_suffix             = optional(string)
    cookie_attributes = optional(object({
      samesite = optional(string)
      secure   = optional(string)
    }))
    additional_routes = optional(list(object({
      host = string
      path = string
    })))
    enabled_origin_commands = optional(list(string))
    json_response_enabled   = optional(bool)
    turnstile_mode          = optional(string)
    turnstile_action        = optional(string)
  }))

  validation {
    condition = alltrue([
      for key in keys(var.waiting_rooms) : can(regex("^[^.]+$", key))
    ])
    error_message = "waiting room map keys must not contain '.' — event resource addresses are composed as <room-key>.<event-key>."
  }

  validation {
    condition     = alltrue([for r in var.waiting_rooms : length(trimspace(r.host)) > 0 && !can(regex("://", r.host))])
    error_message = "host must be a non-empty hostname without a scheme — do not include http:// or https://."
  }

  validation {
    condition     = alltrue([for r in var.waiting_rooms : can(regex("^[A-Za-z0-9_-]+$", r.name))])
    error_message = "name must contain only letters, digits, hyphens and underscores."
  }

  validation {
    condition = alltrue(flatten([
      for key, r in var.waiting_rooms : [
        for other_key, o in var.waiting_rooms :
        key == other_key || lower(r.name) != lower(o.name)
      ]
    ]))
    error_message = "waiting room names must be unique within the zone, case-insensitively — two entries sharing a name conflict at apply."
  }

  validation {
    condition = alltrue(flatten([
      for key, r in var.waiting_rooms : [
        for other_key, o in var.waiting_rooms :
        key == other_key || lower(r.host) != lower(o.host) || coalesce(r.path, "/") != coalesce(o.path, "/")
      ]
    ]))
    error_message = "the host and path combination must be unique across waiting rooms, case-insensitively (an unset path counts as \"/\") — the API rejects a second room on the same route."
  }

  validation {
    condition     = alltrue([for r in var.waiting_rooms : r.new_users_per_minute > 0 && r.total_active_users > 0])
    error_message = "new_users_per_minute and total_active_users must be positive — they are the per-minute and total-session baselines for the route."
  }

  validation {
    condition     = alltrue([for r in var.waiting_rooms : r.queueing_method == null || contains(["fifo", "random", "passthrough", "reject"], r.queueing_method)])
    error_message = "queueing_method must be one of fifo, random, passthrough or reject."
  }

  validation {
    condition     = alltrue([for r in var.waiting_rooms : r.queueing_status_code == null || contains([200, 202, 429], r.queueing_status_code)])
    error_message = "queueing_status_code must be one of 200, 202 or 429."
  }

  validation {
    condition     = alltrue([for r in var.waiting_rooms : r.turnstile_mode == null || contains(["off", "invisible", "visible_non_interactive", "visible_managed"], r.turnstile_mode)])
    error_message = "turnstile_mode must be one of off, invisible, visible_non_interactive or visible_managed."
  }

  validation {
    condition     = alltrue([for r in var.waiting_rooms : r.turnstile_action == null || contains(["log", "infinite_queue"], r.turnstile_action)])
    error_message = "turnstile_action must be log or infinite_queue."
  }

  validation {
    condition = alltrue([
      for r in var.waiting_rooms : r.cookie_attributes == null || r.cookie_attributes.samesite == null || contains(["auto", "lax", "none", "strict"], r.cookie_attributes.samesite)
    ])
    error_message = "cookie_attributes.samesite must be one of auto, lax, none or strict."
  }

  validation {
    condition = alltrue([
      for r in var.waiting_rooms : r.cookie_attributes == null || r.cookie_attributes.secure == null || contains(["auto", "always", "never"], r.cookie_attributes.secure)
    ])
    error_message = "cookie_attributes.secure must be one of auto, always or never."
  }

  validation {
    condition = alltrue([
      for r in var.waiting_rooms : r.default_template_language == null || contains([
        "en-US", "es-ES", "de-DE", "fr-FR", "it-IT", "ja-JP", "ko-KR", "pt-BR",
        "zh-CN", "zh-TW", "nl-NL", "pl-PL", "id-ID", "tr-TR", "ar-EG", "ru-RU",
        "fa-IR", "bg-BG", "hr-HR", "cs-CZ", "da-DK", "fi-FI", "lt-LT", "lv-LV",
        "ms-MY", "nb-NO", "ro-RO", "el-GR", "he-IL", "hi-IN", "hu-HU", "sr-BA",
        "sk-SK", "sl-SI", "sv-SE", "tl-PH", "th-TH", "uk-UA", "vi-VN",
      ], r.default_template_language)
    ])
    error_message = "default_template_language must be one of the locales supported by the default page template (e.g. en-US, es-ES, de-DE, fr-FR, ja-JP, zh-CN)."
  }

  validation {
    condition = alltrue([
      for r in var.waiting_rooms : r.additional_routes == null || length(r.additional_routes) == 0 || (r.cookie_suffix != null && length(trimspace(r.cookie_suffix)) > 0)
    ])
    error_message = "cookie_suffix is required when additional_routes is set — per-route cookies need a distinguishing suffix in their name."
  }
}

variable "events" {
  description = "Map of waiting room events keyed by an arbitrary unique identifier. Each entry creates one cloudflare_waiting_room_event attached to the room named by room_key. Overrides apply only while the event is active; total_active_users and new_users_per_minute must be set together or neither."
  type = map(object({
    room_key                = string
    name                    = string
    event_start_time        = string
    event_end_time          = string
    prequeue_start_time     = optional(string)
    description             = optional(string)
    new_users_per_minute    = optional(number)
    total_active_users      = optional(number)
    queueing_method         = optional(string)
    session_duration        = optional(number)
    suspended               = optional(bool)
    disable_session_renewal = optional(bool)
    custom_page_html        = optional(string)
    shuffle_at_event_start  = optional(bool)
    turnstile_mode          = optional(string)
    turnstile_action        = optional(string)
  }))

  validation {
    condition = alltrue([
      for key in keys(var.events) : can(regex("^[^.]+$", key)) && alltrue([
        for event_key, event in var.events : can(regex("^[^.]+$", event.room_key))
      ])
    ])
    error_message = "event map keys and room_key values must not contain '.' — event resource addresses are composed as <room-key>.<event-key>."
  }

  validation {
    condition = alltrue([
      for event_key, event in var.events : contains(keys(var.waiting_rooms), event.room_key)
    ])
    error_message = "room_key must name an entry of var.waiting_rooms — events are wired to rooms managed by this module; a dangling key fails at plan with this message instead of an index error."
  }

  validation {
    condition     = alltrue([for e in var.events : length(trimspace(e.name)) > 0 && can(regex("^[A-Za-z0-9_-]+$", e.name))])
    error_message = "event name must be non-empty and contain only letters, digits, hyphens and underscores."
  }

  validation {
    condition = alltrue(flatten([
      for key, e in var.events : [
        for other_key, o in var.events :
        key == other_key || e.room_key != o.room_key || lower(e.name) != lower(o.name)
      ]
    ]))
    error_message = "event names must be unique within their waiting room, case-insensitively — two events sharing a room and name conflict at apply."
  }

  validation {
    condition = alltrue([
      for e in var.events : (e.new_users_per_minute == null) == (e.total_active_users == null)
    ])
    error_message = "new_users_per_minute and total_active_users must be set together or neither — the API rejects a lone override."
  }

  validation {
    condition     = alltrue([for e in var.events : e.queueing_method == null || contains(["fifo", "random", "passthrough", "reject"], e.queueing_method)])
    error_message = "queueing_method must be one of fifo, random, passthrough or reject."
  }

  validation {
    condition     = alltrue([for e in var.events : e.turnstile_mode == null || contains(["off", "invisible", "visible_non_interactive", "visible_managed"], e.turnstile_mode)])
    error_message = "turnstile_mode must be one of off, invisible, visible_non_interactive or visible_managed."
  }

  validation {
    condition     = alltrue([for e in var.events : e.turnstile_action == null || contains(["log", "infinite_queue"], e.turnstile_action)])
    error_message = "turnstile_action must be log or infinite_queue."
  }

  validation {
    condition = alltrue([
      for e in var.events : e.shuffle_at_event_start == null || e.shuffle_at_event_start == false || e.prequeue_start_time != null
    ])
    error_message = "shuffle_at_event_start requires prequeue_start_time — there must be a prequeue to shuffle when the event starts."
  }
}
