variable "folders" {
  description = "Map of GCP folders keyed by an arbitrary identifier. Each entry creates one folder under an organization or another folder."
  type = map(object({
    display_name        = string
    parent              = string
    tags                = optional(map(string), {})
    deletion_protection = optional(bool, true)
    deletion_policy     = optional(string, "PREVENT")
  }))

  validation {
    condition     = alltrue([for f in var.folders : can(regex("^[\\p{L}\\p{N}]([\\p{L}\\p{N} _-]{0,28}[\\p{L}\\p{N}])?$", f.display_name))])
    error_message = "display_name must be at most 30 characters, start and end with a letter or number, and contain only letters, numbers, spaces, hyphens and underscores."
  }

  validation {
    condition     = alltrue([for f in var.folders : can(regex("^organizations/[0-9]+$", f.parent)) || can(regex("^folders/[0-9]+$", f.parent))])
    error_message = "parent must be \"organizations/<org_id>\" or \"folders/<folder_id>\"."
  }

  validation {
    condition     = alltrue([for f in var.folders : contains(["DELETE", "ABANDON", "PREVENT"], f.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, ABANDON or PREVENT (case-sensitive)."
  }

  validation {
    condition     = alltrue([for f in var.folders : alltrue([for key, val in f.tags : can(regex("^tagKeys/[0-9]+$", key)) && can(regex("^tagValues/[0-9]+$", val))])])
    error_message = "tags keys must be \"tagKeys/<tag_key_id>\" and values \"tagValues/<tag_value_id>\"."
  }
}
