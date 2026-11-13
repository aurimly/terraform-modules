variable "account_id" {
  description = "Fallback Cloudflare account ID used when a widget omits its own account_id. Must be set if any widget omits account_id."
  type        = string
  default     = ""
}

variable "widgets" {
  description = "Map of Turnstile widgets keyed by an arbitrary unique identifier. Each entry creates one cloudflare_turnstile_widget; widget names are not unique by design — the key disambiguates them."
  type = map(object({
    name            = string
    domains         = list(string)
    mode            = string
    account_id      = optional(string)
    bot_fight_mode  = optional(bool)
    clearance_level = optional(string)
    ephemeral_id    = optional(bool)
    offlabel        = optional(bool)
    region          = optional(string)
  }))

  validation {
    condition     = alltrue([for w in var.widgets : length(trimspace(w.name)) > 0])
    error_message = "name must not be empty or whitespace; it is the human-readable widget identifier in the dashboard."
  }

  validation {
    condition     = alltrue([for w in var.widgets : alltrue([for domain in w.domains : length(trimspace(domain)) > 0])])
    error_message = "domains entries must be non-empty hostnames; the list itself may be empty for widgets used off-web (mobile apps)."
  }

  validation {
    condition     = alltrue([for w in var.widgets : contains(["managed", "non-interactive", "invisible"], w.mode)])
    error_message = "mode must be one of managed, non-interactive or invisible."
  }

  validation {
    condition     = alltrue([for w in var.widgets : w.clearance_level == null || contains(["no_clearance", "jschallenge", "managed", "interactive"], w.clearance_level)])
    error_message = "clearance_level must be one of no_clearance, jschallenge, managed or interactive."
  }

  validation {
    condition     = alltrue([for w in var.widgets : w.region == null || contains(["world", "china"], w.region)])
    error_message = "region must be \"world\" or \"china\"; it cannot be changed after creation."
  }
}
