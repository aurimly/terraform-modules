variable "private_endpoints" {
  description = "Map of Azure private endpoints keyed by an arbitrary identifier. Each entry creates one azurerm_private_endpoint with its service connection, and optionally a DNS zone group and static IP configurations."
  type = map(object({
    name                          = string
    resource_group_name           = string
    location                      = string
    subnet_id                     = string
    custom_network_interface_name = optional(string)
    edge_zone                     = optional(string)
    private_service_connection = object({
      name                              = string
      is_manual_connection              = bool
      private_connection_resource_id    = optional(string)
      private_connection_resource_alias = optional(string)
      subresource_names                 = optional(list(string), [])
      request_message                   = optional(string)
    })
    private_dns_zone_group = optional(object({
      name                 = optional(string, "default")
      private_dns_zone_ids = list(string)
    }))
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
      subresource_name   = optional(string)
      member_name        = optional(string)
    })), {})
    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for endpoint in var.private_endpoints : length(trimspace(endpoint.name)) > 0 && length(trimspace(endpoint.resource_group_name)) > 0 && length(trimspace(endpoint.location)) > 0
    ])
    error_message = "name, resource_group_name and location must not be empty or whitespace."
  }

  validation {
    condition = alltrue([
      for endpoint in var.private_endpoints : can(regex("^/", endpoint.subnet_id))
    ])
    error_message = "subnet_id must be a full ARM resource ID (starts with \"/\") — typically the subnet_ids output of the azure/subnet module."
  }

  validation {
    condition = alltrue([
      for endpoint in var.private_endpoints :
      (endpoint.private_service_connection.private_connection_resource_id == null || trimspace(endpoint.private_service_connection.private_connection_resource_id) == "") !=
      (endpoint.private_service_connection.private_connection_resource_alias == null || trimspace(endpoint.private_service_connection.private_connection_resource_alias) == "")
    ])
    error_message = "private_service_connection needs exactly one of private_connection_resource_id or private_connection_resource_alias — the provider requires one of them."
  }

  validation {
    condition = alltrue([
      for endpoint in var.private_endpoints :
      endpoint.private_service_connection.request_message == null || endpoint.private_service_connection.is_manual_connection
    ])
    error_message = "request_message is only valid when is_manual_connection is true — automatic connections are approved by RBAC and carry no message."
  }

  validation {
    condition = alltrue([
      for endpoint in var.private_endpoints :
      length(endpoint.private_service_connection.request_message) <= 140
      if endpoint.private_service_connection.request_message != null
    ])
    error_message = "request_message is limited to 140 characters by the provider itself (individual services may impose smaller limits, e.g. 128 for SQL)."
  }

  validation {
    condition = alltrue(flatten([
      for endpoint in var.private_endpoints : [
        for id in endpoint.private_dns_zone_group != null ? endpoint.private_dns_zone_group.private_dns_zone_ids : [] : can(regex("^/", id))
      ]
    ]))
    error_message = "private_dns_zone_group.private_dns_zone_ids entries must be non-empty full ARM resource IDs (start with \"/\") — zone IDs from the azure/dns-zone module or this module's private_dns_zone_ids output."
  }

  validation {
    condition = alltrue([
      for endpoint in var.private_endpoints : length(endpoint.tags) <= 50 && alltrue([for k, v in endpoint.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "endpoint tags are limited to 50 entries, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}

variable "private_dns_zones" {
  description = "Map of private DNS zones keyed by an arbitrary identifier, optional alongside the endpoints — for when the zone handling lives in the same stack instead of being supplied from the azure/dns-zone module. Each entry creates one azurerm_private_dns_zone with its SOA record and virtual network links."
  type = map(object({
    name                = string
    resource_group_name = string
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
      resolution_policy    = optional(string)
      tags                 = optional(map(string), {})
    })), {})
    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for zone in var.private_dns_zones : can(regex("^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\\.)+[a-z]{2,63}\\.?$", zone.name))
    ])
    error_message = "name must be a valid DNS zone name — one or more lowercase-alphanumeric/hyphen labels separated by dots and ending in an alphabetic TLD, e.g. \"privatelink.blob.core.windows.net\"; a single trailing dot is accepted and normalized by the API. Case is lowercased by Azure — the module expects lowercase input."
  }

  validation {
    condition = alltrue([
      for zone in var.private_dns_zones : length(trimspace(zone.name)) > 0 && length(trimspace(zone.resource_group_name)) > 0
    ])
    error_message = "name and resource_group_name must not be empty or whitespace."
  }

  validation {
    condition = alltrue(flatten([
      for key, zone in var.private_dns_zones : [
        for other_key, other in var.private_dns_zones :
        key == other_key || lower("${zone.name}|${zone.resource_group_name}") != lower("${other.name}|${other.resource_group_name}")
      ]
    ]))
    error_message = "zone names must be unique across entries when paired with their resource_group_name, case-insensitively — Azure scopes zone names per resource group, so the same zone name in two resource groups is valid."
  }

  validation {
    condition = alltrue([
      for zone in var.private_dns_zones : !anytrue([for link_key in keys(zone.virtual_network_links) : can(regex("\\.", link_key))])
    ])
    error_message = "virtual_network_links map keys must not contain \".\" — they are composed into output identifiers of the form \"<zone_key>.<link_key>\"."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.private_dns_zones : [
        length(distinct([for link in zone.virtual_network_links : lower(link.name)])) == length(zone.virtual_network_links)
      ]
    ]))
    error_message = "virtual_network_links names must be unique within their zone, case-insensitively — two link entries naming the same link resource address one ARM object and collide at apply with a 409 from ARM."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.private_dns_zones : [
        for link in zone.virtual_network_links : length(trimspace(link.name)) > 0 && can(regex("^/", link.virtual_network_id))
      ]
    ]))
    error_message = "each virtual_network_links entry needs a non-empty name and a full ARM virtual network resource ID in virtual_network_id (starts with \"/\")."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.private_dns_zones : [
        for link in zone.virtual_network_links : link.resolution_policy == null || contains(["Default", "NxDomainRedirect"], link.resolution_policy)
      ]
    ]))
    error_message = "virtual_network_links resolution_policy, when set, must be one of Default or NxDomainRedirect (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.private_dns_zones : [
        for soa in zone.soa_record != null ? [zone.soa_record] : [null] :
        soa == null || length(trimspace(soa.email)) > 0
      ]
    ]))
    error_message = "soa_record, when set, needs the zone operator mailbox in email (hostmaster form, e.g. \"hostmaster.azure.com\" — the leftmost label is the @ at the Azure API)."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.private_dns_zones : [
        for soa in zone.soa_record != null ? [zone.soa_record] : [null] :
        soa == null || (soa.expire_time == null || soa.expire_time >= 0)
        && (soa.minimum_ttl == null || soa.minimum_ttl >= 0)
        && (soa.refresh_time == null || soa.refresh_time >= 0)
        && (soa.retry_time == null || soa.retry_time >= 0)
        && (soa.ttl == null || soa.ttl >= 0)
      ]
    ]))
    error_message = "soa_record timings (expire_time, minimum_ttl, refresh_time, retry_time, ttl) must be zero or positive seconds — leave values out to keep the Azure defaults."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.private_dns_zones : [
        for link in zone.virtual_network_links : length(link.tags) <= 50 && alltrue([for k, v in link.tags : length(k) <= 512 && length(v) <= 256])
      ]
    ]))
    error_message = "link tags are limited to 50 entries, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}
