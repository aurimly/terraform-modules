variable "access_policies" {
  default     = {}
  description = "Map of Access Context Manager access policies keyed by an arbitrary identifier. Usually one policy; access_levels, service_perimeters and perimeter_resources reference it by key (policy_key)."
  type = map(object({
    parent          = string
    title           = string
    scopes          = optional(list(string))
    deletion_policy = optional(string)
  }))

  validation {
    condition     = alltrue([for p in var.access_policies : can(regex("^(organizations|folders)/[0-9]+$", p.parent))])
    error_message = "parent must be organizations/{organization_id} or folders/{folder_id} (the ACM API does not accept project-level parents)."
  }

  validation {
    condition     = alltrue([for p in var.access_policies : length(p.title) >= 1])
    error_message = "title must be non-empty."
  }

  validation {
    condition     = alltrue([for p in var.access_policies : p.deletion_policy == null || contains(["DELETE", "ABANDON", "PREVENT"], p.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, ABANDON or PREVENT. Defaults to DELETE when unset."
  }
}

variable "access_levels" {
  default     = {}
  description = "Map of access levels keyed by an arbitrary identifier. Each entry creates one google_access_context_manager_access_level under the access_policies entry referenced by policy_key."
  type = map(object({
    policy_key      = string
    name            = string
    title           = string
    description     = optional(string)
    deletion_policy = optional(string)
    basic = optional(object({
      combining_function = optional(string)
      conditions = list(object({
        ip_subnetworks         = optional(list(string))
        required_access_levels = optional(list(string))
        members                = optional(list(string))
        negate                 = optional(bool)
        regions                = optional(list(string))
        device_policy = optional(object({
          require_screen_lock              = optional(bool)
          require_admin_approval           = optional(bool)
          require_corp_owned               = optional(bool)
          allowed_encryption_statuses      = optional(list(string))
          allowed_device_management_levels = optional(list(string))
          os_constraints = optional(list(object({
            os_type                    = string
            minimum_version            = optional(string)
            require_verified_chrome_os = optional(bool)
          })), [])
        }))
        vpc_network_sources = optional(list(object({
          vpc_subnetwork = optional(object({
            network            = string
            vpc_ip_subnetworks = optional(list(string))
          }))
        })), [])
      }))
    }))
    custom = optional(object({
      expr = object({
        expression  = string
        title       = optional(string)
        description = optional(string)
        location    = optional(string)
      })
    }))
  }))

  validation {
    condition     = alltrue([for l in var.access_levels : can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", l.name))])
    error_message = "name (the short name) must start with a letter and contain only letters, digits and underscores."
  }

  validation {
    condition     = alltrue([for l in var.access_levels : length(l.title) >= 1])
    error_message = "title must be non-empty and unique within the policy."
  }

  validation {
    condition     = alltrue([for l in var.access_levels : (l.basic != null) != (l.custom != null)])
    error_message = "set exactly one of basic or custom."
  }

  validation {
    condition     = alltrue([for l in var.access_levels : l.basic == null || l.basic.combining_function == null || contains(["AND", "OR"], l.basic.combining_function)])
    error_message = "basic.combining_function must be AND or OR. Defaults to AND when unset."
  }

  validation {
    condition = alltrue([
      for l in var.access_levels : l.basic == null || alltrue(flatten([
        for c in l.basic.conditions : [
          for s in [c.device_policy] : s == null || alltrue([
            for st in s.allowed_encryption_statuses : contains(["ENCRYPTION_UNSPECIFIED", "ENCRYPTION_UNSUPPORTED", "UNENCRYPTED", "ENCRYPTED"], st)
          ])
        ]
      ]))
    ])
    error_message = "device_policy.allowed_encryption_statuses values must be ENCRYPTION_UNSPECIFIED, ENCRYPTION_UNSUPPORTED, UNENCRYPTED or ENCRYPTED."
  }

  validation {
    condition = alltrue([
      for l in var.access_levels : l.basic == null || alltrue(flatten([
        for c in l.basic.conditions : [
          for s in [c.device_policy] : s == null || alltrue([
            for m in s.allowed_device_management_levels : contains(["MANAGEMENT_UNSPECIFIED", "NONE", "BASIC", "COMPLETE"], m)
          ])
        ]
      ]))
    ])
    error_message = "device_policy.allowed_device_management_levels values must be MANAGEMENT_UNSPECIFIED, NONE, BASIC or COMPLETE."
  }

  validation {
    condition = alltrue([
      for l in var.access_levels : l.basic == null || alltrue(flatten([
        for c in l.basic.conditions : [
          for d in [c.device_policy] : d == null || alltrue([
            for o in d.os_constraints : contains(["OS_UNSPECIFIED", "DESKTOP_MAC", "DESKTOP_WINDOWS", "DESKTOP_LINUX", "DESKTOP_CHROME_OS", "ANDROID", "IOS"], o.os_type)
          ])
        ]
      ]))
    ])
    error_message = "os_constraints.os_type must be one of OS_UNSPECIFIED, DESKTOP_MAC, DESKTOP_WINDOWS, DESKTOP_LINUX, DESKTOP_CHROME_OS, ANDROID or IOS."
  }

  validation {
    condition     = alltrue([for l in var.access_levels : l.deletion_policy == null || contains(["DELETE", "ABANDON", "PREVENT"], l.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, ABANDON or PREVENT. Defaults to DELETE when unset."
  }
}

variable "service_perimeters" {
  default     = {}
  description = "Map of service perimeters keyed by an arbitrary identifier. Each entry creates one google_access_context_manager_service_perimeter under the access_policies entry referenced by policy_key. Spec blocks require the perimeter to be a regular perimeter with use_explicit_dry_run_spec = true."
  type = map(object({
    policy_key                = string
    name                      = string
    title                     = string
    description               = optional(string)
    perimeter_type            = optional(string)
    use_explicit_dry_run_spec = optional(bool)
    deletion_policy           = optional(string)
    status = optional(object({
      resources           = optional(list(string), [])
      access_levels       = optional(list(string), [])
      restricted_services = optional(list(string), [])
      vpc_accessible_services = optional(object({
        enable_restriction = optional(bool)
        allowed_services   = optional(list(string), [])
      }))
      ingress_policies = optional(list(object({
        title = optional(string)
        ingress_from = optional(object({
          identity_type = optional(string)
          identities    = optional(list(string))
          sources = optional(list(object({
            access_level = optional(string)
            resource     = optional(string)
            psc_endpoint = optional(object({
              forwarding_rule = optional(string)
            }))
          })), [])
        }))
        ingress_to = optional(object({
          resources = optional(list(string))
          roles     = optional(list(string))
          operations = optional(list(object({
            service_name = optional(string)
            method_selectors = optional(list(object({
              method     = optional(string)
              permission = optional(string)
            })), [])
          })), [])
        }))
      })), [])
      egress_policies = optional(list(object({
        title = optional(string)
        egress_from = optional(object({
          identity_type      = optional(string)
          identities         = optional(list(string))
          source_restriction = optional(string)
          sources = optional(list(object({
            access_level = optional(string)
            resource     = optional(string)
            psc_endpoint = optional(object({
              forwarding_rule = optional(string)
            }))
          })), [])
        }))
        egress_to = optional(object({
          resources          = optional(list(string))
          external_resources = optional(list(string))
          roles              = optional(list(string))
          operations = optional(list(object({
            service_name = optional(string)
            method_selectors = optional(list(object({
              method     = optional(string)
              permission = optional(string)
            })), [])
          })), [])
        }))
      })), [])
    }))
    spec = optional(object({
      resources           = optional(list(string), [])
      access_levels       = optional(list(string), [])
      restricted_services = optional(list(string), [])
      vpc_accessible_services = optional(object({
        enable_restriction = optional(bool)
        allowed_services   = optional(list(string), [])
      }))
      ingress_policies = optional(list(object({
        title = optional(string)
        ingress_from = optional(object({
          identity_type = optional(string)
          identities    = optional(list(string))
          sources = optional(list(object({
            access_level = optional(string)
            resource     = optional(string)
            psc_endpoint = optional(object({
              forwarding_rule = optional(string)
            }))
          })), [])
        }))
        ingress_to = optional(object({
          resources = optional(list(string))
          roles     = optional(list(string))
          operations = optional(list(object({
            service_name = optional(string)
            method_selectors = optional(list(object({
              method     = optional(string)
              permission = optional(string)
            })), [])
          })), [])
        }))
      })), [])
      egress_policies = optional(list(object({
        title = optional(string)
        egress_from = optional(object({
          identity_type      = optional(string)
          identities         = optional(list(string))
          source_restriction = optional(string)
          sources = optional(list(object({
            access_level = optional(string)
            resource     = optional(string)
            psc_endpoint = optional(object({
              forwarding_rule = optional(string)
            }))
          })), [])
        }))
        egress_to = optional(object({
          resources          = optional(list(string))
          external_resources = optional(list(string))
          roles              = optional(list(string))
          operations = optional(list(object({
            service_name = optional(string)
            method_selectors = optional(list(object({
              method     = optional(string)
              permission = optional(string)
            })), [])
          })), [])
        }))
      })), [])
    }))
  }))

  validation {
    condition     = alltrue([for p in var.service_perimeters : can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", p.name))])
    error_message = "name (the short name) must start with a letter and contain only letters, digits and underscores."
  }

  validation {
    condition     = alltrue([for p in var.service_perimeters : length(p.title) >= 1])
    error_message = "title must be non-empty and unique within the policy."
  }

  validation {
    condition     = alltrue([for p in var.service_perimeters : p.perimeter_type == null || contains(["PERIMETER_TYPE_REGULAR", "PERIMETER_TYPE_BRIDGE"], p.perimeter_type)])
    error_message = "perimeter_type must be PERIMETER_TYPE_REGULAR or PERIMETER_TYPE_BRIDGE. Defaults to PERIMETER_TYPE_REGULAR when unset."
  }

  validation {
    condition     = alltrue([for p in var.service_perimeters : p.spec == null || p.use_explicit_dry_run_spec == true])
    error_message = "a spec (dry-run) block requires use_explicit_dry_run_spec = true (the API rejects an explicit spec on perimeters without the flag)."
  }

  validation {
    condition = alltrue([
      for p in var.service_perimeters : p.perimeter_type != "PERIMETER_TYPE_BRIDGE" || alltrue(flatten([
        for b in [p.status, p.spec] : b == null ? [] : [
          length(b.access_levels) == 0,
          length(b.restricted_services) == 0,
          length(b.ingress_policies) == 0,
          length(b.egress_policies) == 0
        ]
      ]))
    ])
    error_message = "bridge perimeters only contain resources: leave access_levels, restricted_services, ingress_policies and egress_policies empty in status and spec."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.service_perimeters : [
        for b in [p.status, p.spec] : b == null ? [] : flatten([
          for dir in ["ingress", "egress"] : [
            for pol in b[dir == "ingress" ? "ingress_policies" : "egress_policies"] : [
              for from in [dir == "ingress" ? pol.ingress_from : pol.egress_from] : from == null || from.identity_type == null || contains(["IDENTITY_TYPE_UNSPECIFIED", "ANY_IDENTITY", "ANY_USER_ACCOUNT", "ANY_SERVICE_ACCOUNT"], from.identity_type)
            ]
          ]
        ])
      ]
    ]))
    error_message = "identity_type must be IDENTITY_TYPE_UNSPECIFIED, ANY_IDENTITY, ANY_USER_ACCOUNT or ANY_SERVICE_ACCOUNT."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.service_perimeters : [
        for b in [p.status, p.spec] : b == null ? [] : [
          for pol in b.egress_policies : pol.egress_from == null || pol.egress_from.source_restriction == null || contains(["SOURCE_RESTRICTION_UNSPECIFIED", "SOURCE_RESTRICTION_ENABLED", "SOURCE_RESTRICTION_DISABLED"], pol.egress_from.source_restriction)
        ]
      ]
    ]))
    error_message = "egress_from.source_restriction must be SOURCE_RESTRICTION_UNSPECIFIED, SOURCE_RESTRICTION_ENABLED or SOURCE_RESTRICTION_DISABLED."
  }

  validation {
    condition     = alltrue([for p in var.service_perimeters : p.deletion_policy == null || contains(["DELETE", "ABANDON", "PREVENT"], p.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, ABANDON or PREVENT. Defaults to DELETE when unset."
  }
}

variable "perimeter_resources" {
  default     = {}
  description = "Map of perimeter resource entries keyed by an arbitrary identifier. Each entry adds one projects/{project_number} resource to the status resources of the service_perimeters entry referenced by perimeter_key."
  type = map(object({
    perimeter_key = string
    resource      = string
  }))

  validation {
    condition     = alltrue([for e in var.perimeter_resources : can(regex("^projects/[0-9]+$", e.resource))])
    error_message = "resource must be a project number in the form projects/{project_number} (the API takes project numbers, not IDs)."
  }
}
