variable "account_id" {
  description = "Fallback Cloudflare account ID used when a zone omits its own account_id. Must be set if any zone omits account_id."
  type        = string
  default     = ""
}

variable "zones" {
  description = "Map of Cloudflare zones keyed by zone name. Each entry may carry its own account_id, the zone type, a paused flag, and a map of zone settings (setting_id => value)."
  type = map(object({
    account_id = optional(string)
    type       = optional(string, "full")
    paused     = optional(bool, false)
    settings   = optional(map(string), {})
  }))
}
