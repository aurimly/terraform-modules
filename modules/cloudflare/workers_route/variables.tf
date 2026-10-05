variable "zone_id" {
  description = "Fallback zone ID used when a route omits its own zone_id. Must be set if any route omits zone_id."
  type        = string
  default     = ""
}

variable "routes" {
  description = "Map of Workers routes keyed by an arbitrary unique identifier. Omit script to create a route with no Worker attached."
  type = map(object({
    pattern = string
    script  = optional(string)
    zone_id = optional(string)
  }))
}
