variable "affinity_groups" {
  description = "Map of STACKIT affinity groups keyed by an arbitrary identifier. Each entry creates one affinity group."
  type = map(object({
    project_id = string
    name       = string
    policy     = string
    region     = optional(string)
  }))

  validation {
    condition     = alltrue([for g in var.affinity_groups : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", g.project_id))])
    error_message = "project_id must be a STACKIT project UUID."
  }

  validation {
    condition     = alltrue([for g in var.affinity_groups : length(g.name) >= 1 && length(g.name) <= 63 && can(regex("^[A-Za-z0-9]+((-|_|\\s|\\.)[A-Za-z0-9]+)*$", g.name))])
    error_message = "name must be 1 to 63 characters, start and end with a letter or digit, and contain only letters, digits, hyphens, underscores, dots and whitespace in between (the IaaS name rule)."
  }

  validation {
    condition     = alltrue([for g in var.affinity_groups : contains(["hard-affinity", "hard-anti-affinity", "soft-affinity", "soft-anti-affinity"], g.policy)])
    error_message = "policy must be one of hard-affinity, hard-anti-affinity, soft-affinity or soft-anti-affinity."
  }
}
