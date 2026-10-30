variable "contacts" {
  description = "Map of essential contacts keyed by an arbitrary identifier (typically the notification category). Each entry creates one google_essential_contacts_contact at the parent (organization, folder or project). Categories must be unique across entries — the API allows one contact per category."
  type = map(object({
    email                               = string
    parent                              = string
    notification_category_subscriptions = list(string)
    language_tag                        = optional(string, "en")
    deletion_policy                     = optional(string, "PREVENT")
  }))
  default = {}

  validation {
    condition = alltrue([
      for c in var.contacts :
      can(regex("^organizations/[0-9]+$", c.parent)) ||
      can(regex("^folders/[0-9]+$", c.parent)) ||
      can(regex("^projects/[a-z][a-z0-9-]+$", c.parent))
    ])
    error_message = "parent must be organizations/{numeric id}, folders/{numeric id} or projects/{project_id}."
  }

  validation {
    condition = alltrue(flatten([
      for c in var.contacts : [
        for cat in c.notification_category_subscriptions :
        contains(["ALL", "BILLING", "LEGAL", "SECURITY", "SUSPENSION", "TECHNICAL"], cat)
      ]
    ]))
    error_message = "notification_category_subscriptions entries must be one of ALL, BILLING, LEGAL, SECURITY, SUSPENSION or TECHNICAL."
  }

  validation {
    condition = alltrue([
      for c in var.contacts :
      !contains(c.notification_category_subscriptions, "ALL") || length(c.notification_category_subscriptions) == 1
    ])
    error_message = "\"ALL\" cannot be combined with other notification categories; the Essential Contacts API rejects the mix."
  }

  validation {
    condition = alltrue(flatten([
      for ka, a in var.contacts : [
        for kb, b in var.contacts :
        ka == kb || length(setintersection(a.notification_category_subscriptions, b.notification_category_subscriptions)) == 0
      ]
    ]))
    error_message = "notification_category_subscriptions must not repeat across entries; the API allows only one contact per category."
  }

  validation {
    condition = alltrue([
      for c in var.contacts :
      can(regex("^[^[:space:]]+@[^[:space:]]+$", c.email))
    ])
    error_message = "email must be a valid address (no spaces around the @)."
  }

  validation {
    condition = alltrue([
      for c in var.contacts :
      can(regex("^[a-z]{2}$", c.language_tag))
    ])
    error_message = "language_tag must be an ISO 639-1 code (two lowercase letters), e.g. \"en\"."
  }

  validation {
    condition = alltrue([
      for c in var.contacts :
      contains(["DELETE", "ABANDON", "PREVENT"], c.deletion_policy)
    ])
    error_message = "deletion_policy must be one of DELETE, ABANDON or PREVENT."
  }
}
