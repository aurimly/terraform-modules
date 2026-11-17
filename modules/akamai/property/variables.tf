variable "properties" {
  description = "Map of properties keyed by an arbitrary unique identifier. Keys only pick the for_each instance and appear in resource addresses and outputs."
  type = map(object({
    name          = string
    contract_id   = string
    group_id      = string
    product_id    = string
    rule_format   = optional(string)
    rules         = optional(string)
    version_notes = optional(string)
    hostnames = optional(list(object({
      cname_from             = string
      cname_to               = string
      cert_provisioning_type = string
    })), [])
    activation = optional(object({
      network                        = string
      contact                        = list(string)
      note                           = optional(string)
      auto_acknowledge_rule_warnings = optional(bool, false)
    }))
  }))

  validation {
    condition = alltrue([for p in var.properties :
    alltrue([for h in p.hostnames : contains(["DEFAULT", "CPS_MANAGED"], h.cert_provisioning_type)])])
    error_message = "hostnames.cert_provisioning_type must be one of DEFAULT, CPS_MANAGED. CCM is a limited-availability feature and is not supported by this module."
  }

  validation {
    condition = alltrue([for p in var.properties :
    alltrue([for h in p.hostnames : length(h.cname_from) >= 1 && length(h.cname_to) >= 1])])
    error_message = "hostnames entries must set non-empty cname_from and cname_to."
  }

  validation {
    condition = alltrue([for p in var.properties :
    length(distinct([for h in p.hostnames : lower(h.cname_from)])) == length(p.hostnames)])
    error_message = "cname_from must be unique ignoring case within each property entry (PAPI treats hostnames as per-property identity)."
  }

  validation {
    condition     = alltrue([for p in var.properties : p.activation == null || contains(["STAGING", "PRODUCTION"], p.activation.network)])
    error_message = "activation.network must be one of STAGING, PRODUCTION (the module passes the value through; the provider defaults to STAGING)."
  }

  validation {
    condition     = alltrue([for p in var.properties : p.activation == null || length(p.activation.contact) >= 1])
    error_message = "activation.contact must contain at least one email address when activation is set."
  }
}
