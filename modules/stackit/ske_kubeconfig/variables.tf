variable "kubeconfigs" {
  description = "Map of SKE kubeconfigs for existing clusters keyed by an arbitrary identifier. Each entry creates one short-lived admin kubeconfig; see the module README for expiry and rotation."
  type = map(object({
    project_id     = string
    cluster_name   = string
    region         = optional(string)
    expiration     = optional(number)
    refresh        = optional(bool)
    refresh_before = optional(number)
  }))

  validation {
    condition     = alltrue([for k in var.kubeconfigs : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", k.project_id))])
    error_message = "project_id must be a UUID."
  }

  validation {
    condition     = alltrue([for k in var.kubeconfigs : !can(regex(",", k.cluster_name))])
    error_message = "cluster_name must not contain a comma (the import ID is comma-joined)."
  }

  validation {
    condition     = alltrue([for k in var.kubeconfigs : k.expiration == null || k.expiration > 0])
    error_message = "expiration must be greater than 0."
  }

  validation {
    condition     = alltrue([for k in var.kubeconfigs : k.refresh_before == null || k.refresh == true])
    error_message = "refresh_before requires refresh = true (the module is stricter than the provider here: upstream silently ignores refresh_before without refresh)."
  }
}
