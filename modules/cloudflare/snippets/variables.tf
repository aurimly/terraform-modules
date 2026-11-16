variable "zone_id" {
  description = "Cloudflare zone ID the snippets and rules belong to. This module owns the zone's whole snippet rule list."
  type        = string
}

variable "snippets" {
  description = "Map of Cloudflare Snippets keyed by an arbitrary unique identifier. Each entry creates one cloudflare_snippet; rules reference snippets by snippet_name. Snippet content is JavaScript; the file named by main_module (or the first file) is the entry point."
  type = map(object({
    snippet_name = string
    files        = list(object({ name = string, content = string }))
    main_module  = optional(string)
  }))

  validation {
    condition     = alltrue([for s in var.snippets : length(trimspace(s.snippet_name)) > 0])
    error_message = "snippet_name must not be empty or whitespace; it is the snippet's identifier in the zone and its import key."
  }

  validation {
    condition     = alltrue([for s in var.snippets : can(regex("^[A-Za-z0-9_-]+$", s.snippet_name))])
    error_message = "snippet_name must contain only letters, digits, hyphens and underscores (Cloudflare API restriction)."
  }

  validation {
    condition = alltrue(flatten([
      for key, s in var.snippets : [
        for other_key, o in var.snippets :
        key == other_key || lower(s.snippet_name) != lower(o.snippet_name)
      ]
    ]))
    error_message = "snippet_name must be unique within the zone, case-insensitively — Cloudflare identifies snippets by name, so two entries sharing a name conflict at apply."
  }

  validation {
    condition     = alltrue([for s in var.snippets : length(s.files) > 0])
    error_message = "files must contain at least one entry — a snippet without files has no entry point to run."
  }

  validation {
    condition     = alltrue([for s in var.snippets : alltrue([for f in s.files : length(trimspace(f.name)) > 0 && length(f.content) > 0])])
    error_message = "files entries must have a non-empty name and non-empty content — each entry is one JavaScript file of the snippet."
  }

  validation {
    condition = alltrue([
      for s in var.snippets : s.main_module == null || contains([for f in s.files : f.name], s.main_module)
    ])
    error_message = "main_module must name one of the entries in files — the API runs the snippet with that file as its entry point."
  }
}

variable "rules" {
  description = "Ordered list of zone snippet rules. Order-preserving list, not map-keyed like the rest of this repo — the upstream resource is a single ordered list per zone and rules evaluate in the listed order, so a map would force an invented ordering attribute. The module replaces the zone's whole rule list on every change; two consumers of this module for the same zone conflict."
  type = list(object({
    expression   = string
    snippet_name = string
    description  = optional(string)
    enabled      = optional(bool)
  }))

  validation {
    condition     = alltrue([for r in var.rules : length(trimspace(r.expression)) > 0])
    error_message = "expression must not be empty; it is the Cloudflare Rules language expression that triggers the snippet."
  }

  validation {
    condition = alltrue([
      for r in var.rules : contains([for s in values(var.snippets) : s.snippet_name], r.snippet_name)
    ])
    error_message = "snippet_name must name a snippet managed by this module — the rules resource owns the zone's whole rule list, so a rule pointing at a snippet outside var.snippets would be unmanageable here."
  }
}
