variable "zones" {
  description = "Map of Azure DNS zones keyed by an arbitrary identifier. Each entry creates one DNS zone in the named resource group — either public or private, selected by the `private` flag. Zone names must be unique within their resource group; private zones additionally feed `virtual_network_links`."
  type = map(object({
    name                = string
    resource_group_name = string
    private             = optional(bool, false)
    soa_record = optional(object({
      email        = string
      expire_time  = optional(number)
      minimum_ttl  = optional(number)
      refresh_time = optional(number)
      retry_time   = optional(number)
      ttl          = optional(number)
    }))
    virtual_network_links = optional(map(object({
      name                 = string
      virtual_network_id   = string
      registration_enabled = optional(bool, false)
      tags                 = optional(map(string), {})
    })), {})
    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for zone in var.zones : can(regex("^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\\.)+[a-z]{2,63}\\.?$", zone.name))
    ])
    error_message = "name must be a valid DNS zone name — one or more lowercase-alphanumeric/hyphen labels separated by dots and ending in an alphabetic TLD, e.g. \"example.com\", \"platform.internal.example.com\"; a single trailing dot is accepted and normalized by the API. Case is lowercased by Azure — the module expects lowercase input."
  }

  validation {
    condition = alltrue([
      for zone in var.zones : length(trimspace(zone.name)) > 0 && length(trimspace(zone.resource_group_name)) > 0
    ])
    error_message = "name and resource_group_name must not be empty or whitespace."
  }

  validation {
    condition = alltrue(flatten([
      for key, zone in var.zones : [
        for other_key, other in var.zones :
        key == other_key || lower("${zone.name}|${zone.resource_group_name}") != lower("${other.name}|${other.resource_group_name}")
      ]
    ]))
    error_message = "zone names must be unique across entries when combined with their resource_group_name, case-insensitively — Azure scopes zone names per resource group, not globally, so the same zone name in two resource groups is valid."
  }

  validation {
    condition = alltrue([
      for key in keys(var.zones) : !can(regex("\\.", key))
    ])
    error_message = "zone map keys must not contain \".\" — keys are composed into link identifiers of the form \"<zone_key>.<link_key>\" and a dot would make outputs ambiguous and flattened keys collision-prone."
  }

  validation {
    condition = alltrue([
      for zone in var.zones : zone.private || length(zone.virtual_network_links) == 0
    ])
    error_message = "virtual_network_links are only valid on private zones — public zones have no VPC integration; set private = true or drop the links."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.zones : [
        length(distinct([for link in zone.virtual_network_links : lower(link.name)])) == length(zone.virtual_network_links)
      ]
    ]))
    error_message = "virtual_network_links names must be unique within their zone, case-insensitively — two link entries naming the same link resource address one ARM object and collide at apply with a 409 from ARM."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.zones : [
        for link in zone.virtual_network_links : length(trimspace(link.name)) > 0 && can(regex("^/", link.virtual_network_id))
      ]
    ]))
    error_message = "each virtual_network_links entry needs a non-empty name and a full ARM virtual network resource ID in virtual_network_id (starts with \"/\", typically from the azure/virtual-network module)."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.zones : [
        for link_key in keys(zone.virtual_network_links) : !can(regex("\\.", link_key))
      ]
    ]))
    error_message = "virtual_network_links map keys must not contain \".\" — they are composed into output identifiers of the form \"<zone_key>.<link_key>\"."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.zones : [
        for other_key, other in zone.soa_record != null ? [zone.soa_record] : [null] :
        other == null || length(trimspace(other.email)) > 0
      ]
    ]))
    error_message = "soa_record, when set, needs the zone operator mailbox in email (hostmaster form, e.g. \"hostmaster.example.com\" — the leftmost label is the @ at the Azure API)."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.zones : [
        for soa in zone.soa_record != null ? [zone.soa_record] : [null] :
        soa == null || (soa.expire_time == null || soa.expire_time >= 0)
        && (soa.minimum_ttl == null || soa.minimum_ttl >= 0)
        && (soa.refresh_time == null || soa.refresh_time >= 0)
        && (soa.retry_time == null || soa.retry_time >= 0)
        && (soa.ttl == null || soa.ttl >= 0)
      ]
    ]))
    error_message = "soa_record timings (expire_time, minimum_ttl, refresh_time, retry_time, ttl) must be zero or positive seconds — the SOA defaults are only written when these keys exist; leave values out to keep the Azure defaults."
  }

  validation {
    condition = alltrue([
      for zone in var.zones : length(zone.tags) <= 50 && alltrue([for k, v in zone.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "zone tags are limited to 50 entries, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.zones : [
        for link in zone.virtual_network_links : length(link.tags) <= 50 && alltrue([for k, v in link.tags : length(k) <= 512 && length(v) <= 256])
      ]
    ]))
    error_message = "link tags are limited to 50 entries, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}
