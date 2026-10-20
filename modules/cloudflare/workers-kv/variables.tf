variable "account_id" {
  description = "Fallback Cloudflare account ID used when a namespace omits its own account_id. Must be set if any namespace omits account_id."
  type        = string
  default     = ""
}

variable "namespaces" {
  description = "Map of Workers KV namespaces keyed by an arbitrary unique identifier."
  type = map(object({
    title        = string
    account_id   = optional(string)
    jurisdiction = optional(string)
    mode         = optional(string)
  }))

  validation {
    condition     = alltrue([for n in var.namespaces : n.jurisdiction == null || contains(["eu", "fedramp", "us"], n.jurisdiction)])
    error_message = "jurisdiction must be one of eu, fedramp or us."
  }

  validation {
    condition     = alltrue([for n in var.namespaces : n.mode == null || n.mode == "instant"])
    error_message = "mode must be \"instant\" (KV Instant namespace) or omitted for a classic namespace."
  }
}
