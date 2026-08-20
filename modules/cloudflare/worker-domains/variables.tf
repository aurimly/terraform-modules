variable "account_id" {
  description = "Cloudflare account ID that owns the Workers custom domains."
  type        = string
}

variable "zone_id" {
  description = "Fallback zone ID used when a domain omits its own."
  type        = string
  default     = ""
}

variable "domains" {
  description = "Map of Workers custom domains keyed by hostname. Each entry binds a hostname to a Worker service."
  type = map(object({
    service   = string
    zone_id   = optional(string)
    zone_name = optional(string)
  }))
}
