variable "placement_groups" {
  description = "Map of Hetzner Cloud placement groups keyed by an arbitrary identifier. Each entry creates one placement group."
  type = map(object({
    name   = string
    type   = string
    labels = optional(map(string), {})
  }))

  validation {
    condition     = alltrue([for pg in var.placement_groups : pg.type == "spread"])
    error_message = "type must be spread (the only placement group type the API supports)."
  }

  validation {
    condition     = length(distinct([for pg in var.placement_groups : pg.name])) == length(var.placement_groups)
    error_message = "name must be unique per project; the map contains duplicate names."
  }

  validation {
    condition     = alltrue([for pg in var.placement_groups : alltrue([for l in keys(pg.labels) : can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,253}[a-zA-Z0-9])?/[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", l)) || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", l)) && length(l) <= 63])])
    error_message = "labels keys must be valid: start and end with a letter or digit, may contain dots, underscores and hyphens; optionally a '<prefix>/' prefix (prefix up to 254 characters)."
  }

  validation {
    condition     = alltrue([for pg in var.placement_groups : alltrue([for v in pg.labels : v == "" || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", v))])])
    error_message = "labels values must be at most 63 characters, start and end with a letter or digit, and may contain dots, underscores and hyphens in-between; values may be empty."
  }
}
