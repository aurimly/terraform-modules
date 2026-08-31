variable "folders" {
  description = "Map of STACKIT folders keyed by an arbitrary identifier. Each entry creates one folder under an organization or another folder."
  type = map(object({
    name                = string
    owner_email         = string
    parent_container_id = string
    labels              = optional(map(string), {})
  }))

  validation {
    condition     = alltrue([for f in var.folders : can(regex("^[a-zA-ZäüöÄÜÖ0-9]( ?[a-zA-ZäüöÄÜÖß0-9_+&-]){0,39}$", f.name))])
    error_message = "name must be at most 40 characters, start with a letter or number (umlauts allowed), and contain only letters, numbers, umlauts, ß, single spaces, underscores, plus, ampersand and hyphens."
  }

  validation {
    condition     = alltrue([for f in var.folders : alltrue([for k, v in f.labels : can(regex("^[A-ZÄÜÖa-zäüöß0-9_-]{1,64}$", k)) && can(regex("^$|[A-ZÄÜÖa-zäüöß0-9_-]{1,64}$", v))])])
    error_message = "labels keys must match [A-ZÄÜÖa-zäüöß0-9_-]{1,64} and values must match ^$|[A-ZÄÜÖa-zäüöß0-9_-]{1,64} (values may be empty)."
  }

  validation {
    condition     = alltrue([for f in var.folders : length(f.labels) <= 100])
    error_message = "labels must contain at most 100 entries per folder."
  }

  validation {
    condition     = alltrue([for f in var.folders : f.parent_container_id != ""])
    error_message = "parent_container_id must be set to the organization or parent folder container ID (or UUID)."
  }
}
