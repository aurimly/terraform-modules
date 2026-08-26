variable "org_policies" {
  description = "Map of organization policies keyed by an arbitrary identifier. Each entry creates one google_org_policy_policy under an organization, folder or project."
  type = map(object({
    name            = string
    parent          = string
    deletion_policy = optional(string, "PREVENT")

    spec = optional(object({
      inherit_from_parent = optional(bool)
      reset               = optional(bool)
      rules = optional(list(object({
        allow_all  = optional(string)
        deny_all   = optional(string)
        enforce    = optional(string)
        parameters = optional(string)
        condition = optional(object({
          expression  = string
          title       = optional(string)
          description = optional(string)
          location    = optional(string)
        }))
        values = optional(object({
          allowed_values = optional(list(string))
          denied_values  = optional(list(string))
        }))
      })), [])
    }))

    dry_run_spec = optional(object({
      inherit_from_parent = optional(bool)
      reset               = optional(bool)
      rules = optional(list(object({
        allow_all  = optional(string)
        deny_all   = optional(string)
        enforce    = optional(string)
        parameters = optional(string)
        condition = optional(object({
          expression  = string
          title       = optional(string)
          description = optional(string)
          location    = optional(string)
        }))
        values = optional(object({
          allowed_values = optional(list(string))
          denied_values  = optional(list(string))
        }))
      })), [])
    }))
  }))

  validation {
    condition = alltrue([
      for p in var.org_policies :
      can(regex("^(projects/[a-z0-9-]+|folders/[0-9]+|organizations/[0-9]+)/policies/.+$", p.name))
    ])
    error_message = "name must be \"projects/<project_id>/policies/<constraint>\", \"folders/<folder_id>/policies/<constraint>\" or \"organizations/<org_id>/policies/<constraint>\"."
  }

  validation {
    condition = alltrue([
      for p in var.org_policies :
      can(regex("^(projects/[a-z0-9-]+|folders/[0-9]+|organizations/[0-9]+)$", p.parent))
    ])
    error_message = "parent must be \"projects/<project_id>\", \"folders/<folder_id>\" or \"organizations/<org_id>\"."
  }

  validation {
    condition = alltrue([
      for p in var.org_policies :
      split("/", p.name)[0] == split("/", p.parent)[0]
    ])
    error_message = "name and parent must refer to the same resource type (organizations, folders or projects)."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.org_policies : [
        for s in [for x in [p.spec, p.dry_run_spec] : x if x != null] :
        alltrue([
          for r in s.rules :
          length(compact([r.allow_all, r.deny_all, r.enforce])) <= 1
        ])
      ]
    ]))
    error_message = "Each rule can set at most one of allow_all, deny_all or enforce."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.org_policies : [
        for s in [for x in [p.spec, p.dry_run_spec] : x if x != null] :
        alltrue([
          for r in s.rules : alltrue([
            for v in compact([r.allow_all, r.deny_all, r.enforce]) :
            contains(["TRUE", "FALSE"], v)
          ])
        ])
      ]
    ]))
    error_message = "allow_all, deny_all and enforce must be the strings \"TRUE\" or \"FALSE\"."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.org_policies : [
        for s in [for x in [p.spec, p.dry_run_spec] : x if x != null] :
        s.reset != true || (length(s.rules) == 0 && s.inherit_from_parent != true)
      ]
    ]))
    error_message = "When reset is true, rules must be empty and inherit_from_parent must not be true."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.org_policies : [
        for s in [for x in [p.spec, p.dry_run_spec] : x if x != null] :
        alltrue([
          for r in s.rules :
          r.parameters == null || (can(jsondecode(r.parameters)) && can(tomap(jsondecode(r.parameters))))
        ])
      ]
    ]))
    error_message = "parameters must be a JSON object string (build it with jsonencode)."
  }

  validation {
    condition     = alltrue([for p in var.org_policies : contains(["DELETE", "ABANDON", "PREVENT"], p.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, ABANDON or PREVENT (case-sensitive)."
  }
}
