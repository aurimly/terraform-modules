variable "client_lists" {
  description = "Map of client lists keyed by an arbitrary unique identifier. Keys only pick the for_each instance and appear in resource addresses and outputs; the name inside the entry is what the API sees."
  type = map(object({
    name        = string
    type        = string
    contract_id = string
    group_id    = number
    notes       = optional(string)
    tags        = optional(list(string), [])
    items = list(object({
      value           = optional(string)
      key             = optional(string)
      values          = optional(list(string))
      description     = optional(string)
      tags            = optional(list(string))
      expiration_date = optional(string)
    }))
    activation = optional(object({
      network                 = string
      comments                = optional(string)
      notification_recipients = optional(list(string))
    }))
  }))

  validation {
    condition     = alltrue([for l in var.client_lists : contains(["IP", "GEO", "ASN", "TLS_FINGERPRINT", "FILE_HASH", "USER_ID", "DOMAIN", "REQUEST_HEADER_NAME_VALUE"], l.type)])
    error_message = "type must be one of IP, GEO, ASN, TLS_FINGERPRINT, FILE_HASH, USER_ID, DOMAIN, REQUEST_HEADER_NAME_VALUE."
  }

  validation {
    condition = alltrue([for l in var.client_lists :
      l.type != "REQUEST_HEADER_NAME_VALUE" || alltrue([for i in l.items :
    i.key != null && i.key != "" && i.values != null && length(i.values) >= 1 && i.value == null])])
    error_message = "REQUEST_HEADER_NAME_VALUE lists: every item needs a non-empty key and at least one values entry, and value must be empty (the provider rejects the reverse shape)."
  }

  validation {
    condition = alltrue([for l in var.client_lists :
      l.type == "REQUEST_HEADER_NAME_VALUE" || alltrue([for i in l.items :
    i.value != null && i.value != "" && i.key == null && i.values == null])])
    error_message = "Every list type other than REQUEST_HEADER_NAME_VALUE: each item needs a non-empty value, and key and values must be empty (the provider rejects the reverse shape)."
  }

  validation {
    condition     = alltrue([for l in var.client_lists : length(l.items) >= 1])
    error_message = "items must contain at least one entry."
  }

  validation {
    condition = alltrue([for l in var.client_lists :
    alltrue([for i in l.items : i.expiration_date == null || can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\\.[0-9]+)?(Z|[+-][0-9]{2}:[0-9]{2})$", i.expiration_date))])])
    error_message = "items.expiration_date must be RFC3339-shaped (e.g. 2027-01-01T00:00:00Z) when set (light shape check; the API is the final arbiter)."
  }

  validation {
    condition     = alltrue([for l in var.client_lists : l.activation == null || contains(["STAGING", "PRODUCTION"], l.activation.network)])
    error_message = "activation.network must be one of STAGING, PRODUCTION."
  }

  validation {
    condition     = length(distinct([for l in var.client_lists : lower(l.name)])) == length(var.client_lists)
    error_message = "list names must be unique ignoring case: Akamai list IDs embed the name."
  }
}
