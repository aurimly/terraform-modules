variable "cloud_routers" {
  description = "Map of Equinix Fabric Cloud Routers keyed by an arbitrary unique identifier. Each entry creates one equinix_fabric_cloud_router."
  type = map(object({
    name        = string
    type        = string # XF_ROUTER
    description = optional(string)
    location = object({
      metro_code = string
      ibx        = optional(string)
      metro_name = optional(string)
      region     = optional(string)
    })
    package = object({
      code = string # STANDARD, ADVANCED
    })
    project = object({
      project_id = optional(string)
      href       = optional(string)
    })
    notifications = list(object({
      type          = string # ALL, CONNECTION_APPROVAL, SALES_REP_NOTIFICATIONS, NOTIFICATIONS
      emails        = list(string)
      send_interval = optional(string)
    }))
    account = optional(object({
      account_number = number
    }))
    order = optional(object({
      purchase_order_number = optional(string)
      order_number          = optional(string)
      order_id              = optional(string)
      billing_tier          = optional(string)
      term_length           = optional(number) # 1, 12, 24, 36
    }))
    marketplace_subscription = optional(object({
      uuid = string
      type = optional(string) # e.g. AWS_MARKETPLACE_SUBSCRIPTION
    }))
  }))

  validation {
    condition     = alltrue([for r in var.cloud_routers : can(regex("^[a-zA-Z0-9_-]{1,24}$", r.name))])
    error_message = "name must be 1 to 24 characters, letters, digits, hyphens or underscores only."
  }

  validation {
    condition     = alltrue([for r in var.cloud_routers : length(r.location.metro_code) > 0])
    error_message = "location.metro_code must be a non-empty metro code (e.g. SV)."
  }

  validation {
    condition     = alltrue([for r in var.cloud_routers : length(r.notifications) > 0])
    error_message = "notifications must contain at least one entry."
  }

  validation {
    condition     = alltrue([for r in var.cloud_routers : alltrue([for n in r.notifications : contains(["ALL", "CONNECTION_APPROVAL", "SALES_REP_NOTIFICATIONS", "NOTIFICATIONS"], n.type)])])
    error_message = "notifications[].type must be one of ALL, CONNECTION_APPROVAL, SALES_REP_NOTIFICATIONS or NOTIFICATIONS (case-sensitive)."
  }

  validation {
    condition     = alltrue([for r in var.cloud_routers : alltrue([for n in r.notifications : alltrue([for e in n.emails : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", e))])])])
    error_message = "notifications[].emails entries must look like email addresses."
  }

  validation {
    condition     = alltrue([for r in var.cloud_routers : r.order == null || r.order.term_length == null || contains([1, 12, 24, 36], r.order.term_length)])
    error_message = "order.term_length must be one of 1, 12, 24 or 36 (months)."
  }
}
