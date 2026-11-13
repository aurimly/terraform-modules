variable "rules" {
  description = "Map of zone email routing rules keyed by an arbitrary unique identifier. Each entry creates one cloudflare_email_routing_rule in the zone named by zone_id."
  type = map(object({
    zone_id = string
    matchers = list(object({
      type  = string
      field = optional(string)
      value = optional(string)
    }))
    actions = list(object({
      type  = string
      value = optional(list(string))
    }))
    enabled          = optional(bool)
    name             = optional(string)
    priority         = optional(number)
    source           = optional(string)
    owner_worker_tag = optional(string)
  }))

  validation {
    condition = alltrue(flatten([
      for rule_key, rule in var.rules : [
        for matcher in rule.matchers :
        contains(["all", "literal"], matcher.type) &&
        (matcher.type != "literal" || (matcher.field == "to" && matcher.value != null && length(trimspace(matcher.value)) > 0))
      ]
    ]))
    error_message = "matchers must be type \"all\" or \"literal\"; literal matchers require field \"to\" and a non-empty value (the exact address to match)."
  }

  validation {
    condition = alltrue(flatten([
      for rule_key, rule in var.rules : [
        for action in rule.actions :
        contains(["drop", "forward", "worker"], action.type) &&
        (action.type == "drop" ? action.value == null || length(action.value) == 0 : length(coalesce(action.value, [])) == 1)
      ]
    ]))
    error_message = "actions must be type drop, forward or worker; drop carries no value, forward carries exactly one destination address, worker carries exactly one Worker name (the API limits value to a single entry)."
  }

  validation {
    condition = alltrue([
      for rule_key, rule in var.rules : rule.source == null || contains(["api", "wrangler"], rule.source)
    ])
    error_message = "source must be \"api\" or \"wrangler\"; the provider defaults to \"api\" when omitted."
  }

  validation {
    condition = alltrue([
      for rule_key, rule in var.rules : rule.source != "wrangler" || rule.owner_worker_tag != null && length(trimspace(rule.owner_worker_tag)) > 0
    ])
    error_message = "rules with source \"wrangler\" must set owner_worker_tag — the public tag of the Worker that owns the rule."
  }

  validation {
    condition = alltrue([
      for rule_key, rule in var.rules : length(trimspace(rule.zone_id)) > 0
    ])
    error_message = "zone_id must not be empty — feed the cloudflare/zone module's zone_ids output."
  }
}

variable "catch_all_rules" {
  description = "Map of zone catch-all email routing rules keyed by an arbitrary unique identifier. Each entry creates one cloudflare_email_routing_catch_all for the zone named by zone_id — a zone carries exactly one catch-all, and its matcher is fixed to \"all\"."
  type = map(object({
    zone_id = string
    actions = list(object({
      type  = string
      value = optional(list(string))
    }))
    enabled          = optional(bool)
    name             = optional(string)
    source           = optional(string)
    owner_worker_tag = optional(string)
  }))

  validation {
    condition = alltrue(flatten([
      for rule_key, rule in var.catch_all_rules : [
        for other_key, other in var.catch_all_rules :
        rule_key == other_key || lower(rule.zone_id) != lower(other.zone_id)
      ]
    ]))
    error_message = "a zone carries exactly one catch-all rule — two entries pointing at the same zone_id (case-insensitively) conflict at apply."
  }

  validation {
    condition = alltrue(flatten([
      for rule_key, rule in var.catch_all_rules : [
        for action in rule.actions :
        contains(["drop", "forward", "worker"], action.type) &&
        (action.type == "drop" ? action.value == null || length(action.value) == 0 : length(coalesce(action.value, [])) == 1)
      ]
    ]))
    error_message = "actions must be type drop, forward or worker; drop carries no value, forward carries exactly one destination address, worker carries exactly one Worker name (the API limits value to a single entry)."
  }

  validation {
    condition = alltrue([
      for rule_key, rule in var.catch_all_rules : rule.source == null || contains(["api", "wrangler"], rule.source)
    ])
    error_message = "source must be \"api\" or \"wrangler\"; the provider defaults to \"api\" when omitted."
  }

  validation {
    condition = alltrue([
      for rule_key, rule in var.catch_all_rules : rule.source != "wrangler" || rule.owner_worker_tag != null && length(trimspace(rule.owner_worker_tag)) > 0
    ])
    error_message = "rules with source \"wrangler\" must set owner_worker_tag — the public tag of the Worker that owns the rule."
  }

  validation {
    condition = alltrue([
      for rule_key, rule in var.catch_all_rules : length(trimspace(rule.zone_id)) > 0
    ])
    error_message = "zone_id must not be empty — feed the cloudflare/zone module's zone_ids output."
  }
}
