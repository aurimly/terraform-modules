variable "network_lists" {
  description = "Map of network lists keyed by an arbitrary unique identifier. Keys only pick the for_each instance and appear in resource addresses and outputs; the name inside the entry is what the API sees."
  type = map(object({
    name        = string
    type        = string
    description = string
    list        = optional(list(string), [])
    mode        = string
    contract_id = optional(string)
    group_id    = optional(number)
    activation = optional(object({
      network             = string
      notes               = optional(string)
      notification_emails = list(string)
    }))
  }))

  validation {
    condition     = alltrue([for l in var.network_lists : contains(["IP", "GEO"], l.type)])
    error_message = "type must be one of IP, GEO."
  }

  validation {
    condition     = alltrue([for l in var.network_lists : contains(["APPEND", "REPLACE", "REMOVE"], l.mode)])
    error_message = "mode must be one of APPEND, REPLACE, REMOVE (per-apply delta operation; initial creation uses APPEND)."
  }

  validation {
    condition     = alltrue([for l in var.network_lists : alltrue([for e in l.list : length(e) >= 1])])
    error_message = "list entries must be non-empty strings."
  }

  validation {
    condition = alltrue([for l in var.network_lists : l.type != "IP" || alltrue([for e in l.list :
    can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(/([0-9]|[1-2][0-9]|3[0-2]))?$", e)) || can(regex("^[0-9a-fA-F:]+(/[0-9]{1,3})?$", e))])])
    error_message = "IP list entries must look like IPv4 addresses or CIDRs (with a /0-32 prefix) or IPv6 addresses or prefixes (kept permissive: the API is the final arbiter)."
  }

  validation {
    condition = alltrue([for l in var.network_lists : l.type != "GEO" || alltrue([for e in l.list :
    can(regex("^[A-Za-z]{2,3}$", e))])])
    error_message = "GEO list entries must be EdgeScape country codes (2-3 letters; shape check only — the API is the final arbiter)."
  }

  validation {
    condition     = length(distinct([for l in var.network_lists : lower(l.name)])) == length(var.network_lists)
    error_message = "list names must be unique ignoring case: Akamai list IDs embed the name, and renaming a list replaces its activation (network_list_id is force-new)."
  }

  validation {
    condition     = alltrue([for l in var.network_lists : l.activation == null || contains(["STAGING", "PRODUCTION"], l.activation.network)])
    error_message = "activation.network must be one of STAGING, PRODUCTION (module policy; the provider passes the value through and defaults to STAGING)."
  }

  validation {
    condition     = alltrue([for l in var.network_lists : l.activation == null || length(l.activation.notification_emails) >= 1])
    error_message = "activation.notification_emails must contain at least one email address when activation is set."
  }
}
