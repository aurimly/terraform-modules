variable "repositories" {
  description = "Map of Artifact Registry repositories keyed by an arbitrary identifier. Each entry creates one google_artifact_registry_repository plus optional IAM bindings."
  type = map(object({
    repository_id          = string
    location               = string
    format                 = string
    project_id             = optional(string)
    description            = optional(string)
    labels                 = optional(map(string), {})
    kms_key_name           = optional(string)
    cleanup_policy_dry_run = optional(bool)
    cleanup_policies = optional(map(object({
      id     = string
      action = string
      condition = optional(object({
        tag_state             = optional(string)
        tag_prefixes          = optional(list(string))
        version_name_prefixes = optional(list(string))
        package_name_prefixes = optional(list(string))
        older_than            = optional(string)
        newer_than            = optional(string)
      }))
      most_recent_versions = optional(object({
        keep_count            = optional(number)
        package_name_prefixes = optional(list(string))
      }))
    })), {})
    docker_config = optional(object({
      immutable_tags = optional(bool)
    }))
    vulnerability_scanning_config = optional(object({
      enablement_config = optional(string)
    }))
    role_bindings = optional(map(object({
      role    = string
      members = list(string)
    })), {})
  }))

  validation {
    condition     = alltrue([for r in var.repositories : length(r.repository_id) >= 1 && length(r.repository_id) <= 100 && can(regex("^[a-z0-9][a-z0-9._-]*$", r.repository_id))])
    error_message = "repository_id must be 1 to 100 characters, start with a lowercase letter or digit, and contain only lowercase letters, digits, dots, underscores and hyphens (Artifact Registry naming rules)."
  }

  validation {
    condition     = alltrue([for r in var.repositories : can(regex("^[A-Z][A-Z_]*$", r.format))])
    error_message = "format must be an uppercase identifier (e.g. DOCKER, MAVEN, NPM, PYTHON, APT, YUM, KFP, GO, GENERIC); it is a shape check, not a list of valid formats."
  }

  validation {
    condition     = alltrue([for r in var.repositories : r.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", r.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for r in var.repositories : alltrue([for p in r.cleanup_policies : contains(["DELETE", "KEEP"], p.action)])])
    error_message = "cleanup_policies.action must be one of DELETE or KEEP (case-sensitive)."
  }

  validation {
    condition     = alltrue([for r in var.repositories : alltrue([for p in r.cleanup_policies : p.condition == null || p.condition.tag_state == null || contains(["TAGGED", "UNTAGGED", "ANY"], p.condition.tag_state)])])
    error_message = "cleanup_policies.condition.tag_state must be one of TAGGED, UNTAGGED or ANY (case-sensitive)."
  }

  validation {
    condition     = alltrue([for r in var.repositories : alltrue([for p in r.cleanup_policies : p.most_recent_versions == null || p.action == "KEEP"])])
    error_message = "cleanup_policies.most_recent_versions may only be specified when action is KEEP."
  }

  validation {
    condition     = alltrue([for r in var.repositories : length(distinct([for b in r.role_bindings : b.role])) == length(r.role_bindings)])
    error_message = "role_bindings.role must be unique within each repository; one IAM binding resource exists per role."
  }

  validation {
    condition     = alltrue([for r in var.repositories : alltrue([for b in r.role_bindings : length(b.members) > 0])])
    error_message = "role_bindings.members must contain at least one member."
  }
}
