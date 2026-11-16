variable "tag_keys" {
  description = "Map of resource-manager tag keys keyed by an arbitrary identifier. Each entry creates one google_tags_tag_key under the entry's parent — an organization or a project (folder-parented keys are not supported upstream); tag values reference these entries by key."
  type = map(object({
    parent               = string
    short_name           = string
    description          = optional(string)
    purpose              = optional(string)
    purpose_data         = optional(map(string))
    allowed_values_regex = optional(string)
    deletion_policy      = optional(string, "DELETE")
  }))

  validation {
    condition = alltrue([
      for k in var.tag_keys :
      can(regex("^organizations/[0-9]+$", k.parent)) || can(regex("^projects/([a-z][a-z0-9-]{4,28}[a-z0-9]|[0-9]+)$", k.parent))
    ])
    error_message = "parent must be organizations/{numeric org id} or projects/{project id or numeric project number} — folder-parented tag keys are not supported by the API."
  }

  validation {
    condition     = alltrue([for k in var.tag_keys : can(regex("^[^'\"\\\\/]{1,256}$", k.short_name))])
    error_message = "short_name can be at most 256 characters and must not contain single quotes, double quotes, backslashes or forward slashes."
  }

  validation {
    condition     = alltrue([for k in var.tag_keys : k.description == null || length(k.description) <= 256])
    error_message = "description must be at most 256 characters."
  }

  validation {
    condition     = alltrue([for k in var.tag_keys : k.purpose == null || contains(["GCE_FIREWALL", "DATA_GOVERNANCE"], k.purpose)])
    error_message = "purpose must be one of GCE_FIREWALL or DATA_GOVERNANCE."
  }

  validation {
    condition     = alltrue([for k in var.tag_keys : k.purpose_data == null || k.purpose != null])
    error_message = "purpose_data requires purpose — the data belongs to the policy system named by purpose."
  }

  validation {
    condition = length(distinct([
      for k in var.tag_keys : "${k.parent}/${k.short_name}"
    ])) == length(var.tag_keys)
    error_message = "short_name must be unique within the same parent — two entries sharing parent and short_name are the same tag namespace slot and conflict at apply."
  }

  validation {
    condition     = alltrue([for k in var.tag_keys : contains(["DELETE", "ABANDON", "PREVENT"], k.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, ABANDON or PREVENT (case-sensitive)."
  }
}

variable "tag_values" {
  description = "Map of resource-manager tag values keyed by an arbitrary identifier. Each entry creates one google_tags_tag_value under the tag key named by key."
  type = map(object({
    key             = string
    short_name      = string
    description     = optional(string)
    deletion_policy = optional(string, "DELETE")
  }))

  validation {
    condition = alltrue([
      for v in var.tag_values : contains(keys(var.tag_keys), v.key)
    ])
    error_message = "key must name an entry of var.tag_keys — values are created under tag keys managed by this module; a dangling key fails at plan with this message instead of an index error."
  }

  validation {
    condition     = alltrue([for v in var.tag_values : can(regex("^[^'\"\\\\/]{1,256}$", v.short_name))])
    error_message = "short_name can be at most 256 characters and must not contain single quotes, double quotes, backslashes or forward slashes."
  }

  validation {
    condition     = alltrue([for v in var.tag_values : v.description == null || length(v.description) <= 256])
    error_message = "description must be at most 256 characters."
  }

  validation {
    condition = length(distinct([
      for v in var.tag_values : "${v.key}/${v.short_name}"
    ])) == length(var.tag_values)
    error_message = "short_name must be unique within the same tag key — two entries sharing key and short_name conflict at apply."
  }

  validation {
    condition     = alltrue([for v in var.tag_values : contains(["DELETE", "ABANDON", "PREVENT"], v.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, ABANDON or PREVENT (case-sensitive)."
  }
}
