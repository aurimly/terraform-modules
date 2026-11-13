variable "account_id" {
  description = "Fallback Cloudflare account ID used when a database omits its own account_id. Must be set if any database omits account_id."
  type        = string
  default     = ""
}

variable "databases" {
  description = "Map of D1 databases keyed by an arbitrary unique identifier. Each entry creates one cloudflare_d1_database; replacing an entry destroys its data."
  type = map(object({
    name                  = string
    account_id            = optional(string)
    jurisdiction          = optional(string)
    primary_location_hint = optional(string)
    read_replication_mode = optional(string)
  }))

  validation {
    condition = alltrue(flatten([
      for key, d in var.databases : [
        for other_key, e in var.databases :
        key == other_key || lower(d.name) != lower(e.name) || ((d.account_id != null && d.account_id != "") ? d.account_id : var.account_id) != ((e.account_id != null && e.account_id != "") ? e.account_id : var.account_id)
      ]
    ]))
    error_message = "database names must be unique within their account, case-insensitively — two entries sharing a resolved account_id and name conflict at apply."
  }

  validation {
    condition     = alltrue([for d in var.databases : d.jurisdiction == null || contains(["eu", "fedramp", "us"], d.jurisdiction)])
    error_message = "jurisdiction must be one of eu, fedramp or us."
  }

  validation {
    condition     = alltrue([for d in var.databases : d.primary_location_hint == null || contains(["wnam", "enam", "weur", "eeur", "apac", "oc"], d.primary_location_hint)])
    error_message = "primary_location_hint must be one of wnam, enam, weur, eeur, apac or oc."
  }

  validation {
    condition     = alltrue([for d in var.databases : d.read_replication_mode == null || contains(["auto", "disabled"], d.read_replication_mode)])
    error_message = "read_replication_mode must be \"auto\" or \"disabled\"."
  }

  validation {
    condition     = alltrue([for d in var.databases : length(trimspace(d.name)) > 0])
    error_message = "name must not be empty or whitespace; it is the database's API identifier and is unique per account."
  }
}
